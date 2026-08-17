from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.core.metrics import TASK_DURATION, TASK_TRANSITIONS
from app.models.approval_request import ApprovalRequest
from app.models.enums import TaskMessageRole, TaskStatus
from app.models.project_context import ProjectContext
from app.models.task import Task
from app.models.task_message import TaskMessage
from app.schemas.tasks import TaskEventEnvelope, TaskIssueOut
from app.services.event_service import EventService
from app.services.exceptions import ConflictError, LimitExceededError, NotFoundError
from app.services.redis_service import RedisService
from app.utils.datetime import utcnow

if TYPE_CHECKING:
    from app.services.worker_dispatcher import WorkerDispatcher


class TaskService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        event_service: EventService,
        settings: Settings,
        redis: RedisService,
    ) -> None:
        self._session_factory = session_factory
        self._event_service = event_service
        self._settings = settings
        self._redis = redis
        self._worker_dispatcher: WorkerDispatcher | None = None

    def set_worker_dispatcher(self, dispatcher: "WorkerDispatcher") -> None:
        self._worker_dispatcher = dispatcher

    async def create_task(
        self,
        user_id: UUID,
        prompt: str,
        project_context_id: UUID | None,
        title: str | None = None,
    ) -> Task:
        async with self._session_factory() as session:
            max_concurrent = self._settings.max_concurrent_tasks_per_user
            if max_concurrent > 0:
                running_count = await session.scalar(
                    select(func.count(Task.id)).where(
                        Task.user_id == user_id,
                        Task.status.in_(
                            [
                                TaskStatus.QUEUED,
                                TaskStatus.STARTING,
                                TaskStatus.RUNNING,
                                TaskStatus.WAITING_APPROVAL,
                            ]
                        ),
                    )
                )
                if int(running_count or 0) >= max_concurrent:
                    raise LimitExceededError(
                        "Concurrent task limit reached",
                        code="CONCURRENT_TASK_LIMIT_REACHED",
                    )

            if project_context_id is not None:
                context = await session.scalar(
                    select(ProjectContext).where(
                        ProjectContext.id == project_context_id,
                        ProjectContext.user_id == user_id,
                    )
                )
                if context is None:
                    raise NotFoundError("Project context not found")

            task = Task(
                user_id=user_id,
                project_context_id=project_context_id,
                title=title,
                prompt=prompt,
                status=TaskStatus.QUEUED,
                current_phase="queued",
            )
            session.add(task)
            session.add(
                TaskMessage(
                    task=task,
                    role=TaskMessageRole.USER,
                    content=prompt,
                )
            )
            await session.commit()
            await session.refresh(task)

        await self._event_service.append_event(
            task.id,
            "task.created",
            {"message": "Task created and queued"},
        )
        TASK_TRANSITIONS.labels(status=TaskStatus.QUEUED.value).inc()
        await self._invalidate_usage(task.user_id)

        if self._worker_dispatcher is not None:
            await self._worker_dispatcher.dispatch_task(task.id)

        return task

    async def list_tasks(self, user_id: UUID) -> list[Task]:
        async with self._session_factory() as session:
            tasks = (
                (
                    await session.execute(
                        select(Task).where(Task.user_id == user_id).order_by(Task.created_at.desc())
                    )
                )
                .scalars()
                .all()
            )
            return list(tasks)

    async def get_task(self, user_id: UUID, task_id: UUID) -> Task:
        async with self._session_factory() as session:
            task = await session.scalar(
                select(Task).where(Task.id == task_id, Task.user_id == user_id)
            )
            if task is None:
                raise NotFoundError("Task not found")
            return task

    async def get_task_detail(
        self, user_id: UUID, task_id: UUID
    ) -> tuple[Task, list[TaskMessage], list[TaskEventEnvelope], list[ApprovalRequest]]:
        async with self._session_factory() as session:
            task = await session.scalar(
                select(Task).where(Task.id == task_id, Task.user_id == user_id)
            )
            if task is None:
                raise NotFoundError("Task not found")

            messages = (
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

            approvals = (
                (
                    await session.execute(
                        select(ApprovalRequest)
                        .where(ApprovalRequest.task_id == task_id)
                        .order_by(ApprovalRequest.created_at.asc())
                    )
                )
                .scalars()
                .all()
            )

        events = await self._event_service.list_envelopes(task_id)
        return task, list(messages), events, list(approvals)

    async def add_reply(self, user_id: UUID, task_id: UUID, content: str) -> TaskMessage:
        async with self._session_factory() as session:
            task = await session.scalar(
                select(Task).where(Task.id == task_id, Task.user_id == user_id)
            )
            if task is None:
                raise NotFoundError("Task not found")
            if task.status in {TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.CANCELLED}:
                raise ConflictError("Cannot reply to a finished task")

            message = TaskMessage(
                task_id=task.id,
                role=TaskMessageRole.USER,
                content=content,
            )
            session.add(message)
            task.updated_at = utcnow()
            await session.commit()
            await session.refresh(message)

        await self._event_service.append_event(
            task_id,
            "task.progress",
            {"message": "User follow-up received"},
        )

        if self._worker_dispatcher is not None:
            await self._worker_dispatcher.handle_user_reply(task_id, content)

        return message

    async def cancel_task(self, user_id: UUID, task_id: UUID) -> Task:
        async with self._session_factory() as session:
            task = await session.scalar(
                select(Task).where(Task.id == task_id, Task.user_id == user_id).with_for_update()
            )
            if task is None:
                raise NotFoundError("Task not found")
            if task.status == TaskStatus.CANCELLED:
                return task
            if task.status in {TaskStatus.COMPLETED, TaskStatus.FAILED}:
                raise ConflictError("Cannot cancel a finished task")

            now = utcnow()
            task.status = TaskStatus.CANCELLED
            task.current_phase = "cancelled"
            task.cancelled_at = now
            task.finished_at = now
            await session.commit()
            await session.refresh(task)

        await self._event_service.append_event(
            task_id, "task.cancelled", {"message": "Task cancelled by user"}
        )
        await self._invalidate_usage(task.user_id)
        TASK_TRANSITIONS.labels(status=TaskStatus.CANCELLED.value).inc()
        if self._worker_dispatcher is not None:
            await self._worker_dispatcher.cancel_task(task_id)
        return task

    async def list_messages(self, user_id: UUID, task_id: UUID) -> list[TaskMessage]:
        await self.get_task(user_id, task_id)
        async with self._session_factory() as session:
            messages = (
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
            return list(messages)

    async def list_events(self, user_id: UUID, task_id: UUID) -> list[TaskEventEnvelope]:
        await self.get_task(user_id, task_id)
        return await self._event_service.list_envelopes(task_id)

    async def list_issues(self, user_id: UUID, task_id: UUID) -> list[TaskIssueOut]:
        await self.get_task(user_id, task_id)
        events = await self._event_service.list_envelopes(task_id)

        issue_events = []
        for event in events:
            data = event.data
            has_error_code = bool(data.get("error_code"))
            is_error_type = event.type in {
                "task.failed",
                "approval.rejected",
            } or event.type.startswith("error.")
            if has_error_code or is_error_type:
                issue_events.append(
                    TaskIssueOut(
                        sequence=event.sequence,
                        type=event.type,
                        timestamp=event.timestamp,
                        code=data.get("error_code"),
                        message=str(data.get("message", event.type)),
                        data=data,
                    )
                )

        return issue_events

    async def transition_for_worker(
        self,
        task_id: UUID,
        status: TaskStatus,
        current_phase: str | None = None,
        error_message: str | None = None,
        final_summary: str | None = None,
    ) -> Task:
        async with self._session_factory() as session:
            task = await session.scalar(select(Task).where(Task.id == task_id).with_for_update())
            if task is None:
                raise NotFoundError("Task not found")

            now = utcnow()
            task.status = status
            task.current_phase = current_phase
            task.error_message = error_message
            task.final_summary = final_summary

            if status in {TaskStatus.STARTING, TaskStatus.RUNNING} and task.started_at is None:
                task.started_at = now
            if status in {TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.CANCELLED}:
                task.finished_at = now
            if status == TaskStatus.CANCELLED and task.cancelled_at is None:
                task.cancelled_at = now

            await session.commit()
            await session.refresh(task)
            user_id = task.user_id
            started_at = task.started_at
            finished_at = task.finished_at

        TASK_TRANSITIONS.labels(status=status.value).inc()
        if (
            status in {TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.CANCELLED}
            and started_at
            and finished_at
        ):
            TASK_DURATION.labels(outcome=status.value).observe(
                max((finished_at - started_at).total_seconds(), 0)
            )
        await self._invalidate_usage(user_id)
        return task

    async def append_assistant_message(self, task_id: UUID, content: str) -> TaskMessage:
        async with self._session_factory() as session:
            message = TaskMessage(task_id=task_id, role=TaskMessageRole.ASSISTANT, content=content)
            session.add(message)
            await session.commit()
            await session.refresh(message)
            return message

    async def get_status(self, task_id: UUID) -> TaskStatus:
        async with self._session_factory() as session:
            task = await session.get(Task, task_id)
            if task is None:
                raise NotFoundError("Task not found")
            return task.status

    async def get_user_id(self, task_id: UUID) -> UUID:
        async with self._session_factory() as session:
            task = await session.get(Task, task_id)
            if task is None:
                raise NotFoundError("Task not found")
            return task.user_id

    async def _invalidate_usage(self, user_id: UUID) -> None:
        await self._redis.delete(f"account:usage:{user_id}")
