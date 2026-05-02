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
