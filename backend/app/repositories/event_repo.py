from __future__ import annotations

from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.task import Task
from app.models.task_event import TaskEvent

from .base import BaseRepository


class EventRepository(BaseRepository):
    async def append(self, session: AsyncSession, event: TaskEvent) -> TaskEvent:
        session.add(event)
        await session.commit()
        await session.refresh(event)
        return event

    async def list_by_task(self, session: AsyncSession, task_id: UUID, after_sequence: int = 0) -> list[TaskEvent]:
        result = await session.execute(
            select(TaskEvent)
            .where(TaskEvent.task_id == task_id, TaskEvent.seq_no > after_sequence)
            .order_by(TaskEvent.seq_no.asc())
        )
        return list(result.scalars().all())

    async def get_max_seq(self, session: AsyncSession, task_id: UUID) -> int:
        max_seq = await session.scalar(
            select(func.coalesce(func.max(TaskEvent.seq_no), 0)).where(
                TaskEvent.task_id == task_id
            )
        )
        return int(max_seq or 0)

    async def lock_task(self, session: AsyncSession, task_id: UUID) -> Task | None:
        return await session.scalar(select(Task.id).where(Task.id == task_id).with_for_update())
