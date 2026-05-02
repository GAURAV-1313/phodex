from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.auth import AuthTokenResponse, GoogleAuthRequest, UserOut
from app.services.exceptions import LimitExceededError, UnauthorizedError
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google", response_model=AuthTokenResponse)
async def google_auth(
    payload: GoogleAuthRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
) -> AuthTokenResponse:
    try:
        profile = await services.google_auth_service.verify_id_token(payload.id_token)
    except UnauthorizedError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    try:
        token, expires_at, user = await services.auth_service.login_with_google_profile(profile)
    except LimitExceededError as exc:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": exc.code, "message": str(exc)},
        ) from exc

    return AuthTokenResponse(
        access_token=token,
        expires_at=expires_at,
        user=UserOut.model_validate(user),
    )


@router.get("/me", response_model=UserOut)
async def me(current_user: Annotated[User, Depends(get_current_user)]) -> UserOut:
    return UserOut.model_validate(current_user)
