from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.approvals import (
    ApprovalDecisionRequest,
    ApprovalRequestOut,
    PendingApprovalsResponse,
)
from app.services.exceptions import ConflictError, NotFoundError
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/approvals", tags=["approvals"])


@router.get("/pending", response_model=PendingApprovalsResponse)
async def pending_approvals(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> PendingApprovalsResponse:
    approvals = await services.approval_service.list_pending(current_user.id)
    return PendingApprovalsResponse(
        items=[ApprovalRequestOut.model_validate(item) for item in approvals]
    )


@router.post("/{approval_id}/approve", response_model=ApprovalRequestOut)
async def approve(
    approval_id: UUID,
    payload: ApprovalDecisionRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ApprovalRequestOut:
    try:
        approval = await services.approval_service.approve(
            current_user.id, approval_id, note=payload.note
        )
    except NotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except ConflictError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc

    return ApprovalRequestOut.model_validate(approval)


@router.post("/{approval_id}/reject", response_model=ApprovalRequestOut)
async def reject(
    approval_id: UUID,
    payload: ApprovalDecisionRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ApprovalRequestOut:
    try:
        approval = await services.approval_service.reject(
            current_user.id, approval_id, note=payload.note
        )
    except NotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except ConflictError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc

    return ApprovalRequestOut.model_validate(approval)
