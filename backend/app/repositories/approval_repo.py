from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.approval_request import ApprovalRequest
from app.models.task import Task

from .base import BaseRepository


class ApprovalRepository(BaseRepository):
    async def create(self, session: AsyncSession, approval: ApprovalRequest) -> ApprovalRequest:
        session.add(approval)
        return approval

    async def list_pending(self, session: AsyncSession, user_id: UUID) -> list[ApprovalRequest]:
        from app.models.enums import ApprovalStatus
        result = await session.execute(
            select(ApprovalRequest)
            .join(Task, Task.id == ApprovalRequest.task_id)
            .where(
                Task.user_id == user_id,
                ApprovalRequest.status == ApprovalStatus.PENDING,
            )
            .order_by(ApprovalRequest.created_at.asc())
        )
        return list(result.scalars().all())

    async def list_for_task(self, session: AsyncSession, user_id: UUID, task_id: UUID) -> list[ApprovalRequest]:
        result = await session.execute(
            select(ApprovalRequest)
            .join(Task, Task.id == ApprovalRequest.task_id)
            .where(Task.user_id == user_id, Task.id == task_id)
            .order_by(ApprovalRequest.created_at.asc())
        )
        return list(result.scalars().all())

    async def get_with_task(self, session: AsyncSession, approval_id: UUID, user_id: UUID) -> ApprovalRequest | None:
        return await session.scalar(
            select(ApprovalRequest)
            .join(Task, Task.id == ApprovalRequest.task_id)
            .where(ApprovalRequest.id == approval_id, Task.user_id == user_id)
            .with_for_update()
        )

    async def update_status(
        self, session: AsyncSession, approval: ApprovalRequest, status, resolved_at=None, note: str | None = None
    ) -> ApprovalRequest:
        from app.models.enums import ApprovalStatus

        approval.status = status
        if resolved_at is not None:
            approval.resolved_at = resolved_at
        if note is not None:
            approval.payload_json = {**approval.payload_json, "resolution_note": note}
        await session.commit()
        await session.refresh(approval)
        return approval
