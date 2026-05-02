import asyncio

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


async def test_task_lifecycle_with_approval(client: AsyncClient, login):
    headers = await login("task-user")

    created = await client.post(
        "/tasks", headers=headers, json={"prompt": "Refactor backend service"}
    )
    assert created.status_code == 201
    task = created.json()
    task_id = task["id"]

    waiting = await _wait_for_status(client, headers, task_id, {"waiting_approval"})
    assert waiting["task"]["status"] == "waiting_approval"

    pending = await client.get("/approvals/pending", headers=headers)
    assert pending.status_code == 200
    approvals = pending.json()["items"]
    assert len(approvals) == 1

    approval_id = approvals[0]["id"]
    approved = await client.post(f"/approvals/{approval_id}/approve", headers=headers, json={})
    assert approved.status_code == 200

    completed = await _wait_for_status(client, headers, task_id, {"completed"})
    assert completed["task"]["status"] == "completed"

    event_types = [event["type"] for event in completed["events"]]
    assert "task.created" in event_types
    assert "approval.requested" in event_types
    assert "approval.approved" in event_types
    assert "task.completed" in event_types


async def test_cancel_task_running_or_waiting_approval(client: AsyncClient, login):
    headers = await login("cancel-user")

    created = await client.post("/tasks", headers=headers, json={"prompt": "Run long task"})
    assert created.status_code == 201
    task_id = created.json()["id"]

    await _wait_for_status(client, headers, task_id, {"running", "waiting_approval"})

    cancelled = await client.post(f"/tasks/{task_id}/cancel", headers=headers)
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "cancelled"


async def test_cancel_queued_task(client: AsyncClient, login):
    headers = await login("cancel-queued-user")

    created = await client.post("/tasks", headers=headers, json={"prompt": "Cancel before run"})
    assert created.status_code == 201
    task_id = created.json()["id"]

    cancelled = await client.post(f"/tasks/{task_id}/cancel", headers=headers)
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "cancelled"
