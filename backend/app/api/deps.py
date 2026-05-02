from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.models.user import User
from app.services.exceptions import UnauthorizedError
from app.services.service_registry import ServiceRegistry

bearer_scheme = HTTPBearer(auto_error=False)


async def get_services(request: Request) -> ServiceRegistry:
    return request.app.state.services  # type: ignore[no-any-return]


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    services: Annotated[ServiceRegistry, Depends(get_services)],
) -> User:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    try:
        return await services.auth_service.get_user_from_bearer(f"Bearer {credentials.credentials}")
    except UnauthorizedError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc
