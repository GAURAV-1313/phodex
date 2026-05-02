import asyncio
import sys
import uuid
from collections.abc import AsyncIterator, Awaitable, Callable

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.config import Settings
from app.main import create_app


def _write_stub_runtime(script_path) -> None:
    script_path.write_text(
        (
            "import json\n"
            "import sys\n"
            "\n"
            "prompt = sys.stdin.read()\n"
            "print(json.dumps({'event_type': 'task.progress', 'data': {'message': 'Stub runtime started'}}), flush=True)\n"
            "print(json.dumps({'message': 'Stub runtime received prompt', 'prompt_size': len(prompt)}), flush=True)\n"
            "print(json.dumps({'message': 'Stub runtime generated patch', 'file_changes': [\n"
            "  {'action': 'modified', 'path': 'app/main.py', 'added': 11, 'removed': 3}\n"
            "]}), flush=True)\n"
            "print(json.dumps({'assistant_message': 'Applied backend updates from Codex runtime.'}), flush=True)\n"
            "print(json.dumps({'type': 'response.output_item.done', 'item': {'role': 'assistant', 'content': [\n"
            "  {'type': 'output_text', 'text': 'Visible Codex final answer.'}\n"
            "]}}), flush=True)\n"
            "print(json.dumps({'final_summary': 'Codex runtime completed successfully.'}), flush=True)\n"
        ),
        encoding="utf-8",
    )


@pytest.fixture
async def codex_app(tmp_path) -> AsyncIterator:
    db_file = tmp_path / f"codex-worker-{uuid.uuid4()}.db"
    stub_script = tmp_path / "codex_stub_runtime.py"
    _write_stub_runtime(stub_script)

    settings = Settings(
        DATABASE_URL=f"sqlite+aiosqlite:///{db_file}",
        AUTO_CREATE_SCHEMA=True,
        ALLOW_INSECURE_TEST_TOKENS=True,
        JWT_SECRET_KEY="test-secret",
        WORKER_ENGINE="codex",
        CODEX_COMMAND=sys.executable,
        CODEX_ARGS=f"-u {stub_script}",
        CODEX_PROMPT_STDIN=True,
        CODEX_TIMEOUT_SECONDS=10.0,
        CODEX_REQUIRE_INITIAL_APPROVAL=True,
        CODEX_DEFAULT_WORKDIR=str(tmp_path),
    )
    application = create_app(settings)
    async with application.router.lifespan_context(application):
        yield application


@pytest.fixture
async def codex_client(codex_app) -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=codex_app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
async def codex_login(codex_client: AsyncClient) -> Callable[[str], Awaitable[dict[str, str]]]:
    async def _login(sub: str = "codex-user") -> dict[str, str]:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        response = await codex_client.post("/auth/google", json={"id_token": token})
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


async def test_codex_worker_executes_runtime_after_approval(codex_client: AsyncClient, codex_login):
    headers = await codex_login("codex-runtime-user")

    created = await codex_client.post(
        "/tasks",
        headers=headers,
        json={"prompt": "Implement real worker and summarize changes"},
    )
    assert created.status_code == 201
    task_id = created.json()["id"]

    waiting = await _wait_for_status(codex_client, headers, task_id, {"waiting_approval"})
    assert waiting["task"]["status"] == "waiting_approval"

    pending = await codex_client.get("/approvals/pending", headers=headers)
    assert pending.status_code == 200
    approval_id = pending.json()["items"][0]["id"]

    approved = await codex_client.post(
        f"/approvals/{approval_id}/approve", headers=headers, json={}
    )
    assert approved.status_code == 200

    completed = await _wait_for_status(codex_client, headers, task_id, {"completed"})
    assert completed["task"]["status"] == "completed"
    assert completed["task"]["final_summary"] == "Codex runtime completed successfully."

    log_events = [event for event in completed["events"] if event["type"] == "task.log"]
    assert any(event["data"].get("file_changes") for event in log_events)

    assistant_messages = [
        message["content"] for message in completed["messages"] if message["role"] == "assistant"
    ]
    assert any(
        "Applied backend updates from Codex runtime." in content for content in assistant_messages
    )
    assert any("Visible Codex final answer." in content for content in assistant_messages)
