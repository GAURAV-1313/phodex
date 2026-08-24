from __future__ import annotations

from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.project_context import ProjectContext
from app.models.synced_repository import SyncedRepository

from .base import BaseRepository


class RepoRepository(BaseRepository):
    async def list_by_user(self, session: AsyncSession, user_id: UUID) -> list[SyncedRepository]:
        result = await session.execute(
            select(SyncedRepository)
            .where(SyncedRepository.user_id == user_id)
            .options(selectinload(SyncedRepository.device))
            .order_by(
                SyncedRepository.is_active.desc(), SyncedRepository.updated_at.desc()
            )
        )
        return list(result.scalars().all())

    async def get_by_id(self, session: AsyncSession, repo_id: UUID, user_id: UUID) -> SyncedRepository | None:
        return await session.scalar(
            select(SyncedRepository)
            .where(SyncedRepository.id == repo_id, SyncedRepository.user_id == user_id)
            .options(selectinload(SyncedRepository.device))
        )

    async def get_by_id_no_user(self, session: AsyncSession, repo_id: UUID) -> SyncedRepository | None:
        return await session.scalar(select(SyncedRepository).where(SyncedRepository.id == repo_id))

    async def list_by_user_and_device(
        self, session: AsyncSession, user_id: UUID, device_id: UUID
    ) -> list[SyncedRepository]:
        result = await session.execute(
            select(SyncedRepository).where(
                SyncedRepository.user_id == user_id,
                SyncedRepository.device_id == device_id,
            )
        )
        return list(result.scalars().all())

    async def create(self, session: AsyncSession, repo: SyncedRepository) -> SyncedRepository:
        session.add(repo)
        return repo

    async def update(self, session: AsyncSession, repo: SyncedRepository) -> SyncedRepository:
        await session.commit()
        await session.refresh(repo)
        return repo

    async def select_repository(
        self, session: AsyncSession, user_id: UUID, context: ProjectContext
    ) -> ProjectContext:
        await session.execute(
            update(ProjectContext)
            .where(ProjectContext.user_id == user_id, ProjectContext.is_current.is_(True))
            .values(is_current=False)
        )
        session.add(context)
        await session.commit()
        await session.refresh(context)
        return context

    async def get_current_context(self, session: AsyncSession, user_id: UUID) -> ProjectContext | None:
        return await session.scalar(
            select(ProjectContext)
            .where(ProjectContext.user_id == user_id, ProjectContext.is_current.is_(True))
            .order_by(ProjectContext.updated_at.desc())
        )
