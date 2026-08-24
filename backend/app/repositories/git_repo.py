from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.git_operation import GitOperation
from app.models.task import Task

from .base import BaseRepository


class GitOperationRepository(BaseRepository):
    async def create(self, session: AsyncSession, operation: GitOperation) -> GitOperation:
        session.add(operation)
        await session.commit()
        await session.refresh(operation)
        return operation

    async def get_by_id(self, session: AsyncSession, git_operation_id: UUID) -> GitOperation | None:
        return await session.get(GitOperation, git_operation_id)

    async def get_pending(
        self, session: AsyncSession, git_operation_id: UUID, task_id: UUID, user_id: UUID
    ) -> GitOperation | None:
        result = await session.execute(
            select(GitOperation)
            .join(Task, Task.id == GitOperation.task_id)
            .where(
                GitOperation.id == git_operation_id,
                GitOperation.task_id == task_id,
                Task.user_id == user_id,
            )
        )
        return result.scalars().first()

    async def update_status(
        self,
        session: AsyncSession,
        git_operation_id: UUID,
        status,
        error_message: str | None = None,
        commit_message: str | None = None,
        pushed_branch: str | None = None,
    ) -> bool:
        operation = await session.get(GitOperation, git_operation_id)
        if operation is None:
            return False
        operation.status = status
        if error_message is not None:
            operation.error_message = error_message
        if commit_message is not None:
            operation.commit_message = commit_message
        if pushed_branch is not None:
            operation.pushed_branch = pushed_branch
        await session.commit()
        return True
