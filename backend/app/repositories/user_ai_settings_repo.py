from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_ai_settings import UserAiSettings

from .base import BaseRepository


class UserAiSettingsRepository(BaseRepository):
    async def get_by_user_id(self, session: AsyncSession, user_id: UUID) -> UserAiSettings | None:
        return await session.scalar(select(UserAiSettings).where(UserAiSettings.user_id == user_id))

    async def create(self, session: AsyncSession, settings: UserAiSettings) -> UserAiSettings:
        session.add(settings)
        return settings

    async def update(self, session: AsyncSession, settings: UserAiSettings) -> UserAiSettings:
        await session.commit()
        return settings
