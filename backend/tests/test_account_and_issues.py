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


async def test_account_usage_limits_and_task_issues(client: AsyncClient, login):
    headers = await login("insights-user")

    created = await client.post("/tasks", headers=headers, json={"prompt": "Need visibility"})
    assert created.status_code == 201
    task_id = created.json()["id"]

    waiting = await _wait_for_status(client, headers, task_id, {"waiting_approval"})
    assert waiting["task"]["status"] == "waiting_approval"

    me = await client.get("/account/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["user"]["google_sub"] == "insights-user"

    usage = await client.get("/account/usage", headers=headers)
    assert usage.status_code == 200
    assert usage.json()["total_tasks"] >= 1

    limits = await client.get("/account/limits", headers=headers)
    assert limits.status_code == 200
    assert "current_concurrent_tasks" in limits.json()

    pending = await client.get("/approvals/pending", headers=headers)
    approval_id = pending.json()["items"][0]["id"]

    rejected = await client.post(
        f"/approvals/{approval_id}/reject", headers=headers, json={"note": "No"}
    )
    assert rejected.status_code == 200

    failed = await _wait_for_status(client, headers, task_id, {"failed"})
    assert failed["task"]["status"] == "failed"

    issues = await client.get(f"/tasks/{task_id}/issues", headers=headers)
    assert issues.status_code == 200
    issue_codes = [item.get("code") for item in issues.json()["items"]]
    assert "APPROVAL_REJECTED" in issue_codes


async def test_account_me_reports_device_online_status(client: AsyncClient, login):
    headers = await login("device-status-user")

    # No device registered yet — must not crash, must report offline.
    before = await client.get("/account/me", headers=headers)
    assert before.status_code == 200
    assert before.json()["device_online"] is False
    assert before.json()["device_last_seen_at"] is None

    registered = await client.post(
        "/devices/register",
        headers=headers,
        json={"name": "Test Device", "platform": "macos", "agent_version": "0.1.0"},
    )
    assert registered.status_code == 201

    # A device that just checked in (last_seen_at set moments ago by the
    # register call) must be reported online, and comparing its stored
    # timestamp against "now" must not raise (regression: SQLite doesn't
    # reliably round-trip tzinfo, so this comparison previously crashed
    # with "can't subtract offset-naive and offset-aware datetimes").
    after = await client.get("/account/me", headers=headers)
    assert after.status_code == 200
    body = after.json()
    assert body["device_online"] is True
    assert body["device_last_seen_at"] is not None
