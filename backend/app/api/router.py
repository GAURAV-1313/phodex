from fastapi import APIRouter

from app.api import account, approvals, auth, devices, health, repos, stream, tasks

api_router = APIRouter()
api_router.include_router(account.router)
api_router.include_router(auth.router)
api_router.include_router(tasks.router)
api_router.include_router(approvals.router)
api_router.include_router(devices.router)
api_router.include_router(repos.router)
api_router.include_router(stream.router)
api_router.include_router(health.router)
