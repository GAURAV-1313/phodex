from __future__ import annotations

from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.push_subscription import PushSubscription

from .base import BaseRepository


class PushRepository(BaseRepository):
    async def get_by_token(self, session: AsyncSession, fcm_token: str) -> PushSubscription | None:
        return await session.scalar(select(PushSubscription).where(PushSubscription.fcm_token == fcm_token))

    async def register_token(self, session: AsyncSession, subscription: PushSubscription) -> PushSubscription:
        existing = await self.get_by_token(session, subscription.fcm_token)
        if existing is not None:
            existing.user_id = subscription.user_id
            existing.platform = subscription.platform
            await session.commit()
            return existing
        session.add(subscription)
        await session.commit()
        return subscription

    async def unregister_token(self, session: AsyncSession, fcm_token: str, user_id: UUID) -> None:
        await session.execute(
            delete(PushSubscription).where(
                PushSubscription.fcm_token == fcm_token,
                PushSubscription.user_id == user_id,
            )
        )
        await session.commit()

    async def get_tokens_by_user(self, session: AsyncSession, user_id: UUID) -> list[str]:
        result = await session.execute(
            select(PushSubscription.fcm_token).where(PushSubscription.user_id == user_id)
        )
        return list(result.scalars().all())
