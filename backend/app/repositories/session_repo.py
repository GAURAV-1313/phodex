from __future__ import annotations

from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.session import Session

from .base import BaseRepository


class SessionRepository(BaseRepository):
    async def get_by_jti(self, session: AsyncSession, jwt_jti: str) -> Session | None:
        return await session.scalar(select(Session).where(Session.jwt_jti == jwt_jti))

    async def create(self, session: AsyncSession, session_obj: Session) -> Session:
        session.add(session_obj)
        return session_obj

    async def list_active(self, session: AsyncSession, user_id: UUID) -> list[Session]:
        from app.utils.datetime import utcnow
        result = await session.scalars(
            select(Session)
            .where(
                Session.user_id == user_id,
                Session.revoked_at.is_(None),
                Session.expires_at > utcnow(),
            )
            .order_by(Session.created_at.desc())
        )
        return list(result.all())

    async def revoke(self, session: AsyncSession, session_obj: Session) -> None:
        if session_obj.revoked_at is None:
            session_obj.revoked_at = datetime.now(session_obj.revoked_at.type.timezone.__class__ if hasattr(session_obj.revoked_at.type, 'timezone') else None)
            await session.commit()

    async def revoke_others(
        self, session: AsyncSession, user_id: UUID, keep_session_id: UUID
    ) -> int:
        result = await session.scalars(
            select(Session).where(
                Session.user_id == user_id,
                Session.id != keep_session_id,
                Session.revoked_at.is_(None),
            )
        )
        sessions = list(result.all())
        from app.utils.datetime import utcnow

        now = utcnow()
        for s in sessions:
            s.revoked_at = now
        await session.commit()
        return len(sessions)
