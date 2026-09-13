"""Runs a task as an Anthropic Managed Agents session.

Where the Claude/Codex engines spawn a CLI subprocess on this machine, this
runner asks Anthropic to host both the agent loop and a per-session sandbox:
the task's GitHub repository is mounted into that sandbox (the token is
injected by Anthropic's git proxy and never enters the container), the prompt
is sent as the first user message, and the session's event stream is mapped
onto Phodex's task events, assistant messages, and approval gate.

Mapping to the WorkerEngine interface (see engine.py):
  dispatch_task      -> sessions.create + user.message
  handle_approval    -> user.tool_confirmation (bash is `always_ask` on the agent)
  handle_user_reply  -> user.message
  cancel_task        -> user.interrupt
"""

import asyncio
import json
import threading
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any
from uuid import UUID

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.models.enums import ProjectContextSourceType, TaskStatus
from app.models.project_context import ProjectContext
from app.models.task import Task
from app.services.approval_service import ApprovalService
from app.services.event_service import EventService
from app.services.task_service import TaskService
from app.services.user_ai_settings_service import UserAiSettingsService
from workers.common.state import ExecutionContext, RuntimeState

logger = structlog.get_logger(__name__)

ClientFactory = Callable[[str | None], Any]

_STREAM_OPEN = object()
_STREAM_CLOSED = object()
_MAX_RECONNECTS = 3
_RESULT_PREVIEW_CHARS = 600


def default_client_factory(api_key: str | None) -> Any:
    """Builds the Anthropic SDK client lazily so the SDK is only required when
    the managed engine is actually selected."""
    import anthropic

    return anthropic.Anthropic(api_key=api_key) if api_key else anthropic.Anthropic()


class _StreamError:
    def __init__(self, error: BaseException) -> None:
        self.error = error


@dataclass
class LiveSession:
    session_id: str
    client: Any
    pending_tool: Any | None = None
    seen_event_ids: set[str] = field(default_factory=set)
    completed: bool = False


def _get(obj: Any, name: str, default: Any = None) -> Any:
    """Field access that works for SDK models, dicts, and test doubles."""
    if isinstance(obj, dict):
        return obj.get(name, default)
    return getattr(obj, name, default)


def _text_of(content: Any) -> str:
    if isinstance(content, str):
        return content
    parts: list[str] = []
    for block in content or []:
        if _get(block, "type") == "text":
            parts.append(str(_get(block, "text", "")))
    return "\n".join(part for part in parts if part).strip()


def _summarize_input(value: Any) -> str:
    try:
        text = json.dumps(value, default=str) if not isinstance(value, str) else value
    except TypeError:
        text = str(value)
    return text if len(text) <= _RESULT_PREVIEW_CHARS else text[:_RESULT_PREVIEW_CHARS] + "…"


class ManagedSessionRunner:
    def __init__(
        self,
        settings: Settings,
        session_factory: async_sessionmaker[AsyncSession],
        task_service: TaskService,
        event_service: EventService,
        approval_service: ApprovalService,
        user_ai_settings_service: UserAiSettingsService,
        lock: asyncio.Lock,
        client_factory: ClientFactory | None = None,
    ) -> None:
        self._settings = settings
        self._session_factory = session_factory
        self._task_service = task_service
        self._event_service = event_service
        self._approval_service = approval_service
        self._user_ai_settings_service = user_ai_settings_service
        self._lock = lock
        self._client_factory = client_factory or default_client_factory
        self._live: dict[UUID, LiveSession] = {}

    # ------------------------------------------------------- protocol surface

    def command_preview(self) -> str:
        return (
            f"managed-agent {self._settings.managed_agent_id or '<unset>'} "
            f"(environment {self._settings.managed_environment_id or '<unset>'})"
        )

    async def write_to_stdin(
        self, task_id: UUID, process: asyncio.subprocess.Process, content: str
    ) -> None:  # pragma: no cover - the orchestrator never has a process for us
        await self.send_user_message(task_id, content)

    async def send_user_message(self, task_id: UUID, content: str) -> bool:
        live = self._live.get(task_id)
        if live is None:
            return False
        await self._send(live, [_user_message(content)])
        await self._event_service.append_event(
            task_id, "task.log", {"message": "Forwarded follow-up to the managed session"}
        )
        return True

    async def interrupt(self, task_id: UUID) -> None:
        live = self._live.get(task_id)
        if live is None:
            return
        try:
            await self._send(live, [{"type": "user.interrupt"}])
        except Exception as exc:
            logger.warning("managed.interrupt_failed", task_id=str(task_id), error=str(exc))

    # ----------------------------------------------------------------- run

    async def run(self, task_id: UUID, state: RuntimeState, context: ExecutionContext) -> None:
        repo = await self._load_repo(task_id)
        if repo is None:
            await self._fail(
                task_id,
                phase="managed_repo_required",
                message="The managed engine needs a GitHub repository. Connect one first.",
                code="MANAGED_REPO_REQUIRED",
                retryable=False,
            )
            return
        repo_url, branch = repo

        if not self._settings.managed_agent_id or not self._settings.managed_environment_id:
            await self._fail(
                task_id,
                phase="managed_not_configured",
                message=(
                    "MANAGED_AGENT_ID / MANAGED_ENVIRONMENT_ID are not set. "
                    "Run scripts/setup_managed_agent.py once and add them to the environment."
                ),
                code="MANAGED_NOT_CONFIGURED",
                retryable=False,
            )
            return

        user_id = await self._task_service.get_user_id(task_id)
        token = await self._user_ai_settings_service.get_github_token(user_id)
        token = token or self._settings.github_default_token
        if not token:
            await self._fail(
                task_id,
                phase="managed_github_token_missing",
                message="A GitHub token is required so the managed sandbox can clone and push.",
                code="MANAGED_GITHUB_TOKEN_MISSING",
                retryable=True,
            )
            return

        api_key = None
        settings_row = await self._user_ai_settings_service.get_decrypted(user_id)
        if settings_row is not None:
            api_key = self._user_ai_settings_service.decrypt_anthropic_key(settings_row)

        try:
            client = self._client_factory(api_key)
            resources = [
                {
                    "type": "github_repository",
                    "url": repo_url,
                    "authorization_token": token,
                    **({"checkout": {"type": "branch", "name": branch}} if branch else {}),
                }
            ]
            session = await asyncio.to_thread(
                client.beta.sessions.create,
                agent=self._settings.managed_agent_id,
                environment_id=self._settings.managed_environment_id,
                title=f"Phodex task {task_id}",
                resources=resources,
                metadata={"phodex_task_id": str(task_id)},
            )
        except Exception as exc:
            await self._fail(
                task_id,
                phase="managed_session_create_failed",
                message=f"Could not start the managed session: {exc}",
                code="MANAGED_SESSION_CREATE_FAILED",
                retryable=True,
            )
            return

        live = LiveSession(session_id=str(_get(session, "id")), client=client)
        async with self._lock:
            self._live[task_id] = live
        await self._event_service.append_event(
            task_id,
            "task.log",
            {
                "message": "Managed agent session created",
                "session_id": live.session_id,
                "repository": repo_url,
                "branch": branch,
            },
        )

        try:
            await self._drive(task_id, state, live, context.prompt_text)
        finally:
            async with self._lock:
                self._live.pop(task_id, None)

    # ------------------------------------------------------------- streaming

    async def _drive(
        self, task_id: UUID, state: RuntimeState, live: LiveSession, prompt: str
    ) -> None:
        loop = asyncio.get_running_loop()
        deadline = loop.time() + self._settings.managed_timeout_seconds
        reconnects = 0
        first_message_sent = False

        while True:
            queue: asyncio.Queue[Any] = asyncio.Queue()
            stop = threading.Event()
            pump = asyncio.create_task(asyncio.to_thread(self._pump, live, queue, stop, loop))
            try:
                opened = await asyncio.wait_for(queue.get(), timeout=60)
            except TimeoutError:
                opened = _StreamError(TimeoutError("stream did not open"))
            if isinstance(opened, _StreamError):
                stop.set()
                await self._fail(
                    task_id,
                    phase="managed_stream_failed",
                    message=f"Could not open the managed session stream: {opened.error}",
                    code="MANAGED_STREAM_FAILED",
                    retryable=True,
                )
                return

            if not first_message_sent:
                # Stream-first: the message is sent only once the stream is open,
                # so no early event is missed.
                await self._send(live, [_user_message(prompt)])
                first_message_sent = True
            else:
                # Reconnect with consolidation: replay history we may have
                # missed while the stream was down (deduped by event id).
                for event in await self._history(live):
                    done = await self._handle_event(task_id, state, live, event)
                    if done:
                        stop.set()
                        return

            stream_closed = False
            while True:
                remaining = deadline - loop.time()
                if remaining <= 0:
                    stop.set()
                    await self.interrupt(task_id)
                    await self._fail(
                        task_id,
                        phase="runtime_timeout",
                        message="Managed session timed out",
                        code="WORKER_TIMEOUT",
                        retryable=True,
                    )
                    return
                try:
                    event = await asyncio.wait_for(queue.get(), timeout=remaining)
                except TimeoutError:
                    continue
                if event is _STREAM_CLOSED:
                    stream_closed = True
                    break
                if isinstance(event, _StreamError):
                    logger.warning(
                        "managed.stream_error", task_id=str(task_id), error=str(event.error)
                    )
                    stream_closed = True
                    break
                done = await self._handle_event(task_id, state, live, event)
                if done:
                    stop.set()
                    return

            await pump
            if not stream_closed:
                return
            reconnects += 1
            if reconnects > _MAX_RECONNECTS:
                await self._fail(
                    task_id,
                    phase="managed_stream_lost",
                    message="Lost the managed session stream",
                    code="MANAGED_STREAM_LOST",
                    retryable=True,
                )
                return
            await self._event_service.append_event(
                task_id,
                "task.log",
                {"message": f"Reconnecting to managed session (attempt {reconnects})"},
            )

    def _pump(
        self,
        live: LiveSession,
        queue: asyncio.Queue[Any],
        stop: threading.Event,
        loop: asyncio.AbstractEventLoop,
    ) -> None:
        try:
            with live.client.beta.sessions.events.stream(session_id=live.session_id) as stream:
                loop.call_soon_threadsafe(queue.put_nowait, _STREAM_OPEN)
                for event in stream:
                    if stop.is_set():
                        break
                    loop.call_soon_threadsafe(queue.put_nowait, event)
        except Exception as exc:  # surfaced to the async side
            loop.call_soon_threadsafe(queue.put_nowait, _StreamError(exc))
        finally:
            loop.call_soon_threadsafe(queue.put_nowait, _STREAM_CLOSED)

    async def _history(self, live: LiveSession) -> list[Any]:
        try:
            page = await asyncio.to_thread(
                live.client.beta.sessions.events.list, session_id=live.session_id
            )
        except Exception as exc:
            logger.warning("managed.history_failed", error=str(exc))
            return []
        return list(_get(page, "data", []) or [])

    async def _send(self, live: LiveSession, events: list[dict[str, Any]]) -> None:
        await asyncio.to_thread(
            live.client.beta.sessions.events.send, session_id=live.session_id, events=events
        )

    # --------------------------------------------------------------- events

    async def _handle_event(
        self, task_id: UUID, state: RuntimeState, live: LiveSession, event: Any
    ) -> bool:
        """Maps one session event onto Phodex state. Returns True when the task
        reached a terminal state and streaming should stop."""
        event_id = _get(event, "id")
        if event_id:
            if event_id in live.seen_event_ids:
                return False
            live.seen_event_ids.add(str(event_id))

        etype = str(_get(event, "type", ""))
        if etype == "agent.message":
            text = _text_of(_get(event, "content"))
            if text:
                await self._task_service.append_assistant_message(task_id, text)
                state.final_summary = text
            return False

        if etype == "agent.thinking":
            await self._event_service.append_event(
                task_id, "task.progress", {"message": "Agent is thinking"}
            )
            return False

        if etype in {"agent.tool_use", "agent.mcp_tool_use"}:
            name = str(_get(event, "name", "tool"))
            await self._event_service.append_event(
                task_id,
                "task.log",
                {
                    "message": f"Tool call: {name}({_summarize_input(_get(event, 'input'))})",
                    "tool": name,
                },
            )
            live.pending_tool = event
            return False

        if etype in {"agent.tool_result", "agent.mcp_tool_result"}:
            live.pending_tool = None
            output = _text_of(_get(event, "content")) or _summarize_input(_get(event, "output"))
            if output:
                await self._event_service.append_event(
                    task_id, "task.log", {"message": f"Tool result: {_summarize_input(output)}"}
                )
            return False

        if etype == "session.status_running":
            await self._event_service.append_event(
                task_id, "task.progress", {"message": "Managed agent is working"}
            )
            return False

        if etype == "session.status_idle":
            stop_reason = _get(event, "stop_reason")
            if live.pending_tool is not None and stop_reason in {None, "requires_action"}:
                return await self._confirm_tool(task_id, state, live)
            if state.pending_replies:
                await self._send(live, [_user_message(state.pending_replies.pop(0))])
                await self._event_service.append_event(
                    task_id, "task.log", {"message": "Sent queued follow-up to the managed session"}
                )
                return False
            if stop_reason == "budget_reached":
                await self._fail(
                    task_id,
                    phase="managed_budget_reached",
                    message="Managed session reached its budget",
                    code="MANAGED_BUDGET_REACHED",
                    retryable=False,
                )
                return True
            await self._complete(task_id, state)
            live.completed = True
            return True

        if etype == "session.error":
            await self._fail(
                task_id,
                phase="worker_error",
                message=str(_get(event, "message") or _get(event, "error") or "Session error"),
                code="WORKER_ERROR",
                retryable=True,
            )
            return True

        if etype == "session.status_terminated":
            if live.completed:
                return True
            current = await self._task_service.get_status(task_id)
            if current in {TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.CANCELLED}:
                return True
            await self._fail(
                task_id,
                phase="managed_session_terminated",
                message="Managed session ended before the task completed",
                code="MANAGED_SESSION_TERMINATED",
                retryable=True,
            )
            return True

        return False

    async def _confirm_tool(self, task_id: UUID, state: RuntimeState, live: LiveSession) -> bool:
        tool = live.pending_tool
        name = str(_get(tool, "name", "tool"))
        tool_use_id = str(_get(tool, "id", ""))
        approval = await self._approval_service.create_approval_request(
            task_id=task_id,
            kind="tool_use",
            title=f"Allow {name}?",
            description=f"The managed agent wants to run the {name} tool in the cloud sandbox.",
            payload_json={
                "tool": name,
                "input": _get(tool, "input"),
                "session_id": live.session_id,
                "risk_level": self._settings.managed_initial_approval_risk_level,
            },
        )
        async with self._lock:
            state.approval_id = approval.id
            state.approval_granted = None
            state.approval_event = asyncio.Event()

        await self._task_service.transition_for_worker(
            task_id, TaskStatus.WAITING_APPROVAL, current_phase="awaiting_tool_approval"
        )
        await self._event_service.append_event(
            task_id,
            "task.progress",
            {"message": f"Waiting for approval to run {name}", "tool": name},
        )
        try:
            await asyncio.wait_for(
                state.approval_event.wait(), timeout=self._settings.managed_timeout_seconds
            )
        except TimeoutError:
            await self.interrupt(task_id)
            await self._fail(
                task_id,
                phase="approval_timeout",
                message="Approval timed out",
                code="APPROVAL_TIMEOUT",
                retryable=True,
            )
            return True

        granted = state.approval_granted is True
        live.pending_tool = None
        await self._send(
            live,
            [
                {
                    "type": "user.tool_confirmation",
                    "tool_use_id": tool_use_id,
                    "result": "allow" if granted else "deny",
                    **({} if granted else {"message": "The user rejected this action."}),
                }
            ],
        )
        if not granted:
            # ApprovalService already marked the task FAILED (APPROVAL_REJECTED);
            # stop the agent so the sandbox does not keep working.
            await self.interrupt(task_id)
            return True

        await self._task_service.transition_for_worker(
            task_id, TaskStatus.RUNNING, current_phase="executing_managed_session"
        )
        await self._event_service.append_event(
            task_id, "task.running", {"message": f"Approval granted, {name} is running"}
        )
        return False

    # -------------------------------------------------------------- helpers

    async def _complete(self, task_id: UUID, state: RuntimeState) -> None:
        summary = state.final_summary or "Managed agent completed the task."
        await self._event_service.append_event(
            task_id, "task.completed", {"message": "Task completed", "summary": summary}
        )
        await self._task_service.transition_for_worker(
            task_id, TaskStatus.COMPLETED, current_phase="done", final_summary=summary
        )

    async def _fail(
        self, task_id: UUID, *, phase: str, message: str, code: str, retryable: bool
    ) -> None:
        await self._task_service.transition_for_worker(
            task_id, TaskStatus.FAILED, current_phase=phase, error_message=message
        )
        await self._event_service.append_event(
            task_id,
            "task.failed",
            {"message": message, "error_code": code, "is_retryable": retryable},
        )

    async def _load_repo(self, task_id: UUID) -> tuple[str, str | None] | None:
        async with self._session_factory() as session:
            task = await session.scalar(select(Task).where(Task.id == task_id))
            if task is None or task.project_context_id is None:
                return None
            context = await session.scalar(
                select(ProjectContext).where(ProjectContext.id == task.project_context_id)
            )
            if context is None:
                return None
            metadata = context.metadata_json or {}
            url = context.repo_url or metadata.get("url")
            is_github = (
                context.source_type == ProjectContextSourceType.GITHUB
                or metadata.get("source") == "github"
            )
            if not is_github or not isinstance(url, str) or not url:
                return None
            return url, context.branch


def _user_message(text: str) -> dict[str, Any]:
    return {"type": "user.message", "content": [{"type": "text", "text": text}]}
