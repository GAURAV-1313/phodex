from uuid import UUID

from workers.base import WorkerEngine


class WorkerDispatcher:
    def __init__(self, worker_engine: WorkerEngine) -> None:
        self._worker_engine = worker_engine

    async def dispatch_task(self, task_id: UUID) -> None:
        await self._worker_engine.dispatch_task(task_id)

    async def handle_approval(self, task_id: UUID, approval_id: UUID, approved: bool) -> None:
        await self._worker_engine.handle_approval(task_id, approval_id, approved)

    async def handle_user_reply(self, task_id: UUID, content: str) -> None:
        await self._worker_engine.handle_user_reply(task_id, content)

    async def cancel_task(self, task_id: UUID) -> None:
        await self._worker_engine.cancel_task(task_id)
