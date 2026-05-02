import asyncio

from httpx import AsyncClient


async def _wait_for_status(
    client: AsyncClient, headers: dict[str, str], task_id: str, desired: set[str]
) -> dict:
    for _ in range(300):
        res = await client.get(f"/tasks/{task_id}", headers=headers)
        assert res.status_code == 200
        data = res.json()
        if data["task"]["status"] in desired:
            return data
        await asyncio.sleep(0.02)
    raise AssertionError(f"Task {task_id} did not reach desired statuses: {desired}")


async def test_worker_emits_trace_details_and_file_changes(client: AsyncClient, login):
    headers = await login("trace-user")

    created = await client.post(
        "/tasks", headers=headers, json={"prompt": "Prepare and apply patch"}
    )
    assert created.status_code == 201
    task_id = created.json()["id"]

    waiting = await _wait_for_status(client, headers, task_id, {"waiting_approval"})
    waiting_logs = [event for event in waiting["events"] if event["type"] == "task.log"]
    assert waiting_logs, "Expected at least one task.log event"

    preview_event = next(
        (event for event in waiting_logs if event["data"].get("stage") == "patch_preview"),
        None,
    )
    assert preview_event is not None
    assert isinstance(preview_event["data"].get("file_changes"), list)
    assert len(preview_event["data"]["file_changes"]) >= 1

    pending = await client.get("/approvals/pending", headers=headers)
    assert pending.status_code == 200
    approval_id = pending.json()["items"][0]["id"]

    approved = await client.post(f"/approvals/{approval_id}/approve", headers=headers, json={})
    assert approved.status_code == 200

    completed = await _wait_for_status(client, headers, task_id, {"completed"})
    completed_logs = [event for event in completed["events"] if event["type"] == "task.log"]
    applied_event = next(
        (event for event in completed_logs if event["data"].get("stage") == "apply_changes"),
        None,
    )
    assert applied_event is not None
    assert isinstance(applied_event["data"].get("file_changes"), list)
    assert any(change.get("path") for change in applied_event["data"]["file_changes"])
