from httpx import AsyncClient


async def test_google_auth_and_me(client: AsyncClient, login):
    headers = await login("alice")

    me = await client.get("/auth/me", headers=headers)
    assert me.status_code == 200
    payload = me.json()
    assert payload["google_sub"] == "alice"
    assert payload["email"] == "alice@example.com"
