"""Claude-specific wiring on top of the shared subprocess worker orchestrator."""

import asyncio

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.services.approval_service import ApprovalService
from app.services.event_service import EventService
from app.services.task_service import TaskService
from app.services.user_ai_settings_service import UserAiSettingsService
from workers.claude.process_runner import ProcessRunner
from workers.common.context import ExecutionContextBuilder
from workers.common.orchestrator import SubprocessWorkerOrchestrator


class ClaudeWorkerEngine(SubprocessWorkerOrchestrator):
    """
    Worker adapter that runs tasks through the Claude Code CLI in headless mode
    (`claude -p ... --output-format stream-json`).

    Configured through settings:
      - CLAUDE_COMMAND
      - CLAUDE_EXTRA_ARGS
      - CLAUDE_PERMISSION_MODE
      - CLAUDE_TIMEOUT_SECONDS
      - CLAUDE_REQUIRE_INITIAL_APPROVAL
      - CLAUDE_DEFAULT_WORKDIR

    Unlike Codex, completion/failure is reported structurally by the CLI's
    terminal `result` event (`is_error`) rather than an OUTCOME sentinel the
    model is asked to emit, so no such convention appears in the prompt.
    """

    engine_label = "Claude"

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
            default_workdir=settings.claude_default_workdir,
            session_factory=session_factory,
            instructions=(
                "Return concise operational logs. Do not include private chain-of-thought. "
                "If you edit files, include file-change summaries."
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
            require_initial_approval=settings.claude_require_initial_approval,
            initial_approval_risk_level=settings.claude_initial_approval_risk_level,
            timeout_seconds=settings.claude_timeout_seconds,
            lock=lock,
        )
