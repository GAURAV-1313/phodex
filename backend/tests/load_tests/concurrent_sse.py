import asyncio

import pytest
from httpx import AsyncClient



@pytest.mark.benchmark(min_rounds=10, group="load")
async def test_concurrent_sse_5(client: AsyncClient, benchmark):
    """Test 5 simultaneous SSE connections to the same task."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    r = await client.post("/tasks", json={"prompt": "sse stress test"}, headers=headers)
    task_id = r.json()["id"]

    async def subscribe() -> int:
        r = await client.get(f"/tasks/{task_id}/stream?live=false", headers=headers, timeout=10)
        return r.status_code

    async def run() -> list:
        tasks = [subscribe() for _ in range(5)]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=10, group="load")
async def test_concurrent_sse_10(client: AsyncClient, benchmark):
    """Test 10 simultaneous SSE connections to the same task."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    r = await client.post("/tasks", json={"prompt": "sse stress test"}, headers=headers)
    task_id = r.json()["id"]

    async def subscribe() -> int:
        r = await client.get(f"/tasks/{task_id}/stream?live=false", headers=headers, timeout=10)
        return r.status_code

    async def run() -> list:
        tasks = [subscribe() for _ in range(10)]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=10, group="load")
async def test_concurrent_sse_20(client: AsyncClient, benchmark):
    """Test 20 simultaneous SSE connections to the same task."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    r = await client.post("/tasks", json={"prompt": "sse stress test"}, headers=headers)
    task_id = r.json()["id"]

    async def subscribe() -> int:
        r = await client.get(f"/tasks/{task_id}/stream?live=false", headers=headers, timeout=10)
        return r.status_code

    async def run() -> list:
        tasks = [subscribe() for _ in range(20)]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=10, group="load")
async def test_concurrent_sse_50(client: AsyncClient, benchmark):
    """Test 50 simultaneous SSE connections to the same task."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
    r = await client.post("/tasks", json={"prompt": "sse stress test"}, headers=headers)
    task_id = r.json()["id"]

    async def subscribe() -> int:
        r = await client.get(f"/tasks/{task_id}/stream?live=false", headers=headers, timeout=10)
        return r.status_code

    async def run() -> list:
        tasks = [subscribe() for _ in range(50)]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=10, group="load")
async def test_concurrent_sse_different_tasks(client: AsyncClient, benchmark):
    """Test SSE connections to different tasks simultaneously."""
    token = f"test-token|bench-user|bench@test.com|bench-user"
    r = await client.post("/auth/google", json={"id_token": token})
    headers = {"Authorization": f"Bearer {r.json()['access_token']}"}

    task_ids = []
    for i in range(20):
        r = await client.post("/tasks", json={"prompt": f"sse task {i}"}, headers=headers)
        if r.status_code == 201:
            task_ids.append(r.json()["id"])

    async def subscribe(task_id: str) -> int:
        r = await client.get(f"/tasks/{task_id}/stream?live=false", headers=headers, timeout=10)
        return r.status_code

    async def run() -> list:
        tasks = [subscribe(tid) for tid in task_ids]
        return await asyncio.gather(*tasks)

    benchmark(run)
