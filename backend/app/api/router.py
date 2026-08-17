from fastapi import APIRouter

from app.api import (
    account,
    ai_settings,
    approvals,
    auth,
    devices,
    git_ops,
    health,
    repos,
    stream,
    tasks,
)

api_router = APIRouter()
api_router.include_router(account.router)
api_router.include_router(ai_settings.router)
api_router.include_router(auth.router)
api_router.include_router(tasks.router)
api_router.include_router(git_ops.router)
api_router.include_router(approvals.router)
api_router.include_router(devices.router)
api_router.include_router(repos.router)
api_router.include_router(stream.router)
api_router.include_router(health.router)
