import asyncio
from collections import defaultdict
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.task import Task
from app.models.task_event import TaskEvent
from app.repositories.event_repo import EventRepository
from app.schemas.tasks import TaskEventEnvelope
from app.services.redis_service import RedisService


class EventBus:
    def __init__(self, redis: RedisService) -> None:
        self._redis = redis
        self._subscribers: dict[UUID, set[asyncio.Queue[TaskEventEnvelope]]] = defaultdict(set)
        self._lock = asyncio.Lock()
        self._listener: asyncio.Task[None] | None = None

    async def start(self) -> None:
        if self._redis.enabled:
            self._listener = asyncio.create_task(self._redis.listen(self._deliver_serialized))

    async def close(self) -> None:
        if self._listener is not None:
            self._listener.cancel()
            try:
                await self._listener
            except asyncio.CancelledError:
                pass
            self._listener = None

    async def subscribe(self, task_id: UUID) -> asyncio.Queue[TaskEventEnvelope]:
        queue: asyncio.Queue[TaskEventEnvelope] = asyncio.Queue()
        async with self._lock:
            self._subscribers[task_id].add(queue)
        return queue

    async def unsubscribe(self, task_id: UUID, queue: asyncio.Queue[TaskEventEnvelope]) -> None:
        async with self._lock:
            if task_id in self._subscribers:
                self._subscribers[task_id].discard(queue)
                if not self._subscribers[task_id]:
                    self._subscribers.pop(task_id, None)

    async def publish(self, envelope: TaskEventEnvelope) -> None:
        if self._redis.enabled:
            # Every app instance receives this message through its one Redis listener.
            if await self._redis.publish(envelope.model_dump_json()):
                return
        await self._deliver(envelope)

    async def _deliver_serialized(self, payload: str) -> None:
        await self._deliver(TaskEventEnvelope.model_validate_json(payload))

    async def _deliver(self, envelope: TaskEventEnvelope) -> None:
        async with self._lock:
            subscribers = list(self._subscribers.get(envelope.task_id, set()))

        for queue in subscribers:
            queue.put_nowait(envelope)


class EventService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        event_bus: EventBus,
        event_repo: EventRepository,
    ) -> None:
        self._session_factory = session_factory
        self._event_bus = event_bus
        self._event_repo = event_repo
        self._append_locks: dict[UUID, asyncio.Lock] = defaultdict(asyncio.Lock)

    async def start(self) -> None:
        await self._event_bus.start()

    async def close(self) -> None:
        await self._event_bus.close()

    async def append_event(
        self,
        task_id: UUID,
        event_type: str,
        payload_json: dict,
    ) -> TaskEventEnvelope:
        async with self._append_locks[task_id]:
            async with self._session_factory() as session:
                await self._event_repo.lock_task(session, task_id)
                max_seq = await self._event_repo.get_max_seq(session, task_id)
                next_seq = int(max_seq or 0) + 1
                event = TaskEvent(
                    task_id=task_id,
                    seq_no=next_seq,
                    event_type=event_type,
                    payload_json=payload_json,
                )
                event = await self._event_repo.append(session, event)

        envelope = self._to_envelope(event)
        await self._event_bus.publish(envelope)
        return envelope

    async def list_envelopes(
        self,
        task_id: UUID,
        after_sequence: int = 0,
    ) -> list[TaskEventEnvelope]:
        async with self._session_factory() as session:
            events = await self._event_repo.list_by_task(session, task_id, after_sequence)
            return [self._to_envelope(event) for event in events]

    async def subscribe(self, task_id: UUID) -> asyncio.Queue[TaskEventEnvelope]:
        return await self._event_bus.subscribe(task_id)

    async def unsubscribe(self, task_id: UUID, queue: asyncio.Queue[TaskEventEnvelope]) -> None:
        await self._event_bus.unsubscribe(task_id, queue)

    @staticmethod
    def _to_envelope(event: TaskEvent) -> TaskEventEnvelope:
        return TaskEventEnvelope(
            event_id=event.id,
            task_id=event.task_id,
            sequence=event.seq_no,
            type=event.event_type,
            timestamp=event.created_at,
            data=event.payload_json,
        )
