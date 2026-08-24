from __future__ import annotations

from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.task import Task
from app.models.task_message import TaskMessage

from .base import BaseRepository


class TaskRepository(BaseRepository):
    async def create(self, session: AsyncSession, task: Task) -> Task:
        session.add(task)
        return task

    async def get_by_id(self, session: AsyncSession, task_id: UUID) -> Task | None:
        return await session.get(Task, task_id)

    async def get_by_id_and_user(self, session: AsyncSession, task_id: UUID, user_id: UUID) -> Task | None:
        return await session.scalar(select(Task).where(Task.id == task_id, Task.user_id == user_id))

    async def list_by_user(self, session: AsyncSession, user_id: UUID) -> list[Task]:
        result = await session.execute(
            select(Task).where(Task.user_id == user_id).order_by(Task.created_at.desc())
        )
        return list(result.scalars().all())

    async def count_concurrent(
        self, session: AsyncSession, user_id: UUID, statuses: list
    ) -> int:
        count = await session.scalar(
            select(func.count(Task.id)).where(
                Task.user_id == user_id,
                Task.status.in_(statuses),
            )
        )
        return int(count or 0)

    async def get_status(self, session: AsyncSession, task_id: UUID) -> Task | None:
        return await session.get(Task, task_id)

    async def get_user_id(self, session: AsyncSession, task_id: UUID) -> UUID | None:
        task = await session.get(Task, task_id)
        return task.user_id if task else None

    async def update_status(
        self,
        session: AsyncSession,
        task_id: UUID,
        status,
        current_phase: str | None = None,
        error_message: str | None = None,
        final_summary: str | None = None,
        started_at=None,
        finished_at=None,
        cancelled_at=None,
    ) -> Task | None:
        task = await session.scalar(select(Task).where(Task.id == task_id).with_for_update())
        if task is None:
            return None
        task.status = status
        if current_phase is not None:
            task.current_phase = current_phase
        if error_message is not None:
            task.error_message = error_message
        if final_summary is not None:
            task.final_summary = final_summary
        if started_at is not None:
            task.started_at = started_at
        if finished_at is not None:
            task.finished_at = finished_at
        if cancelled_at is not None:
            task.cancelled_at = cancelled_at
        await session.commit()
        await session.refresh(task)
        return task

    async def list_messages(self, session: AsyncSession, task_id: UUID) -> list[TaskMessage]:
        result = await session.execute(
            select(TaskMessage)
            .where(TaskMessage.task_id == task_id)
            .order_by(TaskMessage.created_at.asc())
        )
        return list(result.scalars().all())
