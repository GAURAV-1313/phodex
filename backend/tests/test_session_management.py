from httpx import AsyncClient


async def test_list_sessions_marks_current_and_excludes_other_users(
    client: AsyncClient, login
):
    headers_a1 = await login("session-user-a")
    headers_a2 = await login("session-user-a")
    await login("session-user-b")

    listed = await client.get("/account/sessions", headers=headers_a1)
    assert listed.status_code == 200
    sessions = listed.json()["items"]
    assert len(sessions) == 2

    current_flags = [s["is_current"] for s in sessions]
    assert current_flags.count(True) == 1

    listed_second = await client.get("/account/sessions", headers=headers_a2)
    assert listed_second.status_code == 200
    sessions_second = listed_second.json()["items"]
    ids_first = {s["id"] for s in sessions}
    ids_second = {s["id"] for s in sessions_second}
    assert ids_first == ids_second
    current_in_second = next(s for s in sessions_second if s["is_current"])
    current_in_first = next(s for s in sessions if s["is_current"])
    assert current_in_second["id"] != current_in_first["id"]


async def test_revoke_session_removes_it_from_the_list(client: AsyncClient, login):
    headers = await login("revoke-user")
    other_headers = await login("revoke-user")

    sessions = (await client.get("/account/sessions", headers=headers)).json()["items"]
    other_session_id = next(s["id"] for s in sessions if not s["is_current"])

    revoke = await client.post(f"/account/sessions/{other_session_id}/revoke", headers=headers)
    assert revoke.status_code == 204

    remaining = (await client.get("/account/sessions", headers=headers)).json()["items"]
    assert len(remaining) == 1
    assert remaining[0]["is_current"] is True

    # The revoked session's own token must no longer authenticate.
    revoked_check = await client.get("/account/me", headers=other_headers)
    assert revoked_check.status_code == 401


async def test_revoke_session_cannot_target_another_users_session(
    client: AsyncClient, login
):
    headers = await login("victim-user")
    attacker_headers = await login("attacker-user")

    victim_sessions = (await client.get("/account/sessions", headers=headers)).json()["items"]
    victim_session_id = victim_sessions[0]["id"]

    attempt = await client.post(
        f"/account/sessions/{victim_session_id}/revoke", headers=attacker_headers
    )
    assert attempt.status_code == 404

    still_valid = await client.get("/account/me", headers=headers)
    assert still_valid.status_code == 200


async def test_revoke_other_sessions_keeps_only_the_current_one(
    client: AsyncClient, login
):
    headers = await login("bulk-revoke-user")
    other_headers_1 = await login("bulk-revoke-user")
    other_headers_2 = await login("bulk-revoke-user")

    result = await client.post("/account/sessions/revoke-others", headers=headers)
    assert result.status_code == 200
    assert result.json()["revoked_count"] == 2

    remaining = (await client.get("/account/sessions", headers=headers)).json()["items"]
    assert len(remaining) == 1
    assert remaining[0]["is_current"] is True

    assert (await client.get("/account/me", headers=other_headers_1)).status_code == 401
    assert (await client.get("/account/me", headers=other_headers_2)).status_code == 401
    assert (await client.get("/account/me", headers=headers)).status_code == 200
