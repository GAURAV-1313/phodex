from abc import ABC, abstractmethod
from uuid import UUID


class WorkerEngine(ABC):
    @abstractmethod
    async def dispatch_task(self, task_id: UUID) -> None:
        pass

    @abstractmethod
    async def handle_approval(self, task_id: UUID, approval_id: UUID, approved: bool) -> None:
        pass

    @abstractmethod
    async def handle_user_reply(self, task_id: UUID, content: str) -> None:
        pass

    @abstractmethod
    async def cancel_task(self, task_id: UUID) -> None:
        pass
