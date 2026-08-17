"""Owns the Codex runtime subprocess: spawning, stdin/stdout wiring, and outcome reporting."""

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
from app.workers.codex.output_parser import (
    extract_assistant_message,
    extract_final_summary,
    is_blocked_outcome,
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

    def command_preview(self) -> str:
        parts = [self._settings.codex_command, *shlex.split(self._settings.codex_args)]
        return " ".join(parts).strip()

    async def _resolve_overrides(self, task_id: UUID) -> tuple[dict[str, str] | None, str | None]:
        """Looks up this task's owner's optional API-key/model override.

        Returns (env, model) — env is None when no override is set, meaning
        the subprocess inherits this process's environment unchanged (today's
        behavior: relies on `codex login` already being done on this host).
        """
        user_id = await self._task_service.get_user_id(task_id)
        row = await self._user_ai_settings_service.get_decrypted(user_id)
        if row is None:
            return None, None
        env = None
        api_key = self._user_ai_settings_service.decrypt_openai_key(row)
        if api_key:
            env = {**os.environ, "OPENAI_API_KEY": api_key}
        return env, row.preferred_codex_model

    async def run(self, task_id: UUID, state: RuntimeState, context: ExecutionContext) -> None:
        env, model = await self._resolve_overrides(task_id)
        arg_tokens = shlex.split(self._settings.codex_args)
        if model:
            # `--model` is scoped to the `exec` subcommand (`codex exec --help`),
            # not a top-level `codex` flag, and CODEX_ARGS often ends in a bare
            # `-` (stdin prompt marker) — so insert right after the subcommand
            # token rather than appending at the end, where it could land after
            # that positional and be misparsed.
            insert_at = 1 if arg_tokens[:1] == ["exec"] else len(arg_tokens)
            arg_tokens = arg_tokens[:insert_at] + ["--model", model] + arg_tokens[insert_at:]
        command = [self._settings.codex_command, *arg_tokens]
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
                "command": self.command_preview(),
                "workdir": cwd,
            },
        )

        use_stdin = self._settings.codex_prompt_stdin
        try:
            managed = await ManagedSubprocess.spawn(command, cwd=cwd, use_stdin=use_stdin, env=env)
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
            state.process = managed.process

        prompt_payload = context.prompt_text
        if state.pending_replies:
            prompt_payload = (
                f"{prompt_payload}\n\nAdditional follow-up instructions received before start:\n"
                + "\n".join(f"- {item}" for item in state.pending_replies)
            )
            state.pending_replies.clear()

        if use_stdin:
            await managed.send_and_close_stdin(prompt_payload)

        managed.start_streaming(
            lambda line, source: self._handle_output_line(task_id, state, line, source)
        )
        exit_code, timed_out = await managed.wait(self._settings.codex_timeout_seconds)

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
        if is_blocked_outcome(summary):
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
                    "message": "Codex runtime reported a blocked outcome",
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

        assistant_message = extract_assistant_message(payload)
        if isinstance(assistant_message, str) and assistant_message.strip():
            assistant_message = assistant_message.strip()
            await self._task_service.append_assistant_message(task_id, assistant_message)
            state.final_summary = assistant_message

        final_summary = extract_final_summary(payload)
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
            {"message": "Forwarded follow-up to running Codex process"},
        )
