"""Runs real git commands directly on this machine's working tree.

Phodex is local-first: the backend already runs on the same machine as the
repos it touches, so "commit and push" is a literal subprocess here — no
GitHub API, no stored GitHub credentials. It reuses whatever git auth (SSH
key, `gh` CLI, credential manager) is already configured on this machine,
the same trust model already used for the Codex/Claude CLI.
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.enums import GitOperationStatus
from app.models.git_operation import GitOperation
from app.models.project_context import ProjectContext
from app.models.task import Task
from app.services.event_service import EventService
from app.services.exceptions import ConflictError, NotFoundError
from app.workers.common.context import resolve_workdir
from app.workers.common.subprocess_io import ManagedSubprocess


class GitService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        event_service: EventService,
    ) -> None:
        self._session_factory = session_factory
        self._event_service = event_service

    async def prepare_commit(self, user_id: UUID, task_id: UUID) -> GitOperation:
        async with self._session_factory() as session:
            task = await session.scalar(
                select(Task).where(Task.id == task_id, Task.user_id == user_id)
            )
            if task is None:
                raise NotFoundError("Task not found")

            repo_path: str | None = None
            if task.project_context_id is not None:
                context = await session.scalar(
                    select(ProjectContext).where(ProjectContext.id == task.project_context_id)
                )
                if context is not None:
                    repo_path = await resolve_workdir(session, context)
            if not repo_path:
                raise ConflictError("Task has no synced repository to commit changes in")
            default_message = task.title or task.prompt[:72]

        # Runs the actual git subprocesses outside the DB session — these can
        # take a moment and shouldn't hold a connection/transaction open.
        status_output = await self._run_git_capture(repo_path, ["status", "--porcelain"])
        diff_stat_output = await self._run_git_capture(repo_path, ["diff", "--stat"])

        async with self._session_factory() as session:
            operation = GitOperation(
                task_id=task_id,
                repo_path=repo_path,
                commit_message=f"Phodex: {default_message}",
                status=GitOperationStatus.PENDING_REVIEW,
                status_output=status_output,
                diff_stat_output=diff_stat_output,
            )
            session.add(operation)
            await session.commit()
            await session.refresh(operation)

        return operation

    async def confirm(
        self, user_id: UUID, task_id: UUID, git_operation_id: UUID, commit_message: str | None
    ) -> GitOperation:
        operation = await self._load_pending(user_id, task_id, git_operation_id)
        if commit_message and commit_message.strip():
            operation.commit_message = commit_message.strip()

        await self._set_status(
            operation.id, GitOperationStatus.RUNNING, commit_message=operation.commit_message
        )
        await self._event_service.append_event(
            task_id,
            "git.started",
            {"message": "Committing and pushing changes", "repo_path": operation.repo_path},
        )

        try:
            await self._run_git_streamed(task_id, operation.repo_path, ["add", "-A"])
            await self._run_git_streamed(
                task_id, operation.repo_path, ["commit", "-m", operation.commit_message]
            )
            # `-u origin HEAD` rather than a bare `push`: sets upstream tracking
            # on the current branch's first-ever push (a bare `push` fails with
            # "no upstream branch" then), and is a harmless no-op once tracking
            # is already configured on later pushes.
            await self._run_git_streamed(
                task_id, operation.repo_path, ["push", "-u", "origin", "HEAD"]
            )
            pushed_branch = (
                await self._run_git_capture(
                    operation.repo_path, ["rev-parse", "--abbrev-ref", "HEAD"]
                )
            ).strip()
        except GitCommandError as exc:
            await self._set_status(operation.id, GitOperationStatus.FAILED, error_message=str(exc))
            await self._event_service.append_event(
                task_id,
                "git.failed",
                {
                    "message": "Commit/push failed",
                    "error": str(exc),
                    "error_code": "GIT_COMMAND_FAILED",
                    "is_retryable": True,
                },
            )
            return await self._reload(operation.id)

        await self._set_status(
            operation.id, GitOperationStatus.COMPLETED, pushed_branch=pushed_branch
        )
        await self._event_service.append_event(
            task_id,
            "git.completed",
            {"message": "Changes committed and pushed successfully."},
        )
        return await self._reload(operation.id)

    async def discard(self, user_id: UUID, task_id: UUID, git_operation_id: UUID) -> GitOperation:
        operation = await self._load_pending(user_id, task_id, git_operation_id)
        await self._set_status(operation.id, GitOperationStatus.REJECTED)
        await self._event_service.append_event(
            task_id, "git.discarded", {"message": "Commit & push discarded by user"}
        )
        return await self._reload(operation.id)

    async def _load_pending(
        self, user_id: UUID, task_id: UUID, git_operation_id: UUID
    ) -> GitOperation:
        async with self._session_factory() as session:
            operation = await session.scalar(
                select(GitOperation)
                .join(Task, Task.id == GitOperation.task_id)
                .where(
                    GitOperation.id == git_operation_id,
                    GitOperation.task_id == task_id,
                    Task.user_id == user_id,
                )
            )
            if operation is None:
                raise NotFoundError("Git operation not found")
            if operation.status != GitOperationStatus.PENDING_REVIEW:
                raise ConflictError("Git operation already resolved")
            return operation

    async def _reload(self, git_operation_id: UUID) -> GitOperation:
        async with self._session_factory() as session:
            operation = await session.get(GitOperation, git_operation_id)
            if operation is None:
                raise NotFoundError("Git operation not found")
            return operation

    async def _set_status(
        self,
        git_operation_id: UUID,
        status: GitOperationStatus,
        error_message: str | None = None,
        commit_message: str | None = None,
        pushed_branch: str | None = None,
    ) -> None:
        async with self._session_factory() as session:
            operation = await session.get(GitOperation, git_operation_id)
            if operation is None:
                return
            operation.status = status
            if error_message is not None:
                operation.error_message = error_message
            if commit_message is not None:
                operation.commit_message = commit_message
            if pushed_branch is not None:
                operation.pushed_branch = pushed_branch
            await session.commit()

    async def _run_git_capture(self, cwd: str, args: list[str]) -> str:
        managed = await ManagedSubprocess.spawn(["git", *args], cwd=cwd, use_stdin=False)
        lines: list[str] = []

        async def _collect(line: str, source: str) -> None:
            if source == "stdout":
                lines.append(line)

        managed.start_streaming(_collect)
        await managed.wait(timeout_seconds=30)
        return "\n".join(lines).strip()

    async def _run_git_streamed(self, task_id: UUID, cwd: str, args: list[str]) -> None:
        managed = await ManagedSubprocess.spawn(["git", *args], cwd=cwd, use_stdin=False)
        stderr_tail: list[str] = []

        async def _on_line(line: str, source: str) -> None:
            if source == "stderr":
                stderr_tail.append(line)
            await self._event_service.append_event(
                task_id, "git.log", {"message": line, "command": " ".join(args), "source": source}
            )

        managed.start_streaming(_on_line)
        exit_code, timed_out = await managed.wait(timeout_seconds=120)
        if timed_out:
            raise GitCommandError(f"git {' '.join(args)} timed out")
        if exit_code != 0:
            detail = "\n".join(stderr_tail[-10:]) or f"exit code {exit_code}"
            raise GitCommandError(f"git {' '.join(args)} failed: {detail}")


class GitCommandError(Exception):
    pass
