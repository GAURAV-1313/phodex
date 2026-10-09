from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.core.metrics import TASK_DURATION, TASK_TRANSITIONS
from app.models.approval_request import ApprovalRequest
from app.models.enums import ApprovalStatus, TaskMessageRole, TaskStatus
from app.models.project_context import ProjectContext
from app.models.task import Task
from app.models.task_message import TaskMessage
from app.repositories.task_repo import TaskRepository
from app.schemas.tasks import TaskEventEnvelope, TaskIssueOut
from app.services.event_service import EventService
from app.services.exceptions import ConflictError, LimitExceededError, NotFoundError
from app.services.push_service import PushService
from app.services.redis_service import RedisService
from app.utils.datetime import utcnow

if TYPE_CHECKING:
    from app.services.worker_dispatcher import WorkerDispatcher

ACTIVE_STATUSES = (
    TaskStatus.QUEUED,
    TaskStatus.STARTING,
    TaskStatus.RUNNING,
    TaskStatus.WAITING_APPROVAL,
)
RESUMABLE_STATUSES = frozenset({TaskStatus.FAILED, TaskStatus.CANCELLED})


class TaskService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        event_service: EventService,
        settings: Settings,
        redis: RedisService,
        push_service: PushService,
        task_repo: TaskRepository,
    ) -> None:
        self._session_factory = session_factory
        self._event_service = event_service
        self._settings = settings
        self._redis = redis
        self._push_service = push_service
        self._task_repo = task_repo
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
                running_count = await self._task_repo.count_concurrent(
                    session, user_id,
                    [TaskStatus.QUEUED.value, TaskStatus.STARTING.value, TaskStatus.RUNNING.value, TaskStatus.WAITING_APPROVAL.value],
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
            return await self._task_repo.list_by_user(session, user_id)

    async def get_task(self, user_id: UUID, task_id: UUID) -> Task:
        async with self._session_factory() as session:
            task = await self._task_repo.get_by_id_and_user(session, task_id, user_id)
            if task is None:
                raise NotFoundError("Task not found")
            return task

    async def get_task_detail(
        self, user_id: UUID, task_id: UUID
    ) -> tuple[Task, list[TaskMessage], list[TaskEventEnvelope], list[ApprovalRequest]]:
        async with self._session_factory() as session:
            task = await self._task_repo.get_by_id_and_user(session, task_id, user_id)
            if task is None:
                raise NotFoundError("Task not found")

            messages = await self._task_repo.list_messages(session, task_id)

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
            task = await self._task_repo.get_by_id_and_user(session, task_id, user_id)
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
            task = await self._task_repo.get_by_id_and_user(session, task_id, user_id)
            if task is None:
                raise NotFoundError("Task not found")
            if task.status == TaskStatus.CANCELLED:
                return task
            if task.status in {TaskStatus.COMPLETED, TaskStatus.FAILED}:
                raise ConflictError("Cannot cancel a finished task")

            now = utcnow()
            cancelled = await self._task_repo.update_status(
                session, task_id, TaskStatus.CANCELLED,
                current_phase="cancelled", cancelled_at=now, finished_at=now,
            )
            if cancelled is None:
                raise NotFoundError("Task not found")
            task = cancelled

        await self._event_service.append_event(
            task_id, "task.cancelled", {"message": "Task cancelled by user"}
        )
        await self._invalidate_usage(task.user_id)
        TASK_TRANSITIONS.labels(status=TaskStatus.CANCELLED.value).inc()
        if self._worker_dispatcher is not None:
            await self._worker_dispatcher.cancel_task(task_id)
        return task

    async def resume_task(self, user_id: UUID, task_id: UUID) -> Task:
        """Re-queues a stopped task so the worker continues where it left off.

        Only tasks that stopped without finishing (failed, cancelled, or
        interrupted by a backend restart) can be resumed. The agent's edits
        are still in the working tree, and if the runtime reported a session
        id, the worker reattaches to that same agent conversation.
        """
        async with self._session_factory() as session:
            task = await self._task_repo.get_by_id_and_user(session, task_id, user_id)
            if task is None:
                raise NotFoundError("Task not found")
            if task.status not in RESUMABLE_STATUSES:
                raise ConflictError(
                    "Only failed, cancelled or interrupted tasks can be resumed"
                )

            max_concurrent = self._settings.max_concurrent_tasks_per_user
            if max_concurrent > 0:
                running_count = await self._task_repo.count_concurrent(
                    session, user_id, [s.value for s in ACTIVE_STATUSES]
                )
                if int(running_count or 0) >= max_concurrent:
                    raise LimitExceededError(
                        "Concurrent task limit reached",
                        code="CONCURRENT_TASK_LIMIT_REACHED",
                    )

            locked = await session.scalar(
                select(Task).where(Task.id == task_id).with_for_update()
            )
            assert locked is not None
            locked.status = TaskStatus.QUEUED
            locked.current_phase = "resume_queued"
            locked.error_message = None
            locked.finished_at = None
            locked.cancelled_at = None
            locked.resume_count = (locked.resume_count or 0) + 1
            await session.commit()
            await session.refresh(locked)
            task = locked

        await self._event_service.append_event(
            task_id,
            "task.resumed",
            {
                "message": "Task resumed from phone",
                "resume_count": task.resume_count,
                "continues_agent_session": task.runtime_session_id is not None,
            },
        )
        TASK_TRANSITIONS.labels(status=TaskStatus.QUEUED.value).inc()
        await self._invalidate_usage(task.user_id)

        if self._worker_dispatcher is not None:
            await self._worker_dispatcher.dispatch_task(task_id)
        return task

    async def recover_interrupted_tasks(self) -> int:
        """Marks tasks left active by a previous process as interrupted.

        Worker state lives in this process's memory, so when the backend dies
        (laptop battery, crash, deploy), any task it was running is orphaned:
        the row still says running but nothing is behind it. On startup we
        fail those tasks with a retryable WORKER_INTERRUPTED error so the
        phone shows them as stopped and offers Resume.
        """
        async with self._session_factory() as session:
            orphaned = list(
                (
                    await session.execute(
                        select(Task).where(
                            Task.status.in_([s.value for s in ACTIVE_STATUSES])
                        )
                    )
                )
                .scalars()
                .all()
            )
            now = utcnow()
            for task in orphaned:
                task.status = TaskStatus.FAILED
                task.current_phase = "interrupted"
                task.error_message = "Phodex stopped while this task was running"
                task.finished_at = now
            pending = list(
                (
                    await session.execute(
                        select(ApprovalRequest).where(
                            ApprovalRequest.task_id.in_([t.id for t in orphaned]),
                            ApprovalRequest.status == ApprovalStatus.PENDING,
                        )
                    )
                )
                .scalars()
                .all()
            ) if orphaned else []
            for approval in pending:
                approval.status = ApprovalStatus.EXPIRED
            await session.commit()
            recovered = [(t.id, t.user_id) for t in orphaned]

        for task_id, user_id in recovered:
            await self._event_service.append_event(
                task_id,
                "task.failed",
                {
                    "message": "Phodex stopped while this task was running. Tap Resume to continue.",
                    "error_code": "WORKER_INTERRUPTED",
                    "is_retryable": True,
                    "is_resumable": True,
                },
            )
            TASK_TRANSITIONS.labels(status=TaskStatus.FAILED.value).inc()
            await self._invalidate_usage(user_id)
        return len(recovered)

    async def set_runtime_session_id(self, task_id: UUID, session_id: str) -> None:
        async with self._session_factory() as session:
            task = await self._task_repo.get_by_id(session, task_id)
            if task is None or task.runtime_session_id == session_id:
                return
            task.runtime_session_id = session_id
            await session.commit()

    async def list_messages(self, user_id: UUID, task_id: UUID) -> list[TaskMessage]:
        await self.get_task(user_id, task_id)
        async with self._session_factory() as session:
            return await self._task_repo.list_messages(session, task_id)

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
            task = await self._task_repo.get_by_id(session, task_id)
            if task is None:
                raise NotFoundError("Task not found")

            now = utcnow()
            updated = await self._task_repo.update_status(
                session, task_id, status,
                current_phase=current_phase,
                error_message=error_message,
                final_summary=final_summary,
                started_at=now if status in {TaskStatus.STARTING, TaskStatus.RUNNING} and task.started_at is None else task.started_at,
                finished_at=now if status in {TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.CANCELLED} else task.finished_at,
                cancelled_at=now if status == TaskStatus.CANCELLED and task.cancelled_at is None else task.cancelled_at,
            )
            if updated is None:
                raise NotFoundError("Task not found")
            task = updated
            user_id = task.user_id
            started_at = task.started_at
            finished_at = task.finished_at
            task_title = task.title or task.prompt

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

        if status == TaskStatus.COMPLETED:
            await self._push_service.notify_user(
                user_id,
                title="Task completed",
                body=task_title,
                data={"task_id": str(task_id), "type": "task.completed"},
            )
        elif status == TaskStatus.FAILED:
            await self._push_service.notify_user(
                user_id,
                title="Task failed",
                body=error_message or task_title,
                data={"task_id": str(task_id), "type": "task.failed"},
            )

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
            task = await self._task_repo.get_by_id(session, task_id)
            if task is None:
                raise NotFoundError("Task not found")
            return task.status

    async def get_user_id(self, task_id: UUID) -> UUID:
        async with self._session_factory() as session:
            task = await self._task_repo.get_by_id(session, task_id)
            if task is None:
                raise NotFoundError("Task not found")
            return task.user_id

    async def _invalidate_usage(self, user_id: UUID) -> None:
        await self._redis.delete(f"account:usage:{user_id}")
