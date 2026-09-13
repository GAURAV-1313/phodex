import os
from collections.abc import AsyncIterator

import pytest
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    create_async_engine,
)

from app.db.base import Base


@pytest.fixture(scope="session")
async def sqlite_engine(tmp_path_factory) -> AsyncIterator[AsyncEngine]:
    db_file = tmp_path_factory.mktemp("bench") / "bench.sqlite3"
    engine = create_async_engine(f"sqlite+aiosqlite:///{db_file}", echo=False, pool_pre_ping=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture(scope="function")
async def pg_engine() -> AsyncIterator[AsyncEngine]:
    url = os.environ.get("POSTGRES_URL")
    if not url:
        pytest.skip("POSTGRES_URL not set — skipping PostgreSQL benchmarks")
    engine = create_async_engine(url, echo=False, pool_pre_ping=True, pool_size=10, max_overflow=20)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()



