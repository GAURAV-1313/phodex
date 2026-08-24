from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device import Device

from .base import BaseRepository


class DeviceRepository(BaseRepository):
    async def get_by_id(self, session: AsyncSession, device_id: UUID) -> Device | None:
        return await session.scalar(select(Device).where(Device.id == device_id))

    async def get_by_id_and_user(self, session: AsyncSession, device_id: UUID, user_id: UUID) -> Device | None:
        return await session.scalar(select(Device).where(Device.id == device_id, Device.user_id == user_id))

    async def create(self, session: AsyncSession, device: Device) -> Device:
        session.add(device)
        return device

    async def update(self, session: AsyncSession, device: Device) -> Device:
        await session.commit()
        await session.refresh(device)
        return device

    async def list_by_user(self, session: AsyncSession, user_id: UUID) -> list[Device]:
        result = await session.execute(
            select(Device)
            .where(Device.user_id == user_id)
            .order_by(Device.updated_at.desc())
        )
        return list(result.scalars().all())

    async def get_most_recent(self, session: AsyncSession, user_id: UUID) -> Device | None:
        return await session.scalar(
            select(Device)
            .where(Device.user_id == user_id)
            .order_by(Device.last_seen_at.desc().nulls_last())
            .limit(1)
        )
