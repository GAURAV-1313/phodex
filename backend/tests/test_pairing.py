from httpx import AsyncClient


async def test_pairing_page_serves_a_qr_code_with_no_auth(client: AsyncClient):
    response = await client.get("/pair")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    body = response.text
    assert "data:image/png;base64," in body
    assert "Connect your phone" in body


async def test_pairing_page_warns_when_address_is_guessed(client: AsyncClient):
    response = await client.get("/pair")
    assert response.status_code == 200
    # The test app never sets PUBLIC_BASE_URL, so this is always a guess.
    assert "same Wi-Fi network" in response.text
