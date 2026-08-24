import os
import uuid
from collections.abc import AsyncIterator

import pytest
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from app.db.base import Base
from app.models.user import User
from app.models.task import Task
from app.models.task_event import TaskEvent
from app.models.task_message import TaskMessage
from app.models.approval_request import ApprovalRequest
from app.models.enums import TaskStatus, TaskMessageRole, ApprovalStatus


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



