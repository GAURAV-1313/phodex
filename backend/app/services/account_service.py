from dataclasses import asdict, dataclass
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.models.approval_request import ApprovalRequest
from app.models.enums import ApprovalStatus, TaskStatus
from app.models.session import Session
from app.models.task import Task
from app.models.task_event import TaskEvent
from app.services.redis_service import RedisService
from app.utils.datetime import utcnow


@dataclass
class UsageSummary:
    total_tasks: int
    queued_tasks: int
    running_tasks: int
    waiting_approval_tasks: int
    completed_tasks: int
    failed_tasks: int
    cancelled_tasks: int
    pending_approvals: int
    total_events: int
    active_sessions: int


@dataclass
class LimitStatus:
    max_active_sessions: int | None
    active_sessions: int
    remaining_active_sessions: int | None
    max_concurrent_tasks: int | None
    current_concurrent_tasks: int
    remaining_concurrent_tasks: int | None


class AccountService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        settings: Settings,
        redis: RedisService,
    ) -> None:
        self._session_factory = session_factory
        self._settings = settings
        self._redis = redis

    async def active_sessions_count(self, user_id: UUID) -> int:
        async with self._session_factory() as session:
            count = await session.scalar(
                select(func.count(Session.id)).where(
                    Session.user_id == user_id,
                    Session.revoked_at.is_(None),
                    Session.expires_at > utcnow(),
                )
            )
            return int(count or 0)

    async def usage_summary(self, user_id: UUID) -> UsageSummary:
        cache_key = f"account:usage:{user_id}"
        cached = await self._redis.get_json(cache_key)
        if isinstance(cached, dict):
            return UsageSummary(**{key: int(value) for key, value in cached.items()})

        async with self._session_factory() as session:
            total_tasks = await self._count_tasks(session, user_id)
            queued_tasks = await self._count_tasks(session, user_id, TaskStatus.QUEUED)
            running_tasks = await self._count_tasks(session, user_id, TaskStatus.RUNNING)
            waiting_approval_tasks = await self._count_tasks(
                session, user_id, TaskStatus.WAITING_APPROVAL
            )
            completed_tasks = await self._count_tasks(session, user_id, TaskStatus.COMPLETED)
            failed_tasks = await self._count_tasks(session, user_id, TaskStatus.FAILED)
            cancelled_tasks = await self._count_tasks(session, user_id, TaskStatus.CANCELLED)

            pending_approvals = await session.scalar(
                select(func.count(ApprovalRequest.id))
                .join(Task, Task.id == ApprovalRequest.task_id)
                .where(Task.user_id == user_id, ApprovalRequest.status == ApprovalStatus.PENDING)
            )

            total_events = await session.scalar(
                select(func.count(TaskEvent.id))
                .join(Task, Task.id == TaskEvent.task_id)
                .where(Task.user_id == user_id)
            )

            active_sessions = await session.scalar(
                select(func.count(Session.id)).where(
                    Session.user_id == user_id,
                    Session.revoked_at.is_(None),
                    Session.expires_at > utcnow(),
                )
            )

            usage = UsageSummary(
                total_tasks=int(total_tasks or 0),
                queued_tasks=int(queued_tasks or 0),
                running_tasks=int(running_tasks or 0),
                waiting_approval_tasks=int(waiting_approval_tasks or 0),
                completed_tasks=int(completed_tasks or 0),
                failed_tasks=int(failed_tasks or 0),
                cancelled_tasks=int(cancelled_tasks or 0),
                pending_approvals=int(pending_approvals or 0),
                total_events=int(total_events or 0),
                active_sessions=int(active_sessions or 0),
            )
            await self._redis.set_json(cache_key, asdict(usage), self._settings.cache_ttl_seconds)
            return usage

    async def invalidate_usage(self, user_id: UUID) -> None:
        await self._redis.delete(f"account:usage:{user_id}")

    async def limits(self, user_id: UUID) -> LimitStatus:
        usage = await self.usage_summary(user_id)

        max_sessions = self._settings.max_active_sessions_per_user or None
        max_concurrent = self._settings.max_concurrent_tasks_per_user or None

        current_concurrent = usage.queued_tasks + usage.running_tasks + usage.waiting_approval_tasks

        return LimitStatus(
            max_active_sessions=max_sessions,
            active_sessions=usage.active_sessions,
            remaining_active_sessions=(
                None if max_sessions is None else max(max_sessions - usage.active_sessions, 0)
            ),
            max_concurrent_tasks=max_concurrent,
            current_concurrent_tasks=current_concurrent,
            remaining_concurrent_tasks=(
                None if max_concurrent is None else max(max_concurrent - current_concurrent, 0)
            ),
        )

    @staticmethod
    async def _count_tasks(
        session: AsyncSession, user_id: UUID, status: TaskStatus | None = None
    ) -> int:
        query = select(func.count(Task.id)).where(Task.user_id == user_id)
        if status is not None:
            query = query.where(Task.status == status)
        count = await session.scalar(query)
        return int(count or 0)
