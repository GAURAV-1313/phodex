"""WORKER_ENGINE=managed: tasks run as Anthropic Managed Agents sessions.

A scripted fake SDK client stands in for Anthropic: it records every call and
emits a canned event stream, so the mapping (session create -> stream -> tool
confirmation -> approval -> completion, follow-ups, cancel) is exercised end
to end with no network.
"""

import asyncio
import subprocess
import threading
from collections.abc import AsyncIterator, Awaitable, Callable
from types import SimpleNamespace
from typing import Any

import pytest
from cryptography.fernet import Fernet
from httpx import ASGITransport, AsyncClient

from app.core.config import Settings
from app.main import create_app


class FakeStream:
    """Blocking iterator fed from the test (the runner consumes it in a thread)."""

    def __init__(self, script: "FakeClient") -> None:
        self._script = script

    def __enter__(self) -> "FakeStream":
        return self

    def __exit__(self, *exc: object) -> None:
        return None

    def __iter__(self) -> "FakeStream":
        return self

    def __next__(self) -> Any:
        item = self._script.next_event()
        if item is StopIteration:
            raise StopIteration
        return item


class FakeClient:
    def __init__(self) -> None:
        self.created: list[dict[str, Any]] = []
        self.sent: list[dict[str, Any]] = []
        self._events: list[Any] = []
        self._cv = threading.Condition()
        self._closed = False
        events = SimpleNamespace(stream=self._stream, send=self._send, list=self._list)
        sessions = SimpleNamespace(create=self._create, events=events)
        self.beta = SimpleNamespace(sessions=sessions)

    # test-side controls -------------------------------------------------
    def emit(self, **event: Any) -> None:
        with self._cv:
            self._events.append(SimpleNamespace(**event))
            self._cv.notify_all()

    def close_stream(self) -> None:
        with self._cv:
            self._closed = True
            self._cv.notify_all()

    def next_event(self) -> Any:
        with self._cv:
            waited = 0.0
            while not self._events and not self._closed and waited < 30:
                self._cv.wait(timeout=0.5)
                waited += 0.5
            if self._events:
                return self._events.pop(0)
            return StopIteration

    def sent_types(self) -> list[str]:
        return [str(e["type"]) for call in self.sent for e in call["events"]]

    # sdk surface ----------------------------------------------------------
    def _create(self, **kwargs: Any) -> Any:
        self.created.append(kwargs)
        return SimpleNamespace(id="sesn_test_1", status="idle")

    def _send(self, *, session_id: str, events: list[dict[str, Any]]) -> Any:
        self.sent.append({"session_id": session_id, "events": events})
        return SimpleNamespace(ok=True)

    def _list(self, *, session_id: str) -> Any:
        return SimpleNamespace(data=[])

    def _stream(self, *, session_id: str) -> FakeStream:
        return FakeStream(self)


def _git(*args: str, cwd: str) -> None:
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True)


@pytest.fixture
def fake_client() -> FakeClient:
    return FakeClient()


@pytest.fixture
def bare_repo(tmp_path):
    """A seeded bare 'origin' the cloud runtime can clone (sync: git is blocking)."""
    bare = tmp_path / "origin.git"
    seed = tmp_path / "seed"
    seed.mkdir()
    _git("init", "-b", "main", cwd=str(seed))
    _git("config", "user.email", "seed@example.com", cwd=str(seed))
    _git("config", "user.name", "Seed", cwd=str(seed))
    (seed / "README.md").write_text("hi\n")
    _git("add", "-A", cwd=str(seed))
    _git("commit", "-m", "init", cwd=str(seed))
    subprocess.run(
        ["git", "init", "--bare", "-b", "main", str(bare)], check=True, capture_output=True
    )
    _git("remote", "add", "origin", str(bare), cwd=str(seed))
    _git("push", "-u", "origin", "main", cwd=str(seed))
    return bare


@pytest.fixture
async def managed_app(tmp_path, fake_client, bare_repo) -> AsyncIterator:
    bare = bare_repo
    settings = Settings(
        DATABASE_URL=f"sqlite+aiosqlite:///{tmp_path / 'managed.db'}",
        REDIS_URL=None,
        OTEL_EXPORTER_OTLP_ENDPOINT=None,
        AUTO_CREATE_SCHEMA=True,
        ALLOW_INSECURE_TEST_TOKENS=True,
        JWT_SECRET_KEY="test-secret",
        WORKER_ENGINE="managed",
        MANAGED_AGENT_ID="agent_test",
        MANAGED_ENVIRONMENT_ID="env_test",
        MANAGED_REQUIRE_INITIAL_APPROVAL=False,
        MANAGED_TIMEOUT_SECONDS=20,
        RUNTIME_MODE="cloud",
        WORKSPACES_ROOT=str(tmp_path / "workspaces"),
        ALLOW_LOCAL_GIT_URLS=True,
        GITHUB_DEFAULT_TOKEN="ghp_default_token",
        SETTINGS_ENCRYPTION_KEY=Fernet.generate_key().decode(),
        CLOUD_RUNNER_HEARTBEAT_SECONDS=3600,
    )
    application = create_app(settings)
    async with application.router.lifespan_context(application):
        # Swap the SDK client factory for the fake.
        engine = application.state.services.worker_dispatcher._worker_engine
        engine._runner._client_factory = lambda api_key: fake_client
        application.state.bare_repo = bare
        try:
            yield application
        finally:
            fake_client.close_stream()


@pytest.fixture
async def managed_client(managed_app) -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=managed_app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
async def managed_login(managed_client: AsyncClient) -> Callable[[str], Awaitable[dict[str, str]]]:
    async def _login(sub: str = "managed-user") -> dict[str, str]:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        response = await managed_client.post("/auth/google", json={"id_token": token})
        assert response.status_code == 200
        return {"Authorization": f"Bearer {response.json()['access_token']}"}

    return _login


async def _wait_for(
    client: AsyncClient, headers: dict[str, str], task_id: str, desired: set[str]
) -> dict:
    for _ in range(400):
        res = await client.get(f"/tasks/{task_id}", headers=headers)
        data = res.json()
        if data["task"]["status"] in desired:
            return data
        await asyncio.sleep(0.02)
    raise AssertionError(f"Task {task_id} never reached {desired}: {data['task']['status']}")


async def _wait_until(predicate: Callable[[], bool], max_wait: float = 5.0) -> None:
    for _ in range(int(max_wait / 0.02)):
        if predicate():
            return
        await asyncio.sleep(0.02)
    raise AssertionError("condition not met in time")


async def _github_context(client: AsyncClient, headers: dict[str, str], app) -> str:
    connected = await client.post(
        "/repos/github/connect", headers=headers, json={"url": str(app.state.bare_repo)}
    )
    assert connected.status_code == 201, connected.text
    selected = await client.post(
        f"/repos/{connected.json()['id']}/select", headers=headers, json={}
    )
    return selected.json()["project_context"]["id"]


async def test_managed_session_completes_task_and_records_messages(
    managed_client: AsyncClient, managed_login, managed_app, fake_client: FakeClient
):
    headers = await managed_login()
    context_id = await _github_context(managed_client, headers, managed_app)

    created = await managed_client.post(
        "/tasks",
        headers=headers,
        json={"prompt": "Add a CHANGELOG", "project_context_id": context_id},
    )
    task_id = created.json()["id"]

    await _wait_until(lambda: fake_client.sent_types() == ["user.message"])
    create_call = fake_client.created[0]
    assert create_call["agent"] == "agent_test"
    assert create_call["environment_id"] == "env_test"
    resource = create_call["resources"][0]
    assert resource["type"] == "github_repository"
    assert resource["authorization_token"] == "ghp_default_token"
    assert resource["checkout"] == {"type": "branch", "name": "main"}
    prompt = fake_client.sent[0]["events"][0]["content"][0]["text"]
    assert "Add a CHANGELOG" in prompt
    assert "/workspace" in prompt

    fake_client.emit(id="evt_1", type="session.status_running")
    fake_client.emit(id="evt_2", type="agent.thinking")
    fake_client.emit(
        id="evt_3",
        type="agent.message",
        content=[SimpleNamespace(type="text", text="Added CHANGELOG.md and pushed.")],
    )
    fake_client.emit(id="evt_4", type="session.status_idle", stop_reason="end_turn")

    detail = await _wait_for(managed_client, headers, task_id, {"completed", "failed"})
    assert detail["task"]["status"] == "completed"
    assert detail["task"]["final_summary"] == "Added CHANGELOG.md and pushed."
    assistant = [m for m in detail["messages"] if m["role"] == "assistant"]
    assert assistant and assistant[-1]["content"] == "Added CHANGELOG.md and pushed."
    types = [e["type"] for e in detail["events"]]
    assert "task.completed" in types
    fake_client.close_stream()


async def test_tool_confirmation_maps_to_phone_approval(
    managed_client: AsyncClient, managed_login, managed_app, fake_client: FakeClient
):
    headers = await managed_login("approver")
    context_id = await _github_context(managed_client, headers, managed_app)
    created = await managed_client.post(
        "/tasks",
        headers=headers,
        json={"prompt": "Run the tests", "project_context_id": context_id},
    )
    task_id = created.json()["id"]
    await _wait_until(lambda: fake_client.sent_types() == ["user.message"])

    fake_client.emit(
        id="tool_1", type="agent.tool_use", name="bash", input={"command": "pytest -q"}
    )
    fake_client.emit(id="idle_1", type="session.status_idle", stop_reason="requires_action")

    waiting = await _wait_for(managed_client, headers, task_id, {"waiting_approval"})
    approval = waiting["approvals"][-1]
    assert approval["kind"] == "tool_use"
    assert approval["payload_json"]["tool"] == "bash"
    assert approval["payload_json"]["input"] == {"command": "pytest -q"}

    approved = await managed_client.post(
        f"/approvals/{approval['id']}/approve", headers=headers, json={}
    )
    assert approved.status_code == 200
    await _wait_until(lambda: "user.tool_confirmation" in fake_client.sent_types())
    confirmation = fake_client.sent[-1]["events"][0]
    assert confirmation == {
        "type": "user.tool_confirmation",
        "tool_use_id": "tool_1",
        "result": "allow",
    }
    await _wait_for(managed_client, headers, task_id, {"running"})

    fake_client.emit(
        id="res_1",
        type="agent.tool_result",
        content=[SimpleNamespace(type="text", text="42 passed")],
    )
    fake_client.emit(
        id="msg_1",
        type="agent.message",
        content=[SimpleNamespace(type="text", text="All tests pass.")],
    )
    fake_client.emit(id="idle_2", type="session.status_idle", stop_reason="end_turn")
    detail = await _wait_for(managed_client, headers, task_id, {"completed", "failed"})
    assert detail["task"]["status"] == "completed"
    fake_client.close_stream()


async def test_rejected_tool_confirmation_denies_and_interrupts(
    managed_client: AsyncClient, managed_login, managed_app, fake_client: FakeClient
):
    headers = await managed_login("rejecter")
    context_id = await _github_context(managed_client, headers, managed_app)
    created = await managed_client.post(
        "/tasks", headers=headers, json={"prompt": "rm -rf", "project_context_id": context_id}
    )
    task_id = created.json()["id"]
    await _wait_until(lambda: fake_client.sent_types() == ["user.message"])
    fake_client.emit(id="tool_9", type="agent.tool_use", name="bash", input={"command": "rm -rf /"})
    fake_client.emit(id="idle_9", type="session.status_idle", stop_reason="requires_action")
    waiting = await _wait_for(managed_client, headers, task_id, {"waiting_approval"})

    rejected = await managed_client.post(
        f"/approvals/{waiting['approvals'][-1]['id']}/reject", headers=headers, json={}
    )
    assert rejected.status_code == 200
    await _wait_until(lambda: "user.interrupt" in fake_client.sent_types())
    types = fake_client.sent_types()
    deny = next(
        e
        for call in fake_client.sent
        for e in call["events"]
        if e["type"] == "user.tool_confirmation"
    )
    assert deny["result"] == "deny"
    assert types.index("user.tool_confirmation") < types.index("user.interrupt")
    await _wait_for(managed_client, headers, task_id, {"failed"})
    fake_client.close_stream()


async def test_follow_up_and_cancel_are_forwarded_to_the_session(
    managed_client: AsyncClient, managed_login, managed_app, fake_client: FakeClient
):
    headers = await managed_login("chatter")
    context_id = await _github_context(managed_client, headers, managed_app)
    created = await managed_client.post(
        "/tasks", headers=headers, json={"prompt": "Start", "project_context_id": context_id}
    )
    task_id = created.json()["id"]
    await _wait_until(lambda: fake_client.sent_types() == ["user.message"])
    fake_client.emit(id="run_1", type="session.status_running")
    await _wait_for(managed_client, headers, task_id, {"running"})

    reply = await managed_client.post(
        f"/tasks/{task_id}/reply", headers=headers, json={"content": "Also update the docs"}
    )
    assert reply.status_code in (200, 201)
    await _wait_until(lambda: fake_client.sent_types().count("user.message") == 2)
    assert fake_client.sent[-1]["events"][0]["content"][0]["text"] == "Also update the docs"

    cancelled = await managed_client.post(f"/tasks/{task_id}/cancel", headers=headers)
    assert cancelled.status_code == 200
    await _wait_until(lambda: "user.interrupt" in fake_client.sent_types())
    await _wait_for(managed_client, headers, task_id, {"cancelled"})
    fake_client.close_stream()


async def test_task_without_github_repo_fails_clearly(
    managed_client: AsyncClient, managed_login, fake_client: FakeClient
):
    headers = await managed_login("no-repo")
    created = await managed_client.post("/tasks", headers=headers, json={"prompt": "No repo"})
    task_id = created.json()["id"]
    await _wait_for(managed_client, headers, task_id, {"failed"})
    issues = (await managed_client.get(f"/tasks/{task_id}/issues", headers=headers)).json()
    codes = {issue["code"] for issue in issues["items"]}
    assert "MANAGED_REPO_REQUIRED" in codes
    assert fake_client.created == []


async def test_session_error_fails_task(
    managed_client: AsyncClient, managed_login, managed_app, fake_client: FakeClient
):
    headers = await managed_login("erroring")
    context_id = await _github_context(managed_client, headers, managed_app)
    created = await managed_client.post(
        "/tasks", headers=headers, json={"prompt": "Boom", "project_context_id": context_id}
    )
    task_id = created.json()["id"]
    await _wait_until(lambda: fake_client.sent_types() == ["user.message"])
    fake_client.emit(id="err_1", type="session.error", message="sandbox exploded")
    detail = await _wait_for(managed_client, headers, task_id, {"failed"})
    assert detail["task"]["error_message"] == "sandbox exploded"
    fake_client.close_stream()


def test_managed_engine_is_a_supported_worker_engine():
    settings = Settings(WORKER_ENGINE="managed", DATABASE_URL="sqlite+aiosqlite:///:memory:")
    assert settings.worker_engine == "managed"
    with pytest.raises(ValueError):
        Settings(WORKER_ENGINE="nope")
