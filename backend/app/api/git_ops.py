from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.git_ops import GitConfirmRequest, GitOperationOut
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/tasks", tags=["git"])


@router.post("/{task_id}/git/prepare", response_model=GitOperationOut)
async def prepare_git_commit(
    task_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> GitOperationOut:
    operation = await services.git_service.prepare_commit(current_user.id, task_id)
    return GitOperationOut.model_validate(operation)


@router.post("/{task_id}/git/{git_operation_id}/confirm", response_model=GitOperationOut)
async def confirm_git_commit(
    task_id: UUID,
    git_operation_id: UUID,
    payload: GitConfirmRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> GitOperationOut:
    operation = await services.git_service.confirm(
        current_user.id, task_id, git_operation_id, payload.commit_message
    )
    return GitOperationOut.model_validate(operation)


@router.post("/{task_id}/git/{git_operation_id}/discard", response_model=GitOperationOut)
async def discard_git_commit(
    task_id: UUID,
    git_operation_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> GitOperationOut:
    operation = await services.git_service.discard(current_user.id, task_id, git_operation_id)
    return GitOperationOut.model_validate(operation)
