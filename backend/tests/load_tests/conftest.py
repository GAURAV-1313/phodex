import asyncio
import uuid
from collections.abc import AsyncIterator, Callable, Awaitable

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.config import Settings
from app.main import create_app


@pytest.fixture
async def app() -> AsyncIterator:
    """FastAPI app for load tests."""
    import tempfile
    db_file = tempfile.mktemp(suffix=".db")
    settings = Settings(
        DATABASE_URL=f"sqlite+aiosqlite:///{db_file}",
        REDIS_URL=None,
        OTEL_EXPORTER_OTLP_ENDPOINT=None,
        AUTO_CREATE_SCHEMA=True,
        ALLOW_INSECURE_TEST_TOKENS=True,
        JWT_SECRET_KEY="test-secret",
        WORKER_ENGINE="fake",
        FAKE_WORKER_STEP_DELAY_SECONDS=0.01,
    )
    application = create_app(settings)
    async with application.router.lifespan_context(application):
        yield application


@pytest.fixture
async def client(app) -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
async def login(client: AsyncClient) -> Callable[[str], Awaitable[dict[str, str]]]:
    async def _login(sub: str = "load-user") -> dict[str, str]:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        response = await client.post("/auth/google", json={"id_token": token})
        assert response.status_code == 200
        access_token = response.json()["access_token"]
        return {"Authorization": f"Bearer {access_token}"}
    return _login


@pytest.fixture
async def load_user(client: AsyncClient, login) -> dict[str, str]:
    return await login("load-user")


@pytest.fixture
async def load_task(client: AsyncClient, load_user) -> str:
    r = await client.post("/tasks", json={"prompt": "load test task"}, headers=load_user)
    assert r.status_code == 201
    return r.json()["id"]


@pytest.fixture
async def load_tasks(client: AsyncClient, load_user, request) -> list[str]:
    """Create N tasks for load testing."""
    n = getattr(request, "param", 10)
    task_ids = []
    for _ in range(n):
        r = await client.post("/tasks", json={"prompt": f"load test task {uuid.uuid4().hex[:6]}"}, headers=load_user)
        if r.status_code == 201:
            task_ids.append(r.json()["id"])
    return task_ids
