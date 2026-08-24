from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.approval_request import ApprovalRequest
from app.models.enums import ApprovalStatus, TaskStatus
from app.models.task import Task
from app.services.event_service import EventService
from app.services.exceptions import ConflictError, NotFoundError
from app.services.push_service import PushService
from app.services.redis_service import RedisService
from app.repositories.approval_repo import ApprovalRepository
from app.utils.datetime import utcnow

if TYPE_CHECKING:
    from app.services.worker_dispatcher import WorkerDispatcher


class ApprovalService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        event_service: EventService,
        redis: RedisService,
        push_service: PushService,
        approval_repo: ApprovalRepository,
    ) -> None:
        self._session_factory = session_factory
        self._event_service = event_service
        self._redis = redis
        self._push_service = push_service
        self._approval_repo = approval_repo
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
            task = await session.get(Task, task_id)
            user_id = task.user_id if task is not None else None

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

        if user_id is not None:
            await self._push_service.notify_user(
                user_id,
                title="Approval needed",
                body=title,
                data={
                    "task_id": str(task_id),
                    "approval_id": str(approval.id),
                    "type": "approval.requested",
                },
            )

        return approval

    async def list_pending(self, user_id: UUID) -> list[ApprovalRequest]:
        async with self._session_factory() as session:
            return await self._approval_repo.list_pending(session, user_id)

    async def list_for_task(self, user_id: UUID, task_id: UUID) -> list[ApprovalRequest]:
        async with self._session_factory() as session:
            return await self._approval_repo.list_for_task(session, user_id, task_id)

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
            approval = await self._approval_repo.get_with_task(session, approval_id, user_id)
            if approval is None:
                raise NotFoundError("Approval request not found")
            if approval.status != ApprovalStatus.PENDING:
                raise ConflictError("Approval request already resolved")

            task = await session.get(Task, approval.task_id, with_for_update=True)
            if task is None:
                raise NotFoundError("Task not found")
            if task.status != TaskStatus.WAITING_APPROVAL:
                raise ConflictError("Task is not waiting for approval")

            approval = await self._approval_repo.update_status(
                session, approval, status, resolved_at=utcnow(), note=note,
            )
            if status == ApprovalStatus.REJECTED:
                task.status = TaskStatus.FAILED
                task.error_message = "Approval rejected"
                task.finished_at = utcnow()
                task.current_phase = "approval_rejected"
                await session.commit()
                await session.refresh(task)

            return approval
