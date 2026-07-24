import uuid
from collections.abc import AsyncIterator, Awaitable, Callable

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.config import Settings
from app.main import create_app


@pytest.fixture
async def app(tmp_path) -> AsyncIterator:
    db_file = tmp_path / f"test-{uuid.uuid4()}.db"
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
    async def _login(sub: str = "user-1") -> dict[str, str]:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        response = await client.post("/auth/google", json={"id_token": token})
        assert response.status_code == 200
        access_token = response.json()["access_token"]
        return {"Authorization": f"Bearer {access_token}"}

    return _login
