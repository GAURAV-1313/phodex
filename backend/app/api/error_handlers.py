"""Centralizes translation of ServiceError subclasses into HTTP responses.

Routes raise ServiceError subclasses directly and no longer need try/except
boilerplate around every service call. Starlette dispatches by exception MRO,
so the most specific handler below always wins (e.g. LimitExceededError over
its ConflictError base). Anything that reaches bare ServiceError still
returns a clean 500 instead of leaking an unhandled traceback.
"""

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse

from app.services.exceptions import (
    ConflictError,
    ForbiddenError,
    LimitExceededError,
    NotFoundError,
    ServiceError,
    UnauthorizedError,
)


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(LimitExceededError)
    async def handle_limit_exceeded(_: Request, exc: LimitExceededError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"detail": {"code": exc.code, "message": str(exc)}},
        )

    @app.exception_handler(NotFoundError)
    async def handle_not_found(_: Request, exc: NotFoundError) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_404_NOT_FOUND, content={"detail": str(exc)})

    @app.exception_handler(UnauthorizedError)
    async def handle_unauthorized(_: Request, exc: UnauthorizedError) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_401_UNAUTHORIZED, content={"detail": str(exc)})

    @app.exception_handler(ForbiddenError)
    async def handle_forbidden(_: Request, exc: ForbiddenError) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_403_FORBIDDEN, content={"detail": str(exc)})

    @app.exception_handler(ConflictError)
    async def handle_conflict(_: Request, exc: ConflictError) -> JSONResponse:
        return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": str(exc)})

    @app.exception_handler(ServiceError)
    async def handle_service_error(_: Request, exc: ServiceError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "Internal service error"},
        )
