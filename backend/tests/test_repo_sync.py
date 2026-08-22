from httpx import AsyncClient


async def test_device_register_repo_sync_and_select(client: AsyncClient, login):
    headers = await login("repo-user")

    registered = await client.post(
        "/devices/register",
        headers=headers,
        json={"name": "Gaurav Mac", "platform": "macos", "agent_version": "0.1.0"},
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
                    "name": "phodex",
                    "local_path": "/Users/gaurav/phodex",
                    "git_root": "/Users/gaurav/phodex",
                    "current_branch": "main",
                    "default_branch": "main",
                    "metadata_json": {"last_commit": "abc123"},
                }
            ],
        },
    )
    assert sync.status_code == 200
    assert sync.json()["synced_count"] == 1

    repos = await client.get("/repos", headers=headers)
    assert repos.status_code == 200
    repo_id = repos.json()["items"][0]["id"]

    selected = await client.post(f"/repos/{repo_id}/select", headers=headers, json={})
    assert selected.status_code == 200
    context_id = selected.json()["project_context"]["id"]

    task = await client.post(
        "/tasks",
        headers=headers,
        json={"prompt": "Use selected repo", "project_context_id": context_id},
    )
    assert task.status_code == 201
    assert task.json()["project_context_id"] == context_id


async def test_current_context_persists_across_requests_and_switches(
    client: AsyncClient, login
):
    headers = await login("current-context-user")

    before = await client.get("/repos/context/current", headers=headers)
    assert before.status_code == 200
    assert before.json()["project_context"] is None

    registered = await client.post(
        "/devices/register",
        headers=headers,
        json={"name": "Gaurav Mac", "platform": "macos", "agent_version": "0.1.0"},
    )
    device_id = registered.json()["id"]

    await client.post(
        "/repos/sync",
        headers=headers,
        json={
            "device_id": device_id,
            "repositories": [
                {
                    "name": "repo-a",
                    "local_path": "/tmp/repo-a",
                    "git_root": "/tmp/repo-a",
                },
                {
                    "name": "repo-b",
                    "local_path": "/tmp/repo-b",
                    "git_root": "/tmp/repo-b",
                },
            ],
        },
    )
    repos = (await client.get("/repos", headers=headers)).json()["items"]
    repo_a = next(r for r in repos if r["name"] == "repo-a")
    repo_b = next(r for r in repos if r["name"] == "repo-b")

    selected_a = await client.post(f"/repos/{repo_a['id']}/select", headers=headers, json={})
    context_a_id = selected_a.json()["project_context"]["id"]

    # A different "request" (no client-side cache) still sees the selection.
    current = await client.get("/repos/context/current", headers=headers)
    assert current.json()["project_context"]["id"] == context_a_id

    # Selecting a second repo must supersede the first, not stack alongside it.
    selected_b = await client.post(f"/repos/{repo_b['id']}/select", headers=headers, json={})
    context_b_id = selected_b.json()["project_context"]["id"]
    assert context_b_id != context_a_id

    current_after_switch = await client.get("/repos/context/current", headers=headers)
    assert current_after_switch.json()["project_context"]["id"] == context_b_id
