"""Anthropic Managed Agents as a Phodex worker engine.

Anthropic hosts the agent loop and a per-session sandbox, so this server needs
no CLI, no Node, and no workspace directory — only a GitHub repository (the
token is injected by Anthropic's git proxy, never inside the sandbox). The
shared orchestrator still owns the lifecycle state machine and the optional
initial approval gate; the session runner maps the session's event stream onto
Phodex events and turns `always_ask` tool calls into approval requests.
"""

import asyncio
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.services.approval_service import ApprovalService
from app.services.event_service import EventService
from app.services.task_service import TaskService
from app.services.user_ai_settings_service import UserAiSettingsService
from workers.common.context import ExecutionContextBuilder
from workers.common.orchestrator import SubprocessWorkerOrchestrator
from workers.managed.session_runner import ClientFactory, ManagedSessionRunner


class ManagedAgentWorkerEngine(SubprocessWorkerOrchestrator):
    engine_label = "Managed"

    def __init__(
        self,
        settings: Settings,
        session_factory: async_sessionmaker[AsyncSession],
        task_service: TaskService,
        event_service: EventService,
        approval_service: ApprovalService,
        user_ai_settings_service: UserAiSettingsService,
        client_factory: ClientFactory | None = None,
    ) -> None:
        lock = asyncio.Lock()
        context_builder = ExecutionContextBuilder(
            default_workdir=None,
            session_factory=session_factory,
            instructions=(
                "You are working inside a cloud sandbox with the repository mounted under "
                "/workspace. Make the change, run any relevant checks, commit on the current "
                "branch and push. Return concise operational logs and a final summary of "
                "the files you changed. Do not include private chain-of-thought."
            ),
        )
        self._runner = ManagedSessionRunner(
            settings=settings,
            session_factory=session_factory,
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
            user_ai_settings_service=user_ai_settings_service,
            lock=lock,
            client_factory=client_factory,
        )
        super().__init__(
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
            context_builder=context_builder,
            process_runner=self._runner,
            require_initial_approval=settings.managed_require_initial_approval,
            initial_approval_risk_level=settings.managed_initial_approval_risk_level,
            timeout_seconds=settings.managed_timeout_seconds,
            lock=lock,
        )

    async def handle_approval(self, task_id: UUID, approval_id: UUID, approved: bool) -> None:
        if approved:
            await super().handle_approval(task_id, approval_id, approved)
            return
        # ApprovalService has already marked the task FAILED before this
        # callback, so the base class (which requires WAITING_APPROVAL) would
        # ignore the rejection and leave the sandbox waiting. Release the
        # runner so it sends the deny + interrupt promptly.
        async with self._lock:
            state = self._states.get(task_id)
            if state is None or state.approval_id != approval_id:
                return
            state.approval_granted = False
            state.approval_event.set()

    async def handle_user_reply(self, task_id: UUID, content: str) -> None:
        if await self._runner.send_user_message(task_id, content):
            return
        async with self._lock:
            state = self._states.get(task_id)
            if state is None:
                return
            state.pending_replies.append(content)
        await self._event_service.append_event(
            task_id,
            "task.log",
            {
                "message": "Worker queued follow-up for next execution step",
                "queued_followup": content,
            },
        )

    async def cancel_task(self, task_id: UUID) -> None:
        await self._runner.interrupt(task_id)
        await super().cancel_task(task_id)
