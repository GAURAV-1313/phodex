"""Codex-specific wiring on top of the shared subprocess worker orchestrator."""

import asyncio

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.services.approval_service import ApprovalService
from app.services.event_service import EventService
from app.services.task_service import TaskService
from app.services.user_ai_settings_service import UserAiSettingsService
from app.workers.codex.process_runner import ProcessRunner
from app.workers.common.context import ExecutionContextBuilder
from app.workers.common.orchestrator import SubprocessWorkerOrchestrator


class CodexWorkerEngine(SubprocessWorkerOrchestrator):
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

    engine_label = "Codex"

    def __init__(
        self,
        settings: Settings,
        session_factory: async_sessionmaker[AsyncSession],
        task_service: TaskService,
        event_service: EventService,
        approval_service: ApprovalService,
        user_ai_settings_service: UserAiSettingsService,
    ) -> None:
        lock = asyncio.Lock()
        context_builder = ExecutionContextBuilder(
            default_workdir=settings.codex_default_workdir,
            session_factory=session_factory,
            instructions=(
                "Return concise operational logs. Do not include private chain-of-thought. "
                "If you edit files, include file-change summaries. End the final response with "
                "exactly one outcome line: OUTCOME: COMPLETED, OUTCOME: BLOCKED, or OUTCOME: FAILED."
            ),
        )
        process_runner = ProcessRunner(
            settings=settings,
            task_service=task_service,
            event_service=event_service,
            lock=lock,
            user_ai_settings_service=user_ai_settings_service,
        )
        super().__init__(
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
            context_builder=context_builder,
            process_runner=process_runner,
            require_initial_approval=settings.codex_require_initial_approval,
            initial_approval_risk_level=settings.codex_initial_approval_risk_level,
            timeout_seconds=settings.codex_timeout_seconds,
            lock=lock,
        )
