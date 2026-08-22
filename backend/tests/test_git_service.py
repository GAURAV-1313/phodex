"""Integration tests for the commit & push flow (git_service.py + api/git_ops.py).

Runs real `git` subprocesses against a scratch temp directory — never the
real project repo, and never a real GitHub remote (a second temp bare repo
stands in for "origin" where a real push needs to be exercised).
"""

import asyncio
import subprocess

import pytest
from httpx import AsyncClient


def _git(*args: str, cwd: str) -> None:
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True)


async def _git_output(*args: str, cwd: str) -> str:
    result = await asyncio.to_thread(
        subprocess.run, ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    )
    return result.stdout


@pytest.fixture
def scratch_repo(tmp_path):
    repo = tmp_path / "scratch-repo"
    repo.mkdir()
    _git("init", "-b", "main", cwd=str(repo))
    _git("config", "user.email", "test@example.com", cwd=str(repo))
    _git("config", "user.name", "Test User", cwd=str(repo))
    (repo / "README.md").write_text("hello\n")
    _git("add", "-A", cwd=str(repo))
    _git("commit", "-m", "initial commit", cwd=str(repo))
    return repo


@pytest.fixture
def scratch_repo_with_remote(scratch_repo, tmp_path):
    bare = tmp_path / "scratch-remote.git"
    subprocess.run(["git", "init", "--bare", str(bare)], check=True, capture_output=True)
    _git("remote", "add", "origin", str(bare), cwd=str(scratch_repo))
    _git("push", "-u", "origin", "main", cwd=str(scratch_repo))
    return scratch_repo, bare


@pytest.fixture
def scratch_repo_with_untracked_remote(scratch_repo, tmp_path):
    """A remote that's configured but never pushed to — no upstream tracking
    yet, the exact state of a repo's first-ever push."""
    bare = tmp_path / "scratch-remote-untracked.git"
    subprocess.run(["git", "init", "--bare", str(bare)], check=True, capture_output=True)
    _git("remote", "add", "origin", str(bare), cwd=str(scratch_repo))
    return scratch_repo, bare


async def _wait_for_task_status(
    client: AsyncClient, headers: dict[str, str], task_id: str, desired: set[str]
) -> dict:
    for _ in range(200):
        res = await client.get(f"/tasks/{task_id}", headers=headers)
        assert res.status_code == 200
        data = res.json()
        if data["task"]["status"] in desired:
            return data
        await asyncio.sleep(0.02)
    raise AssertionError(f"Task {task_id} did not reach {desired}")


async def _completed_task_in_repo(client: AsyncClient, headers: dict[str, str], repo_path: str) -> str:
    """Registers a device, syncs a repo at repo_path, and runs a task to completion in it."""
    registered = await client.post(
        "/devices/register",
        headers=headers,
        json={"name": "Test Device", "platform": "macos", "agent_version": "0.1.0"},
    )
    assert registered.status_code == 201
    device_id = registered.json()["id"]

    sync = await client.post(
        "/repos/sync",
        headers=headers,
        json={
            "device_id": device_id,
            "repositories": [
                {
                    "name": "scratch",
                    "local_path": repo_path,
                    "git_root": repo_path,
                    "current_branch": "main",
                    "default_branch": "main",
                    "metadata_json": {},
                }
            ],
        },
    )
    assert sync.status_code == 200
    repos = await client.get("/repos", headers=headers)
    repo_id = repos.json()["items"][0]["id"]
    selected = await client.post(f"/repos/{repo_id}/select", headers=headers, json={})
    context_id = selected.json()["project_context"]["id"]

    created = await client.post(
        "/tasks",
        headers=headers,
        json={"prompt": "Make a change", "project_context_id": context_id},
    )
    assert created.status_code == 201
    task_id = created.json()["id"]

    waiting = await _wait_for_task_status(client, headers, task_id, {"waiting_approval"})
    approval_id = waiting["approvals"][0]["id"]
    approved = await client.post(f"/approvals/{approval_id}/approve", headers=headers, json={})
    assert approved.status_code == 200
    await _wait_for_task_status(client, headers, task_id, {"completed"})
    return task_id


async def test_prepare_commit_captures_status_and_diff(client: AsyncClient, login, scratch_repo):
    headers = await login("git-prepare-user")
    (scratch_repo / "new_file.txt").write_text("uncommitted change\n")
    task_id = await _completed_task_in_repo(client, headers, str(scratch_repo))

    prepared = await client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    assert prepared.status_code == 200
    body = prepared.json()
    assert body["status"] == "pending_review"
    assert "new_file.txt" in body["status_output"]


async def test_confirm_commits_and_pushes_successfully(
    client: AsyncClient, login, scratch_repo_with_remote
):
    repo, bare_remote = scratch_repo_with_remote
    headers = await login("git-confirm-user")
    (repo / "feature.txt").write_text("agent wrote this\n")
    task_id = await _completed_task_in_repo(client, headers, str(repo))

    prepared = await client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    assert prepared.status_code == 200
    git_operation_id = prepared.json()["id"]

    confirmed = await client.post(
        f"/tasks/{task_id}/git/{git_operation_id}/confirm",
        headers=headers,
        json={"commit_message": "Add feature.txt"},
    )
    assert confirmed.status_code == 200
    body = confirmed.json()
    assert body["status"] == "completed"
    assert body["error_message"] is None
    # Regression: the API response previously kept showing the default
    # "Phodex: ..." message here even though the real git commit correctly
    # used the caller's override — the override was only ever mutated on a
    # detached in-memory object, never persisted before this response was
    # built from a fresh DB read.
    assert body["commit_message"] == "Add feature.txt"

    log_stdout = await _git_output("log", "-1", "--pretty=%s", cwd=str(repo))
    assert log_stdout.strip() == "Add feature.txt"

    remote_log_stdout = await _git_output("log", "-1", "--pretty=%s", "main", cwd=str(bare_remote))
    assert remote_log_stdout.strip() == "Add feature.txt"


async def test_confirm_succeeds_on_first_ever_push_with_no_upstream(
    client: AsyncClient, login, scratch_repo_with_untracked_remote
):
    """Regression: a bare `git push` fails with "no upstream branch" the
    first time a branch is ever pushed. `confirm()` must set tracking itself
    rather than assuming an operator already ran `push -u` once by hand."""
    repo, bare_remote = scratch_repo_with_untracked_remote
    headers = await login("git-first-push-user")
    (repo / "first.txt").write_text("never pushed before\n")
    task_id = await _completed_task_in_repo(client, headers, str(repo))

    prepared = await client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    git_operation_id = prepared.json()["id"]

    confirmed = await client.post(
        f"/tasks/{task_id}/git/{git_operation_id}/confirm",
        headers=headers,
        json={"commit_message": "First push"},
    )
    assert confirmed.status_code == 200
    body = confirmed.json()
    assert body["status"] == "completed"
    assert body["error_message"] is None

    remote_log_stdout = await _git_output("log", "-1", "--pretty=%s", "main", cwd=str(bare_remote))
    assert remote_log_stdout.strip() == "First push"


async def test_confirm_fails_gracefully_when_no_remote_configured(
    client: AsyncClient, login, scratch_repo
):
    headers = await login("git-no-remote-user")
    (scratch_repo / "orphan.txt").write_text("no remote to push to\n")
    task_id = await _completed_task_in_repo(client, headers, str(scratch_repo))

    prepared = await client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    git_operation_id = prepared.json()["id"]

    confirmed = await client.post(
        f"/tasks/{task_id}/git/{git_operation_id}/confirm", headers=headers, json={}
    )
    assert confirmed.status_code == 200
    body = confirmed.json()
    assert body["status"] == "failed"
    assert body["error_message"]

    # The commit itself (before the failing push) should have landed locally.
    log_stdout = await _git_output("log", "-1", "--pretty=%s", cwd=str(scratch_repo))
    assert "Phodex:" in log_stdout


async def test_discard_leaves_repo_untouched(client: AsyncClient, login, scratch_repo):
    headers = await login("git-discard-user")
    (scratch_repo / "draft.txt").write_text("not ready\n")
    task_id = await _completed_task_in_repo(client, headers, str(scratch_repo))

    prepared = await client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    git_operation_id = prepared.json()["id"]

    discarded = await client.post(
        f"/tasks/{task_id}/git/{git_operation_id}/discard", headers=headers
    )
    assert discarded.status_code == 200
    assert discarded.json()["status"] == "rejected"

    status_stdout = await _git_output("status", "--porcelain", cwd=str(scratch_repo))
    assert "draft.txt" in status_stdout


async def test_confirm_twice_conflicts(client: AsyncClient, login, scratch_repo_with_remote):
    repo, _bare_remote = scratch_repo_with_remote
    headers = await login("git-double-confirm-user")
    (repo / "once.txt").write_text("only once\n")
    task_id = await _completed_task_in_repo(client, headers, str(repo))

    prepared = await client.post(f"/tasks/{task_id}/git/prepare", headers=headers)
    git_operation_id = prepared.json()["id"]

    first = await client.post(
        f"/tasks/{task_id}/git/{git_operation_id}/confirm", headers=headers, json={}
    )
    assert first.status_code == 200

    second = await client.post(
        f"/tasks/{task_id}/git/{git_operation_id}/confirm", headers=headers, json={}
    )
    assert second.status_code == 409
