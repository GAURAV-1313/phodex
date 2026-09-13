from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.repos import (
    CurrentProjectContextResponse,
    GithubConnectRequest,
    GithubCredentialsRequest,
    GithubCredentialsResponse,
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


@router.post(
    "/github/connect", response_model=SyncedRepositoryOut, status_code=status.HTTP_201_CREATED
)
async def connect_github_repository(
    payload: GithubConnectRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SyncedRepositoryOut:
    """Cloud runtime: clone (or refresh) a GitHub repository into this server's
    workspace and register it like a synced repository, so it can be selected
    and worked on exactly like a laptop repository."""
    repo = await services.cloud_repo_service.connect_repository(
        current_user, payload.url, payload.branch, payload.token
    )
    return SyncedRepositoryOut.model_validate(repo)


@router.put("/github/credentials", response_model=GithubCredentialsResponse)
async def update_github_credentials(
    payload: GithubCredentialsRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> GithubCredentialsResponse:
    configured = await services.user_ai_settings_service.set_github_token(
        current_user.id, None if payload.clear else payload.token
    )
    return GithubCredentialsResponse(has_github_token=configured)


@router.get("", response_model=RepoListResponse)
async def list_repositories(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RepoListResponse:
    repos = await services.repo_sync_service.list_repositories(current_user.id)
    return RepoListResponse(items=[SyncedRepositoryOut.model_validate(repo) for repo in repos])


@router.get("/context/current", response_model=CurrentProjectContextResponse)
async def get_current_context(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> CurrentProjectContextResponse:
    from app.schemas.repos import ProjectContextOut

    context = await services.repo_sync_service.get_current_context(current_user.id)
    return CurrentProjectContextResponse(
        project_context=ProjectContextOut.model_validate(context) if context else None
    )


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
