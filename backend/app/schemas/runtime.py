from pydantic import BaseModel

from app.schemas.devices import DeviceOut


class PublicRuntimeInfoResponse(BaseModel):
    """Unauthenticated: lets the app decide what to show before sign-in."""

    mode: str
    runner_name: str
    demo_available: bool
    worker_engine: str


class RuntimeInfoResponse(BaseModel):
    mode: str
    runner: DeviceOut | None
    has_github_token: bool
    demo_available: bool
    worker_engine: str
