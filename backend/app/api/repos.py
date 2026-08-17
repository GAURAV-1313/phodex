from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.repos import (
    RepoListResponse,
    RepoSelectRequest,
    RepoSelectResponse,
    RepoSyncRequest,
    RepoSyncResponse,
    SyncedRepositoryOut,
)
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/repos", tags=["repos"])


@router.post("/sync", response_model=RepoSyncResponse)
async def sync_repositories(
    payload: RepoSyncRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RepoSyncResponse:
    repos = await services.repo_sync_service.sync_repositories(current_user.id, payload)
    return RepoSyncResponse(
        synced_count=len(repos),
        items=[SyncedRepositoryOut.model_validate(repo) for repo in repos],
    )


@router.get("", response_model=RepoListResponse)
async def list_repositories(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RepoListResponse:
    repos = await services.repo_sync_service.list_repositories(current_user.id)
    return RepoListResponse(items=[SyncedRepositoryOut.model_validate(repo) for repo in repos])


@router.get("/{repo_id}", response_model=SyncedRepositoryOut)
async def get_repository(
    repo_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SyncedRepositoryOut:
    repo = await services.repo_sync_service.get_repository(current_user.id, repo_id)
    return SyncedRepositoryOut.model_validate(repo)


@router.post("/{repo_id}/select", response_model=RepoSelectResponse)
async def select_repository(
    repo_id: UUID,
    payload: RepoSelectRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RepoSelectResponse:
    context = await services.repo_sync_service.select_repository(
        current_user.id,
        repo_id,
        name=payload.name,
    )

    from app.schemas.repos import ProjectContextOut

    return RepoSelectResponse(project_context=ProjectContextOut.model_validate(context))
