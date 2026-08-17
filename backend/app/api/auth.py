from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.auth import (
    AuthTokenResponse,
    GoogleAuthRequest,
    LoginRequest,
    RegisterRequest,
    UserOut,
)
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google", response_model=AuthTokenResponse)
async def google_auth(
    payload: GoogleAuthRequest,
    request: Request,
    services: Annotated[ServiceRegistry, Depends(get_services)],
) -> AuthTokenResponse:
    client_host = request.client.host if request.client else "unknown"
    allowed = await services.redis.allow(
        f"rate:auth:{client_host}",
        services.settings.auth_rate_limit_per_minute,
        60,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Too many login attempts"
        )
    profile = await services.google_auth_service.verify_id_token(payload.id_token)
    token, expires_at, user = await services.auth_service.login_with_google_profile(profile)

    return AuthTokenResponse(
        access_token=token,
        expires_at=expires_at,
        user=UserOut.model_validate(user),
    )


@router.post("/register", response_model=AuthTokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    payload: RegisterRequest,
    request: Request,
    services: Annotated[ServiceRegistry, Depends(get_services)],
) -> AuthTokenResponse:
    client_host = request.client.host if request.client else "unknown"
    allowed = await services.redis.allow(
        f"rate:auth:{client_host}",
        services.settings.auth_rate_limit_per_minute,
        60,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Too many requests"
        )
    token, expires_at, user = await services.auth_service.register_with_password(
        email=str(payload.email), password=payload.password, name=payload.name
    )
    return AuthTokenResponse(
        access_token=token,
        expires_at=expires_at,
        user=UserOut.model_validate(user),
    )


@router.post("/login", response_model=AuthTokenResponse)
async def login(
    payload: LoginRequest,
    request: Request,
    services: Annotated[ServiceRegistry, Depends(get_services)],
) -> AuthTokenResponse:
    client_host = request.client.host if request.client else "unknown"
    allowed = await services.redis.allow(
        f"rate:auth:{client_host}",
        services.settings.auth_rate_limit_per_minute,
        60,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Too many requests"
        )
    token, expires_at, user = await services.auth_service.login_with_password(
        email=str(payload.email), password=payload.password
    )
    return AuthTokenResponse(
        access_token=token,
        expires_at=expires_at,
        user=UserOut.model_validate(user),
    )


@router.get("/me", response_model=UserOut)
async def me(current_user: Annotated[User, Depends(get_current_user)]) -> UserOut:
    return UserOut.model_validate(current_user)
