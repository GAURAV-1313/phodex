import asyncio
import json

from httpx import AsyncClient


async def _wait_for_status(
    client: AsyncClient, headers: dict[str, str], task_id: str, desired: set[str]
) -> dict:
    for _ in range(200):
        res = await client.get(f"/tasks/{task_id}", headers=headers)
        assert res.status_code == 200
        data = res.json()
        if data["task"]["status"] in desired:
            return data
        await asyncio.sleep(0.02)
    raise AssertionError(f"Task {task_id} did not reach desired statuses: {desired}")


async def test_task_sse_stream_replays_and_streams(client: AsyncClient, login):
    headers = await login("stream-user")

    created = await client.post("/tasks", headers=headers, json={"prompt": "Stream me events"})
    assert created.status_code == 201
    task_id = created.json()["id"]
    await _wait_for_status(client, headers, task_id, {"waiting_approval"})

    seen_types: list[str] = []
    async with client.stream(
        "GET", f"/tasks/{task_id}/stream?live=false", headers=headers
    ) as response:
        assert response.status_code == 200

        async for line in response.aiter_lines():
            if not line.startswith("data: "):
                continue
            payload = json.loads(line.removeprefix("data: "))
            seen_types.append(payload["type"])

    assert "task.created" in seen_types
    assert "task.starting" in seen_types
    assert "task.running" in seen_types
    assert "approval.requested" in seen_types


async def test_stream_alias_tasks_endpoint_streams_events(client: AsyncClient, login):
    headers = await login("stream-alias-user")

    created = await client.post("/tasks", headers=headers, json={"prompt": "Stream alias events"})
    assert created.status_code == 201
    task_id = created.json()["id"]
    await _wait_for_status(client, headers, task_id, {"waiting_approval"})

    seen_types: list[str] = []
    async with client.stream(
        "GET", f"/stream/tasks/{task_id}?live=false", headers=headers
    ) as response:
        assert response.status_code == 200

        async for line in response.aiter_lines():
            if not line.startswith("data: "):
                continue
            payload = json.loads(line.removeprefix("data: "))
            seen_types.append(payload["type"])

    assert "task.created" in seen_types
    assert "task.starting" in seen_types
    assert "task.running" in seen_types
    assert "approval.requested" in seen_types
