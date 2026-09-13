"""Cloud runtime: GitHub-style repositories cloned and executed on the server.

Uses a local bare git repository as the "GitHub" remote (ALLOW_LOCAL_GIT_URLS)
so the clone -> task -> commit -> push loop is exercised end to end without
network access or real credentials.
"""

import asyncio
import shutil
import subprocess
import uuid
from collections.abc import AsyncIterator, Awaitable, Callable
from pathlib import Path

import pytest
from cryptography.fernet import Fernet
from httpx import ASGITransport, AsyncClient

from app.core.config import Settings
from app.main import create_app
from app.services.cloud_repo_service import parse_repo_source, scrub_secrets

DEMO_EMAIL = "demo@phodex.dev"


def _git(*args: str, cwd: str) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True)
    return result.stdout


@pytest.fixture
def seeded_remote(tmp_path) -> tuple[Path, Path]:
    """A bare 'origin' seeded with one commit on main, plus the seed checkout."""
    seed = tmp_path / "seed"
    seed.mkdir()
    _git("init", "-b", "main", cwd=str(seed))
    _git("config", "user.email", "seed@example.com", cwd=str(seed))
    _git("config", "user.name", "Seed", cwd=str(seed))
    (seed / "README.md").write_text("hello from origin\n")
    _git("add", "-A", cwd=str(seed))
    _git("commit", "-m", "initial commit", cwd=str(seed))
    bare = tmp_path / "origin.git"
    subprocess.run(
        ["git", "init", "--bare", "-b", "main", str(bare)], check=True, capture_output=True
    )
    _git("remote", "add", "origin", str(bare), cwd=str(seed))
    _git("push", "-u", "origin", "main", cwd=str(seed))
    return bare, seed


@pytest.fixture
async def cloud_app(tmp_path, seeded_remote) -> AsyncIterator:
    bare, _ = seeded_remote
    db_file = tmp_path / f"cloud-{uuid.uuid4()}.db"
    settings = Settings(
        DATABASE_URL=f"sqlite+aiosqlite:///{db_file}",
        REDIS_URL=None,
        OTEL_EXPORTER_OTLP_ENDPOINT=None,
        AUTO_CREATE_SCHEMA=True,
        ALLOW_INSECURE_TEST_TOKENS=True,
        JWT_SECRET_KEY="test-secret",
        WORKER_ENGINE="fake",
        FAKE_WORKER_STEP_DELAY_SECONDS=0.01,
        RUNTIME_MODE="cloud",
        WORKSPACES_ROOT=str(tmp_path / "workspaces"),
        ALLOW_LOCAL_GIT_URLS=True,
        SETTINGS_ENCRYPTION_KEY=Fernet.generate_key().decode(),
        DEMO_ACCOUNT_EMAIL=DEMO_EMAIL,
        DEMO_ACCOUNT_PASSWORD="demo-password-123",
        DEMO_REPO_ALLOWLIST=str(bare),
        CLOUD_RUNNER_HEARTBEAT_SECONDS=3600,
    )
    application = create_app(settings)
    async with application.router.lifespan_context(application):
        yield application


@pytest.fixture
async def cloud_client(cloud_app) -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=cloud_app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
async def cloud_login(cloud_client: AsyncClient) -> Callable[[str], Awaitable[dict[str, str]]]:
    async def _login(sub: str = "cloud-user") -> dict[str, str]:
        token = f"test-token|{sub}|{sub}@example.com|{sub}"
        response = await cloud_client.post("/auth/google", json={"id_token": token})
        assert response.status_code == 200
        return {"Authorization": f"Bearer {response.json()['access_token']}"}

    return _login


async def _wait_for_task_status(
    client: AsyncClient, headers: dict[str, str], task_id: str, desired: set[str]
) -> dict:
    for _ in range(300):
        res = await client.get(f"/tasks/{task_id}", headers=headers)
        assert res.status_code == 200
        data = res.json()
        if data["task"]["status"] in desired:
            return data
        await asyncio.sleep(0.02)
    raise AssertionError(f"Task {task_id} did not reach {desired}")


async def _connect_and_select(
    client: AsyncClient, headers: dict[str, str], url: str
) -> tuple[dict, str]:
    connected = await client.post(
        "/repos/github/connect", headers=headers, json={"url": url, "branch": "main"}
    )
    assert connected.status_code == 201, connected.text
    repo = connected.json()
    selected = await client.post(f"/repos/{repo['id']}/select", headers=headers, json={})
    assert selected.status_code == 200
    return repo, selected.json()["project_context"]["id"]


async def _run_task_to_completion(
    client: AsyncClient, headers: dict[str, str], context_id: str
) -> str:
    created = await client.post(
        "/tasks", headers=headers, json={"prompt": "Do the thing", "project_context_id": context_id}
    )
    assert created.status_code == 201
    task_id = created.json()["id"]
    waiting = await _wait_for_task_status(client, headers, task_id, {"waiting_approval"})
    approval_id = waiting["approvals"][0]["id"]
    approved = await client.post(f"/approvals/{approval_id}/approve", headers=headers, json={})
    assert approved.status_code == 200
    await _wait_for_task_status(client, headers, task_id, {"completed"})
    return task_id


# --------------------------------------------------------------------- units


def test_parse_repo_source_accepts_common_github_forms():
    for raw in (
        "https://github.com/octo/phodex",
        "https://github.com/octo/phodex.git",
        "http://www.github.com/octo/phodex/",
        "github.com/octo/phodex",
        "octo/phodex",
    ):
        source = parse_repo_source(raw)
        assert source.url == "https://github.com/octo/phodex.git", raw
        assert (source.owner, source.name) == ("octo", "phodex")


def test_parse_repo_source_rejects_junk_and_local_paths_by_default(tmp_path):
    for raw in ("", "not a url", "https://gitlab.com/a/b", "ftp://github.com/a/b"):
        with pytest.raises(ValueError):
            parse_repo_source(raw)
    with pytest.raises(ValueError):
        parse_repo_source(str(tmp_path))
    local = parse_repo_source(str(tmp_path), allow_local=True)
    assert local.owner == "local"
    assert local.name == tmp_path.name


def test_scrub_secrets_masks_tokens():
    line = "fatal: https://x-access-token:ghp_secret123@github.com/a/b rejected"
    assert "ghp_secret123" not in scrub_secrets(line, ["ghp_secret123", ""])
    assert scrub_secrets("clean", []) == "clean"


# ----------------------------------------------------------------- endpoints


async def test_public_runtime_info_requires_no_auth(cloud_client: AsyncClient):
    response = await cloud_client.get("/runtime/public")
    assert response.status_code == 200
    body = response.json()
    assert body["mode"] == "cloud"
    assert body["demo_available"] is True
    assert body["runner_name"] == "Phodex Cloud"

    root = await cloud_client.get("/")
    assert root.json()["runtime_mode"] == "cloud"


async def test_runtime_info_registers_cloud_runner_device(cloud_client: AsyncClient, cloud_login):
    headers = await cloud_login("runner-user")
    info = await cloud_client.get("/runtime", headers=headers)
    assert info.status_code == 200
    body = info.json()
    assert body["mode"] == "cloud"
    assert body["runner"]["name"] == "Phodex Cloud"
    assert body["runner"]["platform"] == "cloud"
    assert body["runner"]["status"] == "online"
    assert body["has_github_token"] is False

    devices = await cloud_client.get("/devices", headers=headers)
    assert [d["platform"] for d in devices.json()["items"]] == ["cloud"]

    # Calling it again must reuse the same synthetic device, not add another.
    await cloud_client.get("/runtime", headers=headers)
    devices = await cloud_client.get("/devices", headers=headers)
    assert len(devices.json()["items"]) == 1


async def test_connect_clones_repo_into_workspace_and_lists_it(
    cloud_client: AsyncClient, cloud_login, cloud_app, seeded_remote
):
    bare, _ = seeded_remote
    headers = await cloud_login("connect-user")
    repo, _context_id = await _connect_and_select(cloud_client, headers, str(bare))

    assert repo["device_name"] == "Phodex Cloud"
    assert repo["current_branch"] == "main"
    assert repo["metadata_json"]["source"] == "github"
    workdir = Path(repo["git_root"])
    assert workdir.is_relative_to(Path(cloud_app.state.services.settings.workspaces_root))
    assert (workdir / "README.md").read_text() == "hello from origin\n"

    listed = await cloud_client.get("/repos", headers=headers)
    assert [r["name"] for r in listed.json()["items"]] == [repo["name"]]

    current = await cloud_client.get("/repos/context/current", headers=headers)
    context = current.json()["project_context"]
    assert context["source_type"] == "github"
    assert context["repo_url"] == str(bare.resolve())

    # Reconnecting the same repo refreshes rather than duplicating it.
    again = await cloud_client.post(
        "/repos/github/connect", headers=headers, json={"url": str(bare)}
    )
    assert again.status_code == 201
    assert again.json()["id"] == repo["id"]
    listed = await cloud_client.get("/repos", headers=headers)
    assert len(listed.json()["items"]) == 1


async def test_connect_rejects_invalid_urls(cloud_client: AsyncClient, cloud_login):
    headers = await cloud_login("bad-url-user")
    response = await cloud_client.post(
        "/repos/github/connect", headers=headers, json={"url": "definitely not a repo"}
    )
    assert response.status_code == 409
    assert "github.com/owner/repo" in response.json()["detail"]


async def test_cloud_task_commit_and_push_reaches_remote(
    cloud_client: AsyncClient, cloud_login, seeded_remote
):
    bare, _ = seeded_remote
    headers = await cloud_login("push-user")
    repo, context_id = await _connect_and_select(cloud_client, headers, str(bare))
    task_id = await _run_task_to_completion(cloud_client, headers, context_id)

    # Simulate the worker having edited the cloud workspace.
    (Path(repo["git_root"]) / "feature.txt").write_text("written in the cloud\n")

    prepared = await cloud_client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    assert prepared.status_code == 200
    assert "feature.txt" in prepared.json()["status_output"]
    op_id = prepared.json()["id"]

    confirmed = await cloud_client.post(
        f"/tasks/{task_id}/git/{op_id}/confirm",
        headers=headers,
        json={"commit_message": "Cloud commit"},
    )
    assert confirmed.status_code == 200, confirmed.text
    assert confirmed.json()["status"] == "completed"
    assert confirmed.json()["pushed_branch"] == "main"

    remote_log = _git("log", "-1", "--pretty=%s%n%an", "main", cwd=str(bare))
    assert remote_log.splitlines() == ["Cloud commit", "push-user"]


async def test_discard_resets_cloud_workspace(
    cloud_client: AsyncClient, cloud_login, seeded_remote
):
    bare, _ = seeded_remote
    headers = await cloud_login("discard-user")
    repo, context_id = await _connect_and_select(cloud_client, headers, str(bare))
    task_id = await _run_task_to_completion(cloud_client, headers, context_id)

    workdir = Path(repo["git_root"])
    (workdir / "README.md").write_text("modified\n")
    (workdir / "scratch.txt").write_text("untracked\n")

    prepared = await cloud_client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    op_id = prepared.json()["id"]
    discarded = await cloud_client.post(f"/tasks/{task_id}/git/{op_id}/discard", headers=headers)
    assert discarded.status_code == 200
    assert discarded.json()["status"] == "rejected"
    assert (workdir / "README.md").read_text() == "hello from origin\n"
    assert not (workdir / "scratch.txt").exists()

    events = (await cloud_client.get(f"/tasks/{task_id}/events", headers=headers)).json()
    discard_events = [e for e in events["items"] if e["type"] == "git.discarded"]
    assert discard_events and discard_events[-1]["data"]["workspace_reset"] is True


async def test_prepare_for_task_reclones_a_missing_workspace_and_fast_forwards(
    cloud_client: AsyncClient, cloud_login, cloud_app, seeded_remote
):
    bare, seed = seeded_remote
    headers = await cloud_login("reclone-user")
    repo, _ = await _connect_and_select(cloud_client, headers, str(bare))
    workdir = Path(repo["git_root"])

    # New commit lands on origin after the clone.
    (seed / "NEW.md").write_text("later\n")
    _git("add", "-A", cwd=str(seed))
    _git("commit", "-m", "second", cwd=str(seed))
    _git("push", cwd=str(seed))

    service = cloud_app.state.services.cloud_repo_service
    me = (await cloud_client.get("/auth/me", headers=headers)).json()["id"]

    await service.prepare_for_task(uuid.UUID(me), str(workdir))
    assert (workdir / "NEW.md").exists(), "clean workspace should fast-forward"

    await asyncio.to_thread(shutil.rmtree, workdir)
    await service.prepare_for_task(uuid.UUID(me), str(workdir))
    assert (workdir / "README.md").exists(), "lost workspace should be re-cloned"

    # A dirty tree is left alone (never silently reset before a task).
    (workdir / "README.md").write_text("in progress\n")
    (seed / "THIRD.md").write_text("even later\n")
    _git("add", "-A", cwd=str(seed))
    _git("commit", "-m", "third", cwd=str(seed))
    _git("push", cwd=str(seed))
    await service.prepare_for_task(uuid.UUID(me), str(workdir))
    assert (workdir / "README.md").read_text() == "in progress\n"
    assert not (workdir / "THIRD.md").exists()


async def test_github_credentials_are_stored_encrypted_and_reported(
    cloud_client: AsyncClient, cloud_login, cloud_app
):
    headers = await cloud_login("token-user")
    saved = await cloud_client.put(
        "/repos/github/credentials", headers=headers, json={"token": "ghp_example_token"}
    )
    assert saved.status_code == 200
    assert saved.json()["has_github_token"] is True

    status = await cloud_client.get("/account/ai-settings", headers=headers)
    assert status.json()["has_github_token"] is True
    info = await cloud_client.get("/runtime", headers=headers)
    assert info.json()["has_github_token"] is True

    service = cloud_app.state.services.user_ai_settings_service
    me = (await cloud_client.get("/auth/me", headers=headers)).json()["id"]
    row = await service.get_decrypted(uuid.UUID(me))
    assert row is not None and row.github_token_encrypted != "ghp_example_token"
    assert await service.get_github_token(uuid.UUID(me)) == "ghp_example_token"

    cleared = await cloud_client.put(
        "/repos/github/credentials", headers=headers, json={"clear": True}
    )
    assert cleared.json()["has_github_token"] is False


async def test_demo_login_and_repo_allowlist(cloud_client: AsyncClient, seeded_remote, tmp_path):
    bare, _ = seeded_remote
    demo = await cloud_client.post("/auth/demo")
    assert demo.status_code == 200
    assert demo.json()["user"]["email"] == DEMO_EMAIL
    headers = {"Authorization": f"Bearer {demo.json()['access_token']}"}

    other = tmp_path / "other.git"
    await asyncio.to_thread(
        subprocess.run, ["git", "init", "--bare", str(other)], check=True, capture_output=True
    )
    denied = await cloud_client.post(
        "/repos/github/connect", headers=headers, json={"url": str(other)}
    )
    assert denied.status_code == 403

    allowed = await cloud_client.post(
        "/repos/github/connect", headers=headers, json={"url": str(bare)}
    )
    assert allowed.status_code == 201


async def test_demo_login_is_404_when_not_configured(client: AsyncClient):
    response = await client.post("/auth/demo")
    assert response.status_code == 404
