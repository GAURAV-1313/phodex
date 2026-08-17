"""Owns the Claude Code runtime subprocess: spawning, output streaming, and outcome reporting."""

import asyncio
import json
import os
import shlex
from pathlib import Path
from uuid import UUID

import structlog

from app.core.config import Settings
from app.models.enums import TaskStatus
from app.services.event_service import EventService
from app.services.task_service import TaskService
from app.services.user_ai_settings_service import UserAiSettingsService
from app.workers.claude.output_parser import (
    extract_assistant_text,
    extract_result_subtype,
    extract_result_summary,
    extract_tool_use_summaries,
    is_error_result,
    is_result_event,
    is_system_init,
)
from app.workers.common.state import ExecutionContext, RuntimeState
from app.workers.common.subprocess_io import ManagedSubprocess

logger = structlog.get_logger(__name__)


class ProcessRunner:
    def __init__(
        self,
        settings: Settings,
        task_service: TaskService,
        event_service: EventService,
        lock: asyncio.Lock,
        user_ai_settings_service: UserAiSettingsService,
    ) -> None:
        self._settings = settings
        self._task_service = task_service
        self._event_service = event_service
        self._lock = lock
        self._user_ai_settings_service = user_ai_settings_service

    def _base_args(self, prompt: str, model: str | None) -> list[str]:
        args = [
            self._settings.claude_command,
            "-p",
            prompt,
            "--output-format",
            "stream-json",
            "--verbose",
            "--permission-mode",
            self._settings.claude_permission_mode,
        ]
        if model:
            args += ["--model", model]
        args += shlex.split(self._settings.claude_extra_args)
        return args

    def command_preview(self) -> str:
        return " ".join(self._base_args("<prompt>", None)).strip()

    async def _resolve_overrides(self, task_id: UUID) -> tuple[dict[str, str] | None, str | None]:
        """Looks up this task's owner's optional API-key/model override.

        Returns (env, model) — env is None when no override is set, meaning
        the subprocess inherits this process's environment unchanged (today's
        behavior: relies on `claude login` already being done on this host).
        """
        user_id = await self._task_service.get_user_id(task_id)
        row = await self._user_ai_settings_service.get_decrypted(user_id)
        if row is None:
            return None, None
        env = None
        api_key = self._user_ai_settings_service.decrypt_anthropic_key(row)
        if api_key:
            env = {**os.environ, "ANTHROPIC_API_KEY": api_key}
        return env, row.preferred_claude_model

    async def run(self, task_id: UUID, state: RuntimeState, context: ExecutionContext) -> None:
        env, model = await self._resolve_overrides(task_id)
        command = self._base_args(context.prompt_text, model)
        if not command or not command[0]:
            raise RuntimeError("CLAUDE_COMMAND is empty")

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
                "message": "Launching Claude runtime process",
                "command": self.command_preview(),
                "workdir": cwd,
            },
        )

        try:
            managed = await ManagedSubprocess.spawn(command, cwd=cwd, use_stdin=False, env=env)
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
                    "message": "Claude runtime command not found",
                    "error_code": "WORKER_RUNTIME_UNAVAILABLE",
                    "error": str(exc),
                    "command": self._settings.claude_command,
                    "is_retryable": False,
                },
            )
            return

        async with self._lock:
            state.process = managed.process

        managed.start_streaming(
            lambda line, source: self._handle_output_line(task_id, state, line, source)
        )
        exit_code, timed_out = await managed.wait(self._settings.claude_timeout_seconds)

        current_status = await self._task_service.get_status(task_id)
        if current_status == TaskStatus.CANCELLED:
            return

        if timed_out:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.FAILED,
                current_phase="runtime_timeout",
                error_message="Claude runtime timed out",
            )
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": "Claude runtime timed out",
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
                error_message=f"Claude runtime exited with code {exit_code}",
            )
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": "Claude runtime exited with non-zero status",
                    "error_code": "WORKER_EXIT_NONZERO",
                    "exit_code": exit_code,
                    "stderr_tail": state.stderr_tail[-20:],
                    "is_retryable": True,
                },
            )
            return

        summary = state.final_summary or "Claude worker completed successfully."
        if state.runtime_reported_error:
            await self._task_service.transition_for_worker(
                task_id,
                TaskStatus.FAILED,
                current_phase="runtime_blocked",
                error_message=summary,
                final_summary=summary,
            )
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": "Claude runtime reported an error outcome",
                    "error_code": "WORKER_BLOCKED",
                    "summary": summary,
                    "exit_code": exit_code,
                    "is_retryable": True,
                },
            )
            return

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

    async def _handle_output_line(
        self,
        task_id: UUID,
        state: RuntimeState,
        line: str,
        source: str,
    ) -> None:
        if source == "stderr":
            state.stderr_tail.append(line)
            if len(state.stderr_tail) > 200:
                state.stderr_tail = state.stderr_tail[-200:]
            await self._event_service.append_event(
                task_id, "task.log", {"message": line, "source": source}
            )
            return

        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            await self._event_service.append_event(
                task_id, "task.log", {"message": line, "source": source}
            )
            return

        if not isinstance(payload, dict):
            await self._event_service.append_event(
                task_id, "task.log", {"message": str(payload), "source": source}
            )
            return

        if is_system_init(payload):
            await self._event_service.append_event(
                task_id, "task.log", {"message": "Claude runtime started", "source": source}
            )
            return

        if is_result_event(payload):
            result_text = extract_result_summary(payload)
            if result_text:
                state.final_summary = result_text
            state.runtime_reported_error = is_error_result(payload)
            await self._event_service.append_event(
                task_id,
                "task.progress",
                {
                    "message": "Claude runtime finished its turn",
                    "is_error": state.runtime_reported_error,
                    "subtype": extract_result_subtype(payload),
                },
            )
            return

        assistant_text = extract_assistant_text(payload)
        if assistant_text:
            await self._task_service.append_assistant_message(task_id, assistant_text)
            state.final_summary = assistant_text

        for tool_summary in extract_tool_use_summaries(payload):
            await self._event_service.append_event(
                task_id,
                "task.log",
                {"message": f"Tool call: {tool_summary}", "source": source},
            )

    async def write_to_stdin(
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
            {"message": "Forwarded follow-up to running Claude process"},
        )
