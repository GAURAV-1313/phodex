from unittest.mock import MagicMock, patch
from uuid import uuid4

import httpx
import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.models.push_subscription import PushSubscription
from app.services.push_service import PushService


@pytest.fixture
def push_service(app) -> PushService:
    return app.state.services.push_service


async def test_push_is_disabled_without_firebase_config(push_service: PushService):
    assert push_service.enabled is False

    # A safe no-op: never raises, never attempts a network call.
    await push_service.notify_user(uuid4(), title="Test", body="Test")


async def test_register_token_creates_a_subscription(push_service: PushService):
    user_id = uuid4()
    await push_service.register_token(user_id, "token-abc", "ios")

    async with push_service._session_factory() as session:
        row = await session.scalar(
            select(PushSubscription).where(PushSubscription.fcm_token == "token-abc")
        )
        assert row is not None
        assert row.user_id == user_id
        assert row.platform == "ios"


async def test_registering_the_same_token_again_upserts_not_duplicates(
    push_service: PushService,
):
    first_user = uuid4()
    second_user = uuid4()
    await push_service.register_token(first_user, "token-shared", "android")
    await push_service.register_token(second_user, "token-shared", "android")

    async with push_service._session_factory() as session:
        rows = (
            (
                await session.execute(
                    select(PushSubscription).where(
                        PushSubscription.fcm_token == "token-shared"
                    )
                )
            )
            .scalars()
            .all()
        )
        assert len(rows) == 1
        assert rows[0].user_id == second_user


async def test_unregister_only_removes_the_matching_users_token(
    push_service: PushService,
):
    owner = uuid4()
    someone_else = uuid4()
    await push_service.register_token(owner, "token-to-remove", "ios")

    # A different user's unregister call must not remove someone else's token.
    await push_service.unregister_token(someone_else, "token-to-remove")
    async with push_service._session_factory() as session:
        still_there = await session.scalar(
            select(PushSubscription).where(PushSubscription.fcm_token == "token-to-remove")
        )
        assert still_there is not None

    await push_service.unregister_token(owner, "token-to-remove")
    async with push_service._session_factory() as session:
        gone = await session.scalar(
            select(PushSubscription).where(PushSubscription.fcm_token == "token-to-remove")
        )
        assert gone is None


async def test_notify_user_sends_via_fcm_http_v1_when_enabled(push_service: PushService):
    user_id = uuid4()
    await push_service.register_token(user_id, "token-live", "ios")

    fake_credentials = MagicMock()
    fake_credentials.token = "fake-access-token"
    fake_credentials.refresh = MagicMock()
    push_service._credentials = fake_credentials
    push_service._settings.firebase_project_id = "phodex-test-project"

    captured: dict[str, object] = {}

    def fake_post(url: str, **kwargs: object) -> httpx.Response:
        captured["url"] = url
        captured["headers"] = kwargs.get("headers")
        captured["json"] = kwargs.get("json")
        return httpx.Response(200, json={"name": "projects/x/messages/1"})

    with patch("app.services.push_service.httpx.post", side_effect=fake_post):
        await push_service.notify_user(user_id, title="Hello", body="World")

    assert captured["url"] == (
        "https://fcm.googleapis.com/v1/projects/phodex-test-project/messages:send"
    )
    assert captured["headers"] == {"Authorization": "Bearer fake-access-token"}
    message = captured["json"]["message"]  # type: ignore[index]
    assert message["token"] == "token-live"
    assert message["notification"] == {"title": "Hello", "body": "World"}


async def test_push_endpoints_register_and_unregister_a_token(client: AsyncClient, login):
    headers = await login("push-user")

    register = await client.post(
        "/push/register",
        headers=headers,
        json={"fcm_token": "device-token-1", "platform": "ios"},
    )
    assert register.status_code == 204

    unregister = await client.post(
        "/push/unregister",
        headers=headers,
        json={"fcm_token": "device-token-1"},
    )
    assert unregister.status_code == 204
