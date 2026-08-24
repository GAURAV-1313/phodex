"""Builds an execution context (prompt text + workdir) from stored task state.

Shared by every subprocess-backed worker engine: which runtime interprets the
prompt differs, but how the prompt is assembled from the task/messages/project
context does not. Each engine supplies its own tail `instructions` (e.g. an
OUTCOME sentinel convention) since that part is genuinely runtime-specific.
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.enums import TaskMessageRole
from app.models.project_context import ProjectContext
from app.models.synced_repository import SyncedRepository
from app.models.task import Task
from app.models.task_message import TaskMessage
from workers.common.state import ExecutionContext


class ExecutionContextBuilder:
    def __init__(
        self,
        default_workdir: str | None,
        session_factory: async_sessionmaker[AsyncSession],
        instructions: str,
    ) -> None:
        self._default_workdir = default_workdir
        self._session_factory = session_factory
        self._instructions = instructions

    async def build(self, task_id: UUID) -> ExecutionContext:
        async with self._session_factory() as session:
            task = await session.scalar(select(Task).where(Task.id == task_id))
            if task is None:
                raise RuntimeError("Task not found for execution context")

            messages = list(
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
            workdir = self._default_workdir

            if task.project_context_id is not None:
                context = await session.scalar(
                    select(ProjectContext).where(ProjectContext.id == task.project_context_id)
                )
                if context is not None:
                    context_name = context.name
                    branch = context.branch
                    workdir = await resolve_workdir(session, context, self._default_workdir)

            prompt_text = compose_prompt(
                task, messages, context_name, branch, self._instructions
            )
            return ExecutionContext(
                prompt_text=prompt_text,
                workdir=workdir,
                context_name=context_name,
                branch=branch,
            )


async def resolve_workdir(
    session: AsyncSession,
    context: ProjectContext,
    default_workdir: str | None = None,
) -> str | None:
    """Resolves the real local working directory for a project context.

    Shared by prompt-composing worker engines and by anything else (e.g. git
    operations) that needs to know which real directory on disk a task's
    changes live in.
    """
    metadata = context.metadata_json or {}
    local_path = metadata.get("local_path")
    if isinstance(local_path, str) and local_path.strip():
        return local_path.strip()

    if context.synced_repository_id is not None:
        repo = await session.scalar(
            select(SyncedRepository).where(SyncedRepository.id == context.synced_repository_id)
        )
        if repo is not None:
            return repo.local_path

    return default_workdir


def compose_prompt(
    task: Task,
    messages: list[TaskMessage],
    context_name: str | None,
    branch: str | None,
    instructions: str,
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

    lines.append(instructions)
    return "\n".join(lines)
