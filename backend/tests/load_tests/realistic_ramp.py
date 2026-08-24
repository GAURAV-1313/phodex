import asyncio

import pytest
from httpx import AsyncClient


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_ramp_1(client: AsyncClient, benchmark):
    """1 concurrent user doing real work."""
    async def user_work(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"ramp test by {sub}"}, headers=headers)
        task_id = r.json()["id"]
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        r = await client.get("/tasks", headers=headers)
        return r.status_code

    async def run() -> list:
        tasks = [user_work("user-0")]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_ramp_5(client: AsyncClient, benchmark):
    """5 concurrent users doing real work."""
    async def user_work(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"ramp test by {sub}"}, headers=headers)
        task_id = r.json()["id"]
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        r = await client.get("/tasks", headers=headers)
        return r.status_code

    async def run() -> list:
        users = [f"user-{i}" for i in range(5)]
        tasks = [user_work(u) for u in users]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_ramp_10(client: AsyncClient, benchmark):
    """10 concurrent users doing real work."""
    async def user_work(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"ramp test by {sub}"}, headers=headers)
        task_id = r.json()["id"]
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        r = await client.get("/tasks", headers=headers)
        return r.status_code

    async def run() -> list:
        users = [f"user-{i}" for i in range(10)]
        tasks = [user_work(u) for u in users]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_ramp_20(client: AsyncClient, benchmark):
    """20 concurrent users doing real work."""
    async def user_work(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"ramp test by {sub}"}, headers=headers)
        task_id = r.json()["id"]
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        r = await client.get("/tasks", headers=headers)
        return r.status_code

    async def run() -> list:
        users = [f"user-{i}" for i in range(20)]
        tasks = [user_work(u) for u in users]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_ramp_50(client: AsyncClient, benchmark):
    """50 concurrent users doing real work."""
    async def user_work(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"ramp test by {sub}"}, headers=headers)
        task_id = r.json()["id"]
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        r = await client.get("/tasks", headers=headers)
        return r.status_code

    async def run() -> list:
        users = [f"user-{i}" for i in range(50)]
        tasks = [user_work(u) for u in users]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_think_5(client: AsyncClient, benchmark):
    """5 users with think time between requests."""
    async def user_with_think_time(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"think time test {sub}"}, headers=headers)
        task_id = r.json()["id"]
        await asyncio.sleep(0.01)
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        return r.status_code

    async def run() -> list:
        users = [f"user-{i}" for i in range(5)]
        tasks = [user_with_think_time(u) for u in users]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_think_10(client: AsyncClient, benchmark):
    """10 users with think time between requests."""
    async def user_with_think_time(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"think time test {sub}"}, headers=headers)
        task_id = r.json()["id"]
        await asyncio.sleep(0.01)
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        return r.status_code

    async def run() -> list:
        users = [f"user-{i}" for i in range(10)]
        tasks = [user_with_think_time(u) for u in users]
        return await asyncio.gather(*tasks)

    benchmark(run)


@pytest.mark.benchmark(min_rounds=5, group="load")
async def test_think_20(client: AsyncClient, benchmark):
    """20 users with think time between requests."""
    async def user_with_think_time(sub: str) -> tuple:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        r = await client.post("/auth/google", json={"id_token": token})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await client.post("/tasks", json={"prompt": f"think time test {sub}"}, headers=headers)
        task_id = r.json()["id"]
        await asyncio.sleep(0.01)
        r = await client.get(f"/tasks/{task_id}", headers=headers)
        return r.status_code

    async def run() -> list:
        users = [f"user-{i}" for i in range(20)]
        tasks = [user_with_think_time(u) for u in users]
        return await asyncio.gather(*tasks)

    benchmark(run)
