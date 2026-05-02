import asyncio
import json
import shlex
from dataclasses import dataclass, field
from pathlib import Path
from uuid import UUID

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.models.enums import TaskMessageRole, TaskStatus
from app.models.project_context import ProjectContext
from app.models.synced_repository import SyncedRepository
from app.models.task import Task
from app.models.task_message import TaskMessage
from app.services.approval_service import ApprovalService
from app.services.event_service import EventService
from app.services.task_service import TaskService
from app.workers.base import WorkerEngine

logger = structlog.get_logger(__name__)


@dataclass
class _TaskExecutionContext:
    prompt_text: str
    workdir: str | None
    context_name: str | None
    branch: str | None


@dataclass
class _RuntimeState:
    task_id: UUID
    job: asyncio.Task[None] | None = None
    process: asyncio.subprocess.Process | None = None
    approval_id: UUID | None = None
    approval_event: asyncio.Event = field(default_factory=asyncio.Event)
    approval_granted: bool | None = None
    pending_replies: list[str] = field(default_factory=list)
    final_summary: str | None = None
    stderr_tail: list[str] = field(default_factory=list)


class CodexWorkerEngine(WorkerEngine):
    """
    Production-oriented worker adapter for running a real Codex runtime command.

    The runtime command and behavior are configured through settings:
      - CODEX_COMMAND
      - CODEX_ARGS
      - CODEX_PROMPT_STDIN
      - CODEX_TIMEOUT_SECONDS
      - CODEX_REQUIRE_INITIAL_APPROVAL
      - CODEX_DEFAULT_WORKDIR
    """

    def __init__(
        self,
        settings: Settings,
        session_factory: async_sessionmaker[AsyncSession],
        task_service: TaskService,
        event_service: EventService,
        approval_service: ApprovalService,
    ) -> None:
        self._settings = settings
        self._session_factory = session_factory
        self._task_service = task_service
        self._event_service = event_service
        self._approval_service = approval_service

        self._lock = asyncio.Lock()
        self._states: dict[UUID, _RuntimeState] = {}

    async def dispatch_task(self, task_id: UUID) -> None:
        async with self._lock:
            existing = self._states.get(task_id)
            if existing is not None and existing.job is not None and not existing.job.done():
                return

            state = _RuntimeState(task_id=task_id)
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

        await self._write_to_stdin(task_id, process, content)

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

    async def _run_task(self, task_id: UUID, state: _RuntimeState) -> None:
        try:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.STARTING,
                current_phase="booting_codex_worker",
            )
            await self._event_service.append_event(
                task_id,
                "task.starting",
                {"message": "Starting Codex worker"},
            )

            context = await self._build_execution_context(task_id)
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.RUNNING,
                current_phase="preparing_codex_runtime",
            )
            await self._event_service.append_event(
                task_id,
                "task.running",
                {
                    "message": "Codex worker is running",
                    "worker_engine": "codex",
                    "workdir": context.workdir,
                },
            )

            if self._settings.codex_require_initial_approval:
                approval = await self._approval_service.create_approval_request(
                    task_id=task_id,
                    kind="command_execution",
                    title="Approve Codex runtime execution",
                    description="Worker requests permission to start the Codex runtime command.",
                    payload_json={
                        "command": self._command_preview(),
                        "workdir": context.workdir,
                        "risk_level": self._settings.codex_initial_approval_risk_level,
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
                    {"message": "Waiting for approval before launching Codex runtime"},
                )

                try:
                    await asyncio.wait_for(
                        state.approval_event.wait(),
                        timeout=self._settings.codex_timeout_seconds,
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
                    current_phase="executing_codex_runtime",
                )
                await self._event_service.append_event(
                    task_id,
                    "task.running",
                    {"message": "Approval granted, launching Codex runtime"},
                )

            await self._run_codex_process(task_id, state, context)
        except asyncio.CancelledError:
            logger.info("codex_worker.cancelled", task_id=str(task_id))
            raise
        except Exception as exc:
            logger.exception("codex_worker.error", task_id=str(task_id), error=str(exc))
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
                    "message": "Codex worker crashed",
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

    async def _build_execution_context(self, task_id: UUID) -> _TaskExecutionContext:
        async with self._session_factory() as session:
            task = await session.scalar(select(Task).where(Task.id == task_id))
            if task is None:
                raise RuntimeError("Task not found for execution context")

            messages = (
                (
                    await session.execute(
                        select(TaskMessage)
                        .where(TaskMessage.task_id == task_id)
                        .order_by(TaskMessage.created_at.asc())
                    )
                )
                .scalars()
                .all()
            )

            context_name: str | None = None
            branch: str | None = None
            workdir: str | None = self._settings.codex_default_workdir

            if task.project_context_id is not None:
                context = await session.scalar(
                    select(ProjectContext).where(ProjectContext.id == task.project_context_id)
                )
                if context is not None:
                    context_name = context.name
                    branch = context.branch
                    metadata = context.metadata_json or {}
                    local_path = metadata.get("local_path")
                    if isinstance(local_path, str) and local_path.strip():
                        workdir = local_path.strip()
                    elif context.synced_repository_id is not None:
                        repo = await session.scalar(
                            select(SyncedRepository).where(
                                SyncedRepository.id == context.synced_repository_id
                            )
                        )
                        if repo is not None:
                            workdir = repo.local_path

            prompt_text = self._compose_prompt(task, messages, context_name, branch)
            return _TaskExecutionContext(
                prompt_text=prompt_text,
                workdir=workdir,
                context_name=context_name,
                branch=branch,
            )

    @staticmethod
    def _compose_prompt(
        task: Task,
        messages: list[TaskMessage],
        context_name: str | None,
        branch: str | None,
    ) -> str:
        lines: list[str] = [
            "You are executing a coding task on behalf of a remote mobile client.",
            f"Primary request: {task.prompt}",
        ]

        if context_name:
            lines.append(f"Project context: {context_name}")
        if branch:
            lines.append(f"Branch: {branch}")

        followups = [
            msg.content.strip()
            for msg in messages
            if msg.role == TaskMessageRole.USER
            and msg.content.strip()
            and msg.content.strip() != task.prompt
        ]
        if followups:
            lines.append("Follow-up instructions:")
            for item in followups:
                lines.append(f"- {item}")

        lines.append(
            "Return concise operational logs. Do not include private chain-of-thought. "
            "If you edit files, include file-change summaries."
        )
        return "\n".join(lines)

    async def _run_codex_process(
        self,
        task_id: UUID,
        state: _RuntimeState,
        context: _TaskExecutionContext,
    ) -> None:
        command = [self._settings.codex_command, *shlex.split(self._settings.codex_args)]
        if not command or not command[0]:
            raise RuntimeError("CODEX_COMMAND is empty")

        cwd: str | None = context.workdir
        if cwd is not None:
            path = Path(cwd)
            if not path.exists() or not path.is_dir():
                await self._event_service.append_event(
                    task_id,
                    "task.log",
                    {
                        "message": "Configured workdir does not exist, falling back to server cwd",
                        "workdir": cwd,
                    },
                )
                cwd = None

        await self._event_service.append_event(
            task_id,
            "task.log",
            {
                "message": "Launching Codex runtime process",
                "command": self._command_preview(),
                "workdir": cwd,
            },
        )

        try:
            process = await asyncio.create_subprocess_exec(
                *command,
                cwd=cwd,
                stdin=asyncio.subprocess.PIPE if self._settings.codex_prompt_stdin else None,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
        except FileNotFoundError as exc:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.FAILED,
                current_phase="runtime_unavailable",
                error_message=str(exc),
            )
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": "Codex runtime command not found",
                    "error_code": "WORKER_RUNTIME_UNAVAILABLE",
                    "error": str(exc),
                    "command": self._settings.codex_command,
                    "is_retryable": False,
                },
            )
            return

        async with self._lock:
            state.process = process

        prompt_payload = context.prompt_text
        if state.pending_replies:
            prompt_payload = (
                f"{prompt_payload}\n\nAdditional follow-up instructions received before start:\n"
                + "\n".join(f"- {item}" for item in state.pending_replies)
            )
            state.pending_replies.clear()

        if self._settings.codex_prompt_stdin and process.stdin is not None:
            process.stdin.write((prompt_payload + "\n").encode("utf-8"))
            await process.stdin.drain()
            process.stdin.close()

        stdout_task = asyncio.create_task(
            self._consume_stream(task_id, state, process.stdout, "stdout")
        )
        stderr_task = asyncio.create_task(
            self._consume_stream(task_id, state, process.stderr, "stderr")
        )

        timed_out = False
        try:
            exit_code = await asyncio.wait_for(
                process.wait(),
                timeout=self._settings.codex_timeout_seconds,
            )
        except TimeoutError:
            timed_out = True
            process.kill()
            exit_code = await process.wait()
        finally:
            await asyncio.gather(stdout_task, stderr_task, return_exceptions=True)

        current_status = await self._task_service.get_status(task_id)
        if current_status == TaskStatus.CANCELLED:
            return

        if timed_out:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.FAILED,
                current_phase="runtime_timeout",
                error_message="Codex runtime timed out",
            )
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": "Codex runtime timed out",
                    "error_code": "WORKER_TIMEOUT",
                    "is_retryable": True,
                },
            )
            return

        if exit_code != 0:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.FAILED,
                current_phase="runtime_exit_nonzero",
                error_message=f"Codex runtime exited with code {exit_code}",
            )
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": "Codex runtime exited with non-zero status",
                    "error_code": "WORKER_EXIT_NONZERO",
                    "exit_code": exit_code,
                    "stderr_tail": state.stderr_tail[-20:],
                    "is_retryable": True,
                },
            )
            return

        summary = state.final_summary or "Codex worker completed successfully."
        await self._event_service.append_event(
            task_id,
            "task.completed",
            {
                "message": "Task completed",
                "summary": summary,
                "exit_code": exit_code,
            },
        )
        await self._task_service.transition_for_worker(
            task_id,
            TaskStatus.COMPLETED,
            current_phase="done",
            final_summary=summary,
        )

    async def _consume_stream(
        self,
        task_id: UUID,
        state: _RuntimeState,
        stream: asyncio.StreamReader | None,
        source: str,
    ) -> None:
        if stream is None:
            return

        while True:
            raw = await stream.readline()
            if not raw:
                return
            line = raw.decode("utf-8", errors="replace").strip()
            if not line:
                continue
            await self._handle_output_line(task_id, state, line, source)

    async def _handle_output_line(
        self,
        task_id: UUID,
        state: _RuntimeState,
        line: str,
        source: str,
    ) -> None:
        if source == "stderr":
            state.stderr_tail.append(line)
            if len(state.stderr_tail) > 200:
                state.stderr_tail = state.stderr_tail[-200:]

        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            await self._event_service.append_event(
                task_id,
                "task.log",
                {"message": line, "source": source},
            )
            return

        if not isinstance(payload, dict):
            await self._event_service.append_event(
                task_id,
                "task.log",
                {"message": str(payload), "source": source},
            )
            return

        assistant_message = self._extract_assistant_message(payload)
        if isinstance(assistant_message, str) and assistant_message.strip():
            assistant_message = assistant_message.strip()
            await self._task_service.append_assistant_message(task_id, assistant_message)
            state.final_summary = assistant_message

        final_summary = self._extract_final_summary(payload)
        if isinstance(final_summary, str) and final_summary.strip():
            state.final_summary = final_summary.strip()

        maybe_event_type = payload.get("event_type")
        if maybe_event_type == "task.progress":
            event_payload = payload.get("data")
            if not isinstance(event_payload, dict):
                event_payload = {"message": payload.get("message", "Worker progress update")}
            await self._event_service.append_event(task_id, "task.progress", event_payload)
            return

        event_payload = dict(payload)
        if "source" not in event_payload:
            event_payload["source"] = source
        if "message" not in event_payload:
            event_payload["message"] = "Worker output"
        await self._event_service.append_event(task_id, "task.log", event_payload)

    def _extract_final_summary(self, payload: dict) -> str | None:
        for key in ("final_summary", "summary"):
            value = payload.get(key)
            if isinstance(value, str) and value.strip():
                return value
        return None

    def _extract_assistant_message(self, payload: dict) -> str | None:
        for key in ("assistant_message", "assistant", "final_answer", "output_text"):
            value = payload.get(key)
            if isinstance(value, str) and value.strip():
                return value

        if payload.get("role") == "assistant":
            content = self._extract_content_text(payload.get("content"))
            if content:
                return content

        if payload.get("type") in {"assistant_message", "agent_message"}:
            for key in ("message", "text"):
                message = payload.get(key)
                if isinstance(message, str) and message.strip():
                    return message

        for key in ("message", "msg", "item", "delta", "event"):
            nested = payload.get(key)
            if isinstance(nested, dict):
                message = self._extract_assistant_message(nested)
                if message:
                    return message

        return None

    def _extract_content_text(self, content: object) -> str | None:
        if isinstance(content, str) and content.strip():
            return content
        if isinstance(content, dict):
            for key in ("text", "output_text", "content"):
                value = content.get(key)
                if isinstance(value, str) and value.strip():
                    return value
            return None
        if isinstance(content, list):
            chunks: list[str] = []
            for item in content:
                text = self._extract_content_text(item)
                if text:
                    chunks.append(text)
            if chunks:
                return "\n".join(chunks)
        return None

    async def _write_to_stdin(
        self, task_id: UUID, process: asyncio.subprocess.Process, content: str
    ) -> None:
        stdin = process.stdin
        if stdin is None or stdin.is_closing():
            return
        stdin.write((content.strip() + "\n").encode("utf-8"))
        await stdin.drain()
        await self._event_service.append_event(
            task_id,
            "task.log",
            {"message": "Forwarded follow-up to running Codex process"},
        )

    def _command_preview(self) -> str:
        parts = [self._settings.codex_command, *shlex.split(self._settings.codex_args)]
        return " ".join(parts).strip()
