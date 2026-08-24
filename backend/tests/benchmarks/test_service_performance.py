import asyncio
import uuid

import pytest
from httpx import AsyncClient


@pytest.mark.benchmark(min_rounds=100, group="service")
async def test_auth_login(client: AsyncClient, benchmark):
    """Benchmark password login (bcrypt hash + JWT)."""
    email = f"bench-{uuid.uuid4().hex[:8]}@test.com"
    async def login() -> int:
        r = await client.post("/auth/register", json={
            "email": email,
            "password": "testpassword123",
            "name": "Bench User",
        })
        if r.status_code == 201:
            return r.status_code
        r = await client.post("/auth/login", json={
            "email": email,
            "password": "testpassword123",
        })
        return r.status_code
    benchmark(login)


@pytest.mark.benchmark(min_rounds=100, group="service")
async def test_auth_google(client: AsyncClient, benchmark):
    """Benchmark Google auth (token verify + JWT)."""
    async def auth() -> int:
        token = f"test-token|bench-{uuid.uuid4().hex[:8]}|bench@test.com|bench-user"
        r = await client.post("/auth/google", json={"id_token": token})
        return r.status_code
    benchmark(auth)


@pytest.mark.benchmark(min_rounds=100, group="service")
async def test_task_create(client: AsyncClient, login, benchmark):
    """Benchmark task creation."""
    headers = await login()
    async def create() -> int:
        r = await client.post("/tasks", json={
            "prompt": "benchmark task creation test",
        }, headers=headers)
        return r.status_code
    benchmark(create)


@pytest.mark.benchmark(min_rounds=100, group="service")
async def test_task_cancel(client: AsyncClient, login, benchmark):
    """Benchmark task cancellation."""
    headers = await login()
    r = await client.post("/tasks", json={"prompt": "test"}, headers=headers)
    task_id = r.json()["id"]

    async def cancel() -> int:
        r = await client.post(f"/tasks/{task_id}/cancel", headers=headers)
        return r.status_code
    benchmark(cancel)


@pytest.mark.benchmark(min_rounds=100, group="service")
async def test_approval_approve(client: AsyncClient, login, benchmark):
    """Benchmark approval decision."""
    headers = await login()
    r = await client.post("/tasks", json={"prompt": "test with approval"}, headers=headers)
    task_id = r.json()["id"]

    r = await client.get("/approvals/pending", headers=headers)
    approvals = r.json()["items"]
    if not approvals:
        pytest.skip("No pending approvals to test")

    approval_id = approvals[0]["id"]

    async def approve() -> int:
        r = await client.post(
            f"/approvals/{approval_id}/approve",
            json={"note": "benchmark approve"},
            headers=headers,
        )
        return r.status_code
    benchmark(approve)


@pytest.mark.benchmark(min_rounds=100, group="service")
async def test_task_detail_query(client: AsyncClient, login, benchmark):
    """Benchmark task detail query (heavy join)."""
    headers = await login()
    r = await client.post("/tasks", json={"prompt": "test detail query"}, headers=headers)
    task_id = r.json()["id"]

    async def detail() -> int:
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        return r.status_code
    benchmark(detail)
