import asyncio
import os
import stat
import uuid
from collections.abc import AsyncIterator, Awaitable, Callable

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.config import Settings
from app.main import create_app


def _write_stub_runtime(script_path) -> None:
    script_path.write_text(
        (
            "#!/usr/bin/env python3\n"
            "import json\n"
            "\n"
            "print(json.dumps({'type': 'system', 'subtype': 'init', 'session_id': 'stub'}), flush=True)\n"
            "print(json.dumps({\n"
            "  'type': 'assistant',\n"
            "  'message': {'role': 'assistant', 'content': [\n"
            "    {'type': 'tool_use', 'name': 'Edit', 'input': {'file_path': 'app/main.py'}}\n"
            "  ]},\n"
            "}), flush=True)\n"
            "print(json.dumps({\n"
            "  'type': 'assistant',\n"
            "  'message': {'role': 'assistant', 'content': [\n"
            "    {'type': 'text', 'text': 'Applied backend updates from Claude runtime.'}\n"
            "  ]},\n"
            "}), flush=True)\n"
            "print(json.dumps({\n"
            "  'type': 'result',\n"
            "  'subtype': 'success',\n"
            "  'is_error': False,\n"
            "  'result': 'Claude runtime completed successfully.',\n"
            "}), flush=True)\n"
        ),
        encoding="utf-8",
    )
    script_path.chmod(script_path.stat().st_mode | stat.S_IEXEC)


@pytest.fixture
async def claude_app(tmp_path) -> AsyncIterator:
    db_file = tmp_path / f"claude-worker-{uuid.uuid4()}.db"
    stub_script = tmp_path / "claude_stub_runtime.py"
    _write_stub_runtime(stub_script)

    settings = Settings(
        DATABASE_URL=f"sqlite+aiosqlite:///{db_file}",
        REDIS_URL=None,
        OTEL_EXPORTER_OTLP_ENDPOINT=None,
        AUTO_CREATE_SCHEMA=True,
        ALLOW_INSECURE_TEST_TOKENS=True,
        JWT_SECRET_KEY="test-secret",
        WORKER_ENGINE="claude",
        CLAUDE_COMMAND=str(stub_script),
        CLAUDE_TIMEOUT_SECONDS=10.0,
        CLAUDE_REQUIRE_INITIAL_APPROVAL=True,
        CLAUDE_DEFAULT_WORKDIR=str(tmp_path),
    )
    application = create_app(settings)
    async with application.router.lifespan_context(application):
        yield application


@pytest.fixture
async def claude_client(claude_app) -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=claude_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
async def claude_login(claude_client: AsyncClient) -> Callable[[str], Awaitable[dict[str, str]]]:
    async def _login(sub: str = "claude-user") -> dict[str, str]:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        response = await claude_client.post("/auth/google", json={"id_token": token})
        assert response.status_code == 200
        access_token = response.json()["access_token"]
        return {"Authorization": f"Bearer {access_token}"}

    return _login


async def _wait_for_status(
    client: AsyncClient, headers: dict[str, str], task_id: str, desired: set[str]
) -> dict:
    for _ in range(400):
        response = await client.get(f"/tasks/{task_id}", headers=headers)
        assert response.status_code == 200
        payload = response.json()
        if payload["task"]["status"] in desired:
            return payload
        await asyncio.sleep(0.02)
    raise AssertionError(f"Task {task_id} did not reach desired status in {desired}")


async def test_claude_worker_executes_runtime_after_approval(
    claude_client: AsyncClient, claude_login
):
    if os.name != "posix":
        pytest.skip("stub runtime relies on a POSIX shebang script")

    headers = await claude_login("claude-runtime-user")

    created = await claude_client.post(
        "/tasks",
        headers=headers,
        json={"prompt": "Implement real worker and summarize changes"},
    )
    assert created.status_code == 201
    task_id = created.json()["id"]

    waiting = await _wait_for_status(claude_client, headers, task_id, {"waiting_approval"})
    assert waiting["task"]["status"] == "waiting_approval"

    pending = await claude_client.get("/approvals/pending", headers=headers)
    assert pending.status_code == 200
    approval_id = pending.json()["items"][0]["id"]

    approved = await claude_client.post(
        f"/approvals/{approval_id}/approve", headers=headers, json={}
    )
    assert approved.status_code == 200

    completed = await _wait_for_status(claude_client, headers, task_id, {"completed"})
    assert completed["task"]["status"] == "completed"
    assert completed["task"]["final_summary"] == "Claude runtime completed successfully."

    log_events = [event for event in completed["events"] if event["type"] == "task.log"]
    assert any("Edit: app/main.py" in event["data"].get("message", "") for event in log_events)

    assistant_messages = [
        message["content"] for message in completed["messages"] if message["role"] == "assistant"
    ]
    assert any(
        "Applied backend updates from Claude runtime." in content
        for content in assistant_messages
    )
