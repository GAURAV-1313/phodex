from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.approval_request import ApprovalRequest
from app.models.enums import ApprovalStatus, TaskStatus
from app.models.task import Task
from app.services.event_service import EventService
from app.services.exceptions import ConflictError, NotFoundError
from app.services.redis_service import RedisService
from app.utils.datetime import utcnow

if TYPE_CHECKING:
    from app.services.worker_dispatcher import WorkerDispatcher


class ApprovalService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        event_service: EventService,
        redis: RedisService,
    ) -> None:
        self._session_factory = session_factory
        self._event_service = event_service
        self._redis = redis
        self._worker_dispatcher: WorkerDispatcher | None = None

    def set_worker_dispatcher(self, dispatcher: "WorkerDispatcher") -> None:
        self._worker_dispatcher = dispatcher

    async def create_approval_request(
        self,
        task_id: UUID,
        kind: str,
        title: str,
        description: str,
        payload_json: dict,
    ) -> ApprovalRequest:
        async with self._session_factory() as session:
            approval = ApprovalRequest(
                task_id=task_id,
                kind=kind,
                title=title,
                description=description,
                payload_json=payload_json,
                status=ApprovalStatus.PENDING,
            )
            session.add(approval)
            await session.commit()
            await session.refresh(approval)

        await self._event_service.append_event(
            task_id,
            "approval.requested",
            {
                "approval_id": str(approval.id),
                "kind": kind,
                "title": title,
                "description": description,
            },
        )

        return approval

    async def list_pending(self, user_id: UUID) -> list[ApprovalRequest]:
        async with self._session_factory() as session:
            approvals = (
                (
                    await session.execute(
                        select(ApprovalRequest)
                        .join(Task, Task.id == ApprovalRequest.task_id)
                        .where(
                            Task.user_id == user_id,
                            ApprovalRequest.status == ApprovalStatus.PENDING,
                        )
                        .order_by(ApprovalRequest.created_at.asc())
                    )
                )
                .scalars()
                .all()
            )
            return list(approvals)

    async def list_for_task(self, user_id: UUID, task_id: UUID) -> list[ApprovalRequest]:
        async with self._session_factory() as session:
            approvals = (
                (
                    await session.execute(
                        select(ApprovalRequest)
                        .join(Task, Task.id == ApprovalRequest.task_id)
                        .where(Task.user_id == user_id, Task.id == task_id)
                        .order_by(ApprovalRequest.created_at.asc())
                    )
                )
                .scalars()
                .all()
            )
            return list(approvals)

    async def approve(
        self, user_id: UUID, approval_id: UUID, note: str | None = None
    ) -> ApprovalRequest:
        approval = await self._resolve(user_id, approval_id, ApprovalStatus.APPROVED, note)
        await self._event_service.append_event(
            approval.task_id,
            "approval.approved",
            {
                "approval_id": str(approval.id),
                "note": note,
            },
        )
        if self._worker_dispatcher is not None:
            await self._worker_dispatcher.handle_approval(
                approval.task_id, approval.id, approved=True
            )
        await self._invalidate_usage_for_task(approval.task_id)
        return approval

    async def reject(
        self, user_id: UUID, approval_id: UUID, note: str | None = None
    ) -> ApprovalRequest:
        approval = await self._resolve(user_id, approval_id, ApprovalStatus.REJECTED, note)
        await self._event_service.append_event(
            approval.task_id,
            "approval.rejected",
            {
                "approval_id": str(approval.id),
                "note": note,
                "message": "Approval rejected by user",
                "error_code": "APPROVAL_REJECTED",
                "is_retryable": False,
            },
        )
        await self._event_service.append_event(
            approval.task_id,
            "task.failed",
            {
                "message": "Task failed because approval was rejected",
                "error_code": "APPROVAL_REJECTED",
                "is_retryable": False,
            },
        )
        if self._worker_dispatcher is not None:
            await self._worker_dispatcher.handle_approval(
                approval.task_id, approval.id, approved=False
            )
        await self._invalidate_usage_for_task(approval.task_id)
        return approval

    async def _invalidate_usage_for_task(self, task_id: UUID) -> None:
        async with self._session_factory() as session:
            task = await session.get(Task, task_id)
            if task is not None:
                await self._redis.delete(f"account:usage:{task.user_id}")

    async def _resolve(
        self,
        user_id: UUID,
        approval_id: UUID,
        status: ApprovalStatus,
        note: str | None,
    ) -> ApprovalRequest:
        async with self._session_factory() as session:
            approval = await session.scalar(
                select(ApprovalRequest)
                .join(Task, Task.id == ApprovalRequest.task_id)
                .where(ApprovalRequest.id == approval_id, Task.user_id == user_id)
                .with_for_update()
            )
            if approval is None:
                raise NotFoundError("Approval request not found")
            if approval.status != ApprovalStatus.PENDING:
                raise ConflictError("Approval request already resolved")

            task = await session.get(Task, approval.task_id, with_for_update=True)
            if task is None:
                raise NotFoundError("Task not found")
            if task.status != TaskStatus.WAITING_APPROVAL:
                raise ConflictError("Task is not waiting for approval")

            approval.status = status
            approval.resolved_at = utcnow()
            if note:
                approval.payload_json = {**approval.payload_json, "resolution_note": note}

            if status == ApprovalStatus.REJECTED:
                task.status = TaskStatus.FAILED
                task.error_message = "Approval rejected"
                task.finished_at = utcnow()
                task.current_phase = "approval_rejected"

            await session.commit()
            await session.refresh(approval)
            return approval
