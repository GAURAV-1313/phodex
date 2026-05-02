import asyncio
from uuid import UUID

import structlog

from app.core.config import Settings
from app.models.enums import TaskStatus
from app.services.approval_service import ApprovalService
from app.services.event_service import EventService
from app.services.task_service import TaskService
from app.workers.base import WorkerEngine

logger = structlog.get_logger(__name__)


class FakeWorkerEngine(WorkerEngine):
    """
    Fake worker for V1.

    TODO: Replace this with real Codex runtime integration while keeping the same WorkerEngine interface.
    """

    def __init__(
        self,
        settings: Settings,
        task_service: TaskService,
        event_service: EventService,
        approval_service: ApprovalService,
    ) -> None:
        self._settings = settings
        self._task_service = task_service
        self._event_service = event_service
        self._approval_service = approval_service
        self._lock = asyncio.Lock()
        self._task_jobs: dict[UUID, asyncio.Task[None]] = {}

    async def dispatch_task(self, task_id: UUID) -> None:
        async with self._lock:
            running = self._task_jobs.get(task_id)
            if running is not None and not running.done():
                return
            job = asyncio.create_task(self._run_until_approval(task_id))
            self._task_jobs[task_id] = job

    async def handle_approval(self, task_id: UUID, approval_id: UUID, approved: bool) -> None:
        current_status = await self._task_service.get_status(task_id)
        if current_status != TaskStatus.WAITING_APPROVAL:
            return

        if approved:
            async with self._lock:
                running = self._task_jobs.get(task_id)
                if running is not None and not running.done():
                    return
                job = asyncio.create_task(self._resume_after_approval(task_id, approval_id))
                self._task_jobs[task_id] = job
            return

        await self._task_service.transition_for_worker(
            task_id,
            TaskStatus.FAILED,
            current_phase="approval_rejected",
            error_message="Approval rejected",
        )
        await self._event_service.append_event(
            task_id,
            "task.failed",
            {
                "message": "Task failed because approval was rejected",
                "error_code": "APPROVAL_REJECTED",
                "is_retryable": False,
            },
        )

    async def handle_user_reply(self, task_id: UUID, content: str) -> None:
        status = await self._task_service.get_status(task_id)
        if status == TaskStatus.RUNNING:
            await self._event_service.append_event(
                task_id,
                "task.log",
                {"message": f"Worker received follow-up: {content}"},
            )
            return

        if status == TaskStatus.WAITING_APPROVAL:
            await self._event_service.append_event(
                task_id,
                "task.log",
                {"message": "Follow-up received and queued until approval"},
            )

    async def cancel_task(self, task_id: UUID) -> None:
        async with self._lock:
            job = self._task_jobs.get(task_id)
            if job is not None and not job.done():
                job.cancel()

    async def _run_until_approval(self, task_id: UUID) -> None:
        try:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.STARTING,
                current_phase="booting_worker",
            )
            await self._event_service.append_event(
                task_id,
                "task.starting",
                {"message": "Starting worker"},
            )
            await asyncio.sleep(self._settings.fake_worker_step_delay_seconds)

            if await self._task_service.get_status(task_id) == TaskStatus.CANCELLED:
                return

            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.RUNNING,
                current_phase="analyzing_context",
            )
            await self._event_service.append_event(
                task_id,
                "task.running",
                {"message": "Task is running"},
            )
            await self._event_service.append_event(
                task_id,
                "task.progress",
                {"message": "Reading repository structure"},
            )
            await self._event_service.append_event(
                task_id,
                "task.log",
                {
                    "message": "Collected initial context",
                    "stage": "context_scan",
                    "tool_name": "repo.index",
                    "tool_args": {
                        "include_hidden": False,
                        "max_files": 5000,
                    },
                    "output_preview": "Indexed src/, tests/, docs/ and 147 files.",
                },
            )
            await self._task_service.append_assistant_message(
                task_id,
                "I analyzed the request and prepared an execution plan.",
            )
            await self._event_service.append_event(
                task_id,
                "task.log",
                {
                    "message": "Prepared patch preview",
                    "stage": "patch_preview",
                    "file_changes": [
                        {
                            "action": "deleted",
                            "path": "index.html",
                            "added": 0,
                            "removed": 255,
                        },
                        {
                            "action": "created",
                            "path": "index.html",
                            "added": 326,
                            "removed": 0,
                        },
                    ],
                },
            )
            await asyncio.sleep(self._settings.fake_worker_step_delay_seconds)

            if await self._task_service.get_status(task_id) == TaskStatus.CANCELLED:
                return

            await self._approval_service.create_approval_request(
                task_id=task_id,
                kind="command_execution",
                title="Approve command execution",
                description="Fake worker needs approval to run a potentially risky operation.",
                payload_json={
                    "command": "git clean -xdf",
                    "risk_level": "high",
                },
            )
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.WAITING_APPROVAL,
                current_phase="awaiting_user_approval",
            )
            await self._event_service.append_event(
                task_id,
                "task.progress",
                {"message": "Waiting for approval to continue"},
            )
        except asyncio.CancelledError:
            logger.info("fake_worker.cancelled", task_id=str(task_id))
            raise
        except Exception as exc:
            logger.exception("fake_worker.error", task_id=str(task_id), error=str(exc))
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
                    "message": "Worker crashed",
                    "error_code": "WORKER_ERROR",
                    "error": str(exc),
                    "is_retryable": True,
                },
            )

    async def _resume_after_approval(self, task_id: UUID, approval_id: UUID) -> None:
        try:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.RUNNING,
                current_phase="post_approval_execution",
            )
            await self._event_service.append_event(
                task_id,
                "task.running",
                {
                    "message": "Resuming after approval",
                    "approval_id": str(approval_id),
                },
            )
            await asyncio.sleep(self._settings.fake_worker_step_delay_seconds)

            if await self._task_service.get_status(task_id) == TaskStatus.CANCELLED:
                return

            await self._event_service.append_event(
                task_id,
                "task.progress",
                {"message": "Applying approved action"},
            )
            await self._event_service.append_event(
                task_id,
                "task.log",
                {
                    "message": "Applied changes to working tree",
                    "stage": "apply_changes",
                    "file_changes": [
                        {
                            "action": "modified",
                            "path": "backend/app/workers/fake_worker.py",
                            "added": 42,
                            "removed": 8,
                        },
                        {
                            "action": "created",
                            "path": "backend/tests/test_worker_trace_details.py",
                            "added": 58,
                            "removed": 0,
                        },
                    ],
                },
            )
            await self._task_service.append_assistant_message(
                task_id,
                "Approved action completed. Preparing final summary.",
            )

            await asyncio.sleep(self._settings.fake_worker_step_delay_seconds)
            await self._event_service.append_event(
                task_id,
                "task.completed",
                {"message": "Task completed", "summary": "Fake worker completed successfully."},
            )
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.COMPLETED,
                current_phase="done",
                final_summary="Fake worker completed successfully.",
            )
        except asyncio.CancelledError:
            logger.info("fake_worker.resume_cancelled", task_id=str(task_id))
            raise
        except Exception as exc:
            logger.exception("fake_worker.resume_error", task_id=str(task_id), error=str(exc))
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
                    "message": "Worker failed after approval",
                    "error_code": "WORKER_ERROR",
                    "error": str(exc),
                    "is_retryable": True,
                },
            )
