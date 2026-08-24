"""Generic dispatch/approval/cancel orchestration shared by subprocess-backed worker engines.

Concrete engines (Codex, Claude, ...) differ only in what runs the subprocess,
how the prompt/workdir get built, and a handful of engine-specific labels,
timeouts, and approval settings. This base class owns the task lifecycle state
machine; subclasses supply those pieces via the constructor.
"""

import asyncio
from typing import Protocol
from uuid import UUID

import structlog

from app.models.enums import TaskStatus
from app.services.approval_service import ApprovalService
from app.services.event_service import EventService
from app.services.task_service import TaskService
from workers.base import WorkerEngine
from workers.common.context import ExecutionContextBuilder
from workers.common.state import ExecutionContext, RuntimeState

logger = structlog.get_logger(__name__)


class ProcessRunnerProtocol(Protocol):
    async def run(self, task_id: UUID, state: RuntimeState, context: ExecutionContext) -> None: ...

    def command_preview(self) -> str: ...

    async def write_to_stdin(
        self, task_id: UUID, process: asyncio.subprocess.Process, content: str
    ) -> None: ...


class SubprocessWorkerOrchestrator(WorkerEngine):
    """Shared dispatch/approval/cancel state machine for subprocess-backed worker engines."""

    engine_label: str  # e.g. "Codex", "Claude" — used only in log/event text

    def __init__(
        self,
        *,
        task_service: TaskService,
        event_service: EventService,
        approval_service: ApprovalService,
        context_builder: ExecutionContextBuilder,
        process_runner: ProcessRunnerProtocol,
        require_initial_approval: bool,
        initial_approval_risk_level: str,
        timeout_seconds: float,
        lock: asyncio.Lock,
    ) -> None:
        self._task_service = task_service
        self._event_service = event_service
        self._approval_service = approval_service
        self._context_builder = context_builder
        self._process_runner = process_runner
        self._require_initial_approval = require_initial_approval
        self._initial_approval_risk_level = initial_approval_risk_level
        self._timeout_seconds = timeout_seconds

        self._lock = lock
        self._states: dict[UUID, RuntimeState] = {}

    async def dispatch_task(self, task_id: UUID) -> None:
        async with self._lock:
            existing = self._states.get(task_id)
            if existing is not None and existing.job is not None and not existing.job.done():
                return

            state = RuntimeState(task_id=task_id)
            state.job = asyncio.create_task(self._run_task(task_id, state))
            self._states[task_id] = state

    async def handle_approval(self, task_id: UUID, approval_id: UUID, approved: bool) -> None:
        status = await self._task_service.get_status(task_id)
        if status != TaskStatus.WAITING_APPROVAL:
            return

        async with self._lock:
            state = self._states.get(task_id)
            if state is None:
                return
            if state.approval_id != approval_id:
                return
            state.approval_granted = approved
            state.approval_event.set()

    async def handle_user_reply(self, task_id: UUID, content: str) -> None:
        async with self._lock:
            state = self._states.get(task_id)
            if state is None:
                return

            process = state.process
            if process is None or process.stdin is None or process.stdin.is_closing():
                state.pending_replies.append(content)
                await self._event_service.append_event(
                    task_id,
                    "task.log",
                    {
                        "message": "Worker queued follow-up for next execution step",
                        "queued_followup": content,
                    },
                )
                return

        await self._process_runner.write_to_stdin(task_id, process, content)

    async def cancel_task(self, task_id: UUID) -> None:
        async with self._lock:
            state = self._states.get(task_id)
            if state is None:
                return
            job = state.job
            process = state.process

        if process is not None and process.returncode is None:
            process.terminate()
            try:
                await asyncio.wait_for(process.wait(), timeout=2.0)
            except TimeoutError:
                process.kill()
                await process.wait()

        if job is not None and not job.done():
            job.cancel()

    async def _run_task(self, task_id: UUID, state: RuntimeState) -> None:
        phase_prefix = self.engine_label.lower()
        try:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.STARTING,
                current_phase=f"booting_{phase_prefix}_worker",
            )
            await self._event_service.append_event(
                task_id,
                "task.starting",
                {"message": f"Starting {self.engine_label} worker"},
            )

            context = await self._context_builder.build(task_id)
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.RUNNING,
                current_phase=f"preparing_{phase_prefix}_runtime",
            )
            await self._event_service.append_event(
                task_id,
                "task.running",
                {
                    "message": f"{self.engine_label} worker is running",
                    "worker_engine": phase_prefix,
                    "workdir": context.workdir,
                },
            )

            if self._require_initial_approval:
                approval = await self._approval_service.create_approval_request(
                    task_id=task_id,
                    kind="command_execution",
                    title=f"Approve {self.engine_label} runtime execution",
                    description=(
                        f"Worker requests permission to start the {self.engine_label} "
                        "runtime command."
                    ),
                    payload_json={
                        "command": self._process_runner.command_preview(),
                        "workdir": context.workdir,
                        "risk_level": self._initial_approval_risk_level,
                    },
                )
                state.approval_id = approval.id

                await self._task_service.transition_for_worker(
                    task_id,
                    TaskStatus.WAITING_APPROVAL,
                    current_phase="awaiting_user_approval",
                )
                await self._event_service.append_event(
                    task_id,
                    "task.progress",
                    {
                        "message": (
                            f"Waiting for approval before launching {self.engine_label} runtime"
                        )
                    },
                )

                try:
                    await asyncio.wait_for(
                        state.approval_event.wait(),
                        timeout=self._timeout_seconds,
                    )
                except TimeoutError:
                    await self._task_service.transition_for_worker(
                        task_id,
                        TaskStatus.FAILED,
                        current_phase="approval_timeout",
                        error_message="Approval timed out",
                    )
                    await self._event_service.append_event(
                        task_id,
                        "task.failed",
                        {
                            "message": "Approval timed out",
                            "error_code": "APPROVAL_TIMEOUT",
                            "is_retryable": True,
                        },
                    )
                    return

                if state.approval_granted is not True:
                    # Rejection is handled by ApprovalService before dispatcher callback.
                    return

                current_status = await self._task_service.get_status(task_id)
                if current_status == TaskStatus.CANCELLED:
                    return

                await self._task_service.transition_for_worker(
                    task_id,
                    TaskStatus.RUNNING,
                    current_phase=f"executing_{phase_prefix}_runtime",
                )
                await self._event_service.append_event(
                    task_id,
                    "task.running",
                    {"message": f"Approval granted, launching {self.engine_label} runtime"},
                )

            await self._process_runner.run(task_id, state, context)
        except asyncio.CancelledError:
            logger.info("worker.cancelled", engine=self.engine_label, task_id=str(task_id))
            raise
        except Exception as exc:
            logger.exception(
                "worker.error", engine=self.engine_label, task_id=str(task_id), error=str(exc)
            )
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.FAILED,
                current_phase="worker_error",
                error_message=str(exc),
            )
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": f"{self.engine_label} worker crashed",
                    "error_code": "WORKER_ERROR",
                    "error": str(exc),
                    "is_retryable": True,
                },
            )
        finally:
            async with self._lock:
                current = self._states.get(task_id)
                if current is state:
                    self._states.pop(task_id, None)
