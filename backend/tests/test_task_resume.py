"""Resume: recovering tasks orphaned by a backend restart and continuing them from the phone."""

import asyncio
from uuid import UUID

from httpx import AsyncClient
from sqlalchemy import select

from app.core.config import Settings
from app.models.enums import TaskStatus
from app.models.task import Task
from workers.claude.output_parser import extract_session_id
from workers.common.context import RESUME_NOTE, compose_prompt


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


async def test_resume_cancelled_task_requeues_it(client: AsyncClient, login):
    headers = await login("resume-user")
    created = await client.post("/tasks", headers=headers, json={"prompt": "Long refactor"})
    task_id = created.json()["id"]
    await client.post(f"/tasks/{task_id}/cancel", headers=headers)

    resumed = await client.post(f"/tasks/{task_id}/resume", headers=headers)
    assert resumed.status_code == 200
    body = resumed.json()
    assert body["resume_count"] == 1
    assert body["error_message"] is None

    detail = await _wait_for_status(
        client, headers, task_id, {"queued", "starting", "running", "waiting_approval"}
    )
    assert "task.resumed" in [event["type"] for event in detail["events"]]


async def test_resume_rejects_completed_task(client: AsyncClient, login):
    headers = await login("resume-completed-user")
    created = await client.post("/tasks", headers=headers, json={"prompt": "Small fix"})
    task_id = created.json()["id"]
    await _wait_for_status(client, headers, task_id, {"waiting_approval"})
    approvals = (await client.get("/approvals/pending", headers=headers)).json()["items"]
    await client.post(f"/approvals/{approvals[0]['id']}/approve", headers=headers, json={})
    await _wait_for_status(client, headers, task_id, {"completed"})

    resumed = await client.post(f"/tasks/{task_id}/resume", headers=headers)
    assert resumed.status_code == 409


async def test_resume_other_users_task_is_not_found(client: AsyncClient, login):
    owner = await login("resume-owner")
    created = await client.post("/tasks", headers=owner, json={"prompt": "Mine"})
    task_id = created.json()["id"]
    await client.post(f"/tasks/{task_id}/cancel", headers=owner)

    stranger = await login("resume-stranger")
    resumed = await client.post(f"/tasks/{task_id}/resume", headers=stranger)
    assert resumed.status_code == 404


async def test_startup_recovery_marks_orphaned_tasks_interrupted(app, client: AsyncClient, login):
    headers = await login("recovery-user")
    created = await client.post("/tasks", headers=headers, json={"prompt": "Battery dies"})
    task_id = created.json()["id"]
    await client.post(f"/tasks/{task_id}/cancel", headers=headers)

    # Simulate the row a dead process leaves behind: still "running", nothing behind it.
    async with app.state.session_factory() as session:
        task = await session.scalar(select(Task).where(Task.id == UUID(task_id)))
        task.status = TaskStatus.RUNNING
        task.finished_at = None
        await session.commit()

    recovered = await app.state.services.task_service.recover_interrupted_tasks()
    assert recovered == 1

    detail = (await client.get(f"/tasks/{task_id}", headers=headers)).json()
    assert detail["task"]["status"] == "failed"
    assert detail["task"]["current_phase"] == "interrupted"
    issues = (await client.get(f"/tasks/{task_id}/issues", headers=headers)).json()["items"]
    assert any(issue["code"] == "WORKER_INTERRUPTED" for issue in issues)

    resumed = await client.post(f"/tasks/{task_id}/resume", headers=headers)
    assert resumed.status_code == 200


def test_extract_session_id_from_stream_json():
    assert extract_session_id({"type": "system", "subtype": "init", "session_id": "abc"}) == "abc"
    assert extract_session_id({"type": "assistant"}) is None


def test_compose_prompt_adds_resume_note_only_when_resuming():
    task = Task(prompt="Add tests")
    assert RESUME_NOTE not in compose_prompt(task, [], None, None, "tail")
    assert RESUME_NOTE in compose_prompt(task, [], None, None, "tail", is_resume=True)


def test_claude_args_reattach_to_session():
    from workers.claude.process_runner import ProcessRunner

    settings = Settings(
        DATABASE_URL="sqlite+aiosqlite:///:memory:",
        REDIS_URL=None,
        JWT_SECRET_KEY="test-secret",
        CLAUDE_COMMAND="claude",
    )
    runner = ProcessRunner(settings, None, None, asyncio.Lock(), None)  # type: ignore[arg-type]
    args = runner._base_args("go on", None, "sess-123")
    assert args[:3] == ["claude", "--resume", "sess-123"]
    assert "--resume" not in runner._base_args("fresh", None)
