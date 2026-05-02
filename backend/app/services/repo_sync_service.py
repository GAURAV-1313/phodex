from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.device import Device
from app.models.enums import ProjectContextSourceType
from app.models.project_context import ProjectContext
from app.models.synced_repository import SyncedRepository
from app.schemas.repos import RepoSyncRequest
from app.services.exceptions import NotFoundError
from app.utils.datetime import utcnow


class RepoSyncService:
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def sync_repositories(
        self, user_id: UUID, payload: RepoSyncRequest
    ) -> list[SyncedRepository]:
        scan_time = payload.scanned_at or utcnow()

        async with self._session_factory() as session:
            device = await session.scalar(
                select(Device).where(Device.id == payload.device_id, Device.user_id == user_id)
            )
            if device is None:
                raise NotFoundError("Device not found")

            existing = (
                (
                    await session.execute(
                        select(SyncedRepository).where(
                            SyncedRepository.user_id == user_id,
                            SyncedRepository.device_id == payload.device_id,
                        )
                    )
                )
                .scalars()
                .all()
            )

            existing_by_git_root = {repo.git_root: repo for repo in existing}
            seen_git_roots: set[str] = set()
            touched: list[SyncedRepository] = []

            for item in payload.repositories:
                seen_git_roots.add(item.git_root)
                repo = existing_by_git_root.get(item.git_root)
                if repo is None:
                    repo = SyncedRepository(
                        user_id=user_id,
                        device_id=payload.device_id,
                        name=item.name,
                        local_path=item.local_path,
                        git_root=item.git_root,
                        current_branch=item.current_branch,
                        default_branch=item.default_branch,
                        last_opened_at=item.last_opened_at,
                        last_scanned_at=scan_time,
                        metadata_json=item.metadata_json,
                        is_active=True,
                    )
                    session.add(repo)
                else:
                    repo.name = item.name
                    repo.local_path = item.local_path
                    repo.current_branch = item.current_branch
                    repo.default_branch = item.default_branch
                    repo.last_opened_at = item.last_opened_at
                    repo.last_scanned_at = scan_time
                    repo.metadata_json = item.metadata_json
                    repo.is_active = True
                touched.append(repo)

            for repo in existing:
                if repo.git_root not in seen_git_roots:
                    repo.is_active = False
                    repo.last_scanned_at = scan_time

            device.last_seen_at = utcnow()
            await session.commit()

            for repo in touched:
                await session.refresh(repo)
            return touched

    async def list_repositories(self, user_id: UUID) -> list[SyncedRepository]:
        async with self._session_factory() as session:
            repos = (
                (
                    await session.execute(
                        select(SyncedRepository)
                        .where(SyncedRepository.user_id == user_id)
                        .order_by(
                            SyncedRepository.is_active.desc(), SyncedRepository.updated_at.desc()
                        )
                    )
                )
                .scalars()
                .all()
            )
            return repos

    async def get_repository(self, user_id: UUID, repo_id: UUID) -> SyncedRepository:
        async with self._session_factory() as session:
            repo = await session.scalar(
                select(SyncedRepository).where(
                    SyncedRepository.id == repo_id, SyncedRepository.user_id == user_id
                )
            )
            if repo is None:
                raise NotFoundError("Repository not found")
            return repo

    async def select_repository(
        self, user_id: UUID, repo_id: UUID, name: str | None = None
    ) -> ProjectContext:
        async with self._session_factory() as session:
            repo = await session.scalar(
                select(SyncedRepository).where(
                    SyncedRepository.id == repo_id, SyncedRepository.user_id == user_id
                )
            )
            if repo is None:
                raise NotFoundError("Repository not found")

            context = ProjectContext(
                user_id=user_id,
                source_type=ProjectContextSourceType.LOCAL_SYNCED,
                synced_repository_id=repo.id,
                name=name or f"{repo.name} ({repo.current_branch or 'unknown-branch'})",
                branch=repo.current_branch,
                metadata_json={
                    "local_path": repo.local_path,
                    "git_root": repo.git_root,
                    "device_id": str(repo.device_id),
                },
            )
            session.add(context)
            await session.commit()
            await session.refresh(context)
            return context
