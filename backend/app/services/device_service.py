from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.device import Device
from app.schemas.devices import DeviceHeartbeatRequest, DeviceRegisterRequest
from app.services.exceptions import NotFoundError
from app.repositories.device_repo import DeviceRepository
from app.utils.datetime import utcnow


class DeviceService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        device_repo: DeviceRepository,
    ) -> None:
        self._session_factory = session_factory
        self._device_repo = device_repo

    async def register_device(self, user_id: UUID, payload: DeviceRegisterRequest) -> Device:
        async with self._session_factory() as session:
            device: Device | None = None
            if payload.device_id is not None:
                device = await self._device_repo.get_by_id_and_user(session, payload.device_id, user_id)

            if device is None:
                device_kwargs: dict[str, object] = {
                    "user_id": user_id,
                    "name": payload.name,
                    "platform": payload.platform,
                    "status": payload.status,
                    "agent_version": payload.agent_version,
                    "last_seen_at": utcnow(),
                }
                if payload.device_id is not None:
                    device_kwargs["id"] = payload.device_id

                device = Device(**device_kwargs)
                session.add(device)
            else:
                device.name = payload.name
                device.platform = payload.platform
                device.status = payload.status
                device.agent_version = payload.agent_version
                device.last_seen_at = utcnow()

            await session.commit()
            await session.refresh(device)
            return device

    async def heartbeat(self, user_id: UUID, payload: DeviceHeartbeatRequest) -> Device:
        async with self._session_factory() as session:
            device = await self._device_repo.get_by_id_and_user(session, payload.device_id, user_id)
            if device is None:
                raise NotFoundError("Device not found")

            device.status = payload.status
            device.agent_version = payload.agent_version or device.agent_version
            device.last_seen_at = utcnow()
            await session.commit()
            await session.refresh(device)
            return device

    async def list_devices(self, user_id: UUID) -> list[Device]:
        async with self._session_factory() as session:
            return await self._device_repo.list_by_user(session, user_id)

    async def get_most_recent(self, user_id: UUID) -> Device | None:
        async with self._session_factory() as session:
            return await self._device_repo.get_most_recent(session, user_id)

    async def get_device(self, user_id: UUID, device_id: UUID) -> Device:
        async with self._session_factory() as session:
            device = await self._device_repo.get_by_id_and_user(session, device_id, user_id)
            if device is None:
                raise NotFoundError("Device not found")
            return device
