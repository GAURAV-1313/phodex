import os
import uuid

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db.base import Base
from app.models.user import User
from app.models.task import Task
from app.models.task_event import TaskEvent
from app.models.task_message import TaskMessage
from app.models.approval_request import ApprovalRequest
from app.models.enums import TaskStatus, TaskMessageRole, ApprovalStatus


def _create_test_user() -> User:
    return User(
        google_sub=f"bench-user-{uuid.uuid4()}",
        email=f"bench-{uuid.uuid4().hex[:8]}@test.com",
        name="Benchmark User",
        password_hash=None,
    )


async def _create_user_with_tasks(
    engine,
    n_tasks: int = 100,
    events_per_task: int = 20,
    messages_per_task: int = 10,
    with_approvals: bool = False,
) -> tuple:
    session_factory = async_sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    task_ids = []
    async with session_factory() as session:
        user = _create_test_user()
        session.add(user)
        await session.flush()

        for i in range(n_tasks):
            task = Task(
                user_id=user.id,
                prompt=f"benchmark task {i}: implement feature and fix bugs",
                title=f"Benchmark Task {i}",
                status=TaskStatus.COMPLETED if i % 3 == 0 else TaskStatus.RUNNING,
                current_phase="done" if i % 3 == 0 else "executing",
            )
            session.add(task)
            await session.flush()
            task_ids.append(str(task.id))

            for j in range(events_per_task):
                event = TaskEvent(
                    task_id=task.id,
                    seq_no=j,
                    event_type="task.progress" if j % 2 == 0 else "task.log",
                    payload_json={"message": f"Progress update {j}", "source": "worker"},
                )
                session.add(event)

            for j in range(messages_per_task):
                msg = TaskMessage(
                    task_id=task.id,
                    role=TaskMessageRole.ASSISTANT if j % 2 == 0 else TaskMessageRole.USER,
                    content=f"Assistant message {j}" if j % 2 == 0 else f"User reply {j}",
                )
                session.add(msg)

            if with_approvals:
                approval = ApprovalRequest(
                    task_id=task.id,
                    kind="command_execution",
                    title=f"Approve task {i}",
                    description=f"Worker requests permission for task {i}",
                    payload_json={"command": "git commit", "risk_level": "medium"},
                    status=ApprovalStatus.PENDING,
                )
                session.add(approval)

        await session.commit()

    return user, task_ids


@pytest.mark.benchmark(min_rounds=50, group="db")
async def test_list_tasks_pagination_sqlite(sqlite_engine, benchmark):
    """Benchmark list_tasks at different volumes."""
    for n in [100, 500, 1000]:
        await _create_user_with_tasks(sqlite_engine, n_tasks=n, events_per_task=5, messages_per_task=3, with_approvals=False)

    session_factory = async_sessionmaker(bind=sqlite_engine, autoflush=False, expire_on_commit=False)

    async def query(offset: int, limit: int = 20) -> list:
        async with session_factory() as session:
            result = await session.execute(
                text("SELECT * FROM tasks ORDER BY created_at DESC LIMIT :limit OFFSET :offset"),
                {"limit": limit, "offset": offset}
            )
            return result.fetchall()

    benchmark(query, 0, 20)


@pytest.mark.benchmark(min_rounds=50, group="db")
async def test_get_task_detail_sqlite(sqlite_engine, benchmark):
    """Benchmark task detail query (joins 4 tables via separate queries)."""
    user, task_ids = await _create_user_with_tasks(
        sqlite_engine, n_tasks=1, events_per_task=50, messages_per_task=30, with_approvals=True
    )

    session_factory = async_sessionmaker(bind=sqlite_engine, autoflush=False, expire_on_commit=False)
    task_id = task_ids[0]

    async def query() -> dict:
        async with session_factory() as session:
            task = await session.get(Task, task_id)
            messages = await session.execute(
                text("SELECT * FROM task_messages WHERE task_id = :tid ORDER BY created_at"),
                {"tid": task_id}
            )
            events = await session.execute(
                text("SELECT * FROM task_events WHERE task_id = :tid ORDER BY seq_no"),
                {"tid": task_id}
            )
            approvals = await session.execute(
                text("SELECT * FROM approval_requests WHERE task_id = :tid"),
                {"tid": task_id}
            )
            return {
                "task": task,
                "messages": messages.fetchall(),
                "events": events.fetchall(),
                "approvals": approvals.fetchall(),
            }

    benchmark(query)


@pytest.mark.benchmark(min_rounds=50, group="db")
async def test_list_events_sqlite(sqlite_engine, benchmark):
    """Benchmark listing events for a task with many events."""
    user, task_ids = await _create_user_with_tasks(
        sqlite_engine, n_tasks=1, events_per_task=200, messages_per_task=5, with_approvals=False
    )

    session_factory = async_sessionmaker(bind=sqlite_engine, autoflush=False, expire_on_commit=False)
    task_id = task_ids[0]

    async def query() -> list:
        async with session_factory() as session:
            result = await session.execute(
                text("SELECT * FROM task_events WHERE task_id = :tid ORDER BY seq_no"),
                {"tid": task_id}
            )
            return result.fetchall()

    benchmark(query)


@pytest.mark.benchmark(min_rounds=50, group="db")
async def test_list_pending_approvals_sqlite(sqlite_engine, benchmark):
    """Benchmark listing pending approvals."""
    user, task_ids = await _create_user_with_tasks(
        sqlite_engine, n_tasks=10, events_per_task=5, messages_per_task=3, with_approvals=True
    )

    session_factory = async_sessionmaker(bind=sqlite_engine, autoflush=False, expire_on_commit=False)

    async def query() -> list:
        async with session_factory() as session:
            result = await session.execute(
                text("SELECT * FROM approval_requests WHERE status = 'pending' ORDER BY created_at DESC")
            )
            return result.fetchall()

    benchmark(query)


@pytest.mark.benchmark(min_rounds=50, group="db")
async def test_list_messages_sqlite(sqlite_engine, benchmark):
    """Benchmark listing messages for a task."""
    user, task_ids = await _create_user_with_tasks(
        sqlite_engine, n_tasks=1, events_per_task=5, messages_per_task=100, with_approvals=False
    )

    session_factory = async_sessionmaker(bind=sqlite_engine, autoflush=False, expire_on_commit=False)
    task_id = task_ids[0]

    async def query() -> list:
        async with session_factory() as session:
            result = await session.execute(
                text("SELECT * FROM task_messages WHERE task_id = :tid ORDER BY created_at"),
                {"tid": task_id}
            )
            return result.fetchall()

    benchmark(query)


@pytest.mark.skipif(not os.environ.get("POSTGRES_URL"), reason="POSTGRES_URL not set")
@pytest.mark.benchmark(min_rounds=30, group="db")
async def test_list_tasks_pagination_pg(pg_engine, benchmark):
    """Same tests against PostgreSQL."""
    for n in [100, 500, 1000]:
        await _create_user_with_tasks(pg_engine, n_tasks=n, events_per_task=5, messages_per_task=3, with_approvals=False)

    session_factory = async_sessionmaker(bind=pg_engine, autoflush=False, expire_on_commit=False)

    async def query(offset: int, limit: int = 20) -> list:
        async with session_factory() as session:
            result = await session.execute(
                text("SELECT * FROM tasks ORDER BY created_at DESC LIMIT :limit OFFSET :offset"),
                {"limit": limit, "offset": offset}
            )
            return result.fetchall()

    benchmark(query, 0, 20)


@pytest.mark.skipif(not os.environ.get("POSTGRES_URL"), reason="POSTGRES_URL not set")
@pytest.mark.benchmark(min_rounds=30, group="db")
async def test_get_task_detail_pg(pg_engine, benchmark):
    user, task_ids = await _create_user_with_tasks(
        pg_engine, n_tasks=1, events_per_task=50, messages_per_task=30, with_approvals=True
    )

    session_factory = async_sessionmaker(bind=pg_engine, autoflush=False, expire_on_commit=False)
    task_id = task_ids[0]

    async def query() -> dict:
        async with session_factory() as session:
            task = await session.get(Task, task_id)
            messages = await session.execute(
                text("SELECT * FROM task_messages WHERE task_id = :tid ORDER BY created_at"),
                {"tid": task_id}
            )
            events = await session.execute(
                text("SELECT * FROM task_events WHERE task_id = :tid ORDER BY seq_no"),
                {"tid": task_id}
            )
            approvals = await session.execute(
                text("SELECT * FROM approval_requests WHERE task_id = :tid"),
                {"tid": task_id}
            )
            return {
                "task": task,
                "messages": messages.fetchall(),
                "events": events.fetchall(),
                "approvals": approvals.fetchall(),
            }

    benchmark(query)
