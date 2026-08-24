import asyncio
import uuid

import pytest
from httpx import AsyncClient


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_auth_register(client: AsyncClient, benchmark):
    """Benchmark auth registration endpoint."""
    async def register() -> int:
        email = f"user-{uuid.uuid4().hex[:8]}@test.com"
        r = await client.post("/auth/register", json={
            "email": email,
            "password": "testpassword123",
            "name": "Load Test User",
        })
        return r.status_code
    benchmark(register)


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_auth_login(client: AsyncClient, benchmark):
    """Benchmark auth login endpoint."""
    email = f"bench-{uuid.uuid4().hex[:8]}@test.com"
    # Register once
    await client.post("/auth/register", json={
        "email": email,
        "password": "testpassword123",
        "name": "Bench User",
    })
    
    async def login() -> int:
        r = await client.post("/auth/login", json={
            "email": email,
            "password": "testpassword123",
        })
        return r.status_code
    benchmark(login)


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_task_create(client: AsyncClient, benchmark):
    """Benchmark task creation."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    async def create() -> int:
        r = await client.post("/tasks", json={"prompt": "fix the login bug"}, headers=headers)
        return r.status_code
    benchmark(create)


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_task_list(client: AsyncClient, benchmark):
    """Benchmark listing tasks."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    async def list_tasks() -> int:
        r = await client.get("/tasks", headers=headers)
        return r.status_code
    benchmark(list_tasks)


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_task_detail(client: AsyncClient, benchmark):
    """Benchmark task detail query (heavy join)."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    # Create a task
    r = await client.post("/tasks", json={"prompt": "benchmark detail query"}, headers=headers)
    task_id = r.json()["id"]
    
    async def detail() -> int:
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        return r.status_code
    benchmark(detail)


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_task_cancel(client: AsyncClient, benchmark):
    """Benchmark task cancellation."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    # Create a task
    r = await client.post("/tasks", json={"prompt": "test cancel"}, headers=headers)
    task_id = r.json()["id"]
    
    async def cancel() -> int:
        r = await client.post(f"/tasks/{task_id}/cancel", headers=headers)
        return r.status_code
    benchmark(cancel)


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_task_lifecycle(client: AsyncClient, benchmark):
    """Full task CRUD cycle: create → detail → cancel."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    async def lifecycle() -> tuple:
        # Create
        r1 = await client.post("/tasks", json={"prompt": "full lifecycle test"}, headers=headers)
        task_id = r1.json()["id"]
        # Detail
        r2 = await client.get(f"/tasks/{task_id}", headers=headers)
        # Cancel
        r3 = await client.post(f"/tasks/{task_id}/cancel", headers=headers)
        return r1.status_code, r2.status_code, r3.status_code
    benchmark(lifecycle)


@pytest.mark.benchmark(min_rounds=100, group="load")
async def test_rate_limit_stress(client: AsyncClient, benchmark):
    """Rapid task creation to trigger rate limiting."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    results = []
    async def hammer() -> list:
        local_results = []
        for _ in range(50):
            r = await client.post("/tasks", json={"prompt": "rate limit test"}, headers=headers)
            local_results.append(r.status_code)
        return local_results
    benchmark(hammer)


@pytest.mark.benchmark(min_rounds=20, group="load")
async def test_concurrent_task_creation(client: AsyncClient, benchmark):
    """10 concurrent task creations."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    async def create_one() -> int:
        r = await client.post("/tasks", json={"prompt": "concurrent test"}, headers=headers)
        return r.status_code
    
    async def run_concurrent() -> list:
        tasks = [create_one() for _ in range(10)]
        return await asyncio.gather(*tasks)
    
    benchmark(run_concurrent)


@pytest.mark.benchmark(min_rounds=20, group="load")
async def test_concurrent_task_detail(client: AsyncClient, benchmark):
    """10 concurrent task detail queries."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    # Create a task
    r = await client.post("/tasks", json={"prompt": "concurrent detail test"}, headers=headers)
    task_id = r.json()["id"]
    
    async def detail_one() -> int:
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        return r.status_code
    
    async def run_concurrent() -> list:
        tasks = [detail_one() for _ in range(10)]
        return await asyncio.gather(*tasks)
    
    benchmark(run_concurrent)


@pytest.mark.benchmark(min_rounds=50, group="load")
async def test_approval_flow(client: AsyncClient, benchmark):
    """Approval request → approve flow."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    # Create task
    r = await client.post("/tasks", json={"prompt": "test approval flow"}, headers=headers)
    task_id = r.json()["id"]
    
    async def approve_flow() -> tuple:
        # Get pending approvals
        r1 = await client.get("/approvals/pending", headers=headers)
        approvals = r1.json()["items"]
        if not approvals:
            return (0, 0)
        approval_id = approvals[0]["id"]
        # Approve
        r2 = await client.post(
            f"/approvals/{approval_id}/approve",
            json={"note": "benchmark approve"},
            headers=headers,
        )
        return r1.status_code, r2.status_code
    benchmark(approve_flow)


@pytest.mark.benchmark(min_rounds=50, group="load")
async def test_sse_stream(client: AsyncClient, benchmark):
    """Benchmark SSE stream connection (non-live)."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    
    # Create a task
    r = await client.post("/tasks", json={"prompt": "test sse"}, headers=headers)
    task_id = r.json()["id"]
    
    async def stream() -> int:
        r = await client.get(
            f"/tasks/{task_id}/stream?live=false",
            headers=headers,
            timeout=10,
        )
        return r.status_code
    benchmark(stream)
