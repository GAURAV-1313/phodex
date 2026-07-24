import asyncio

import fakeredis.aioredis
from httpx import AsyncClient

from app.services.redis_service import RedisService


async def test_redis_cache_rate_limit_and_pubsub() -> None:
    service = RedisService(None, "test:events")
    service._client = fakeredis.aioredis.FakeRedis(decode_responses=True)  # type: ignore[assignment]

    assert await service.allow("rate:test", limit=1, window_seconds=60)
    assert not await service.allow("rate:test", limit=1, window_seconds=60)

    await service.set_json("cache:test", {"value": 7}, ttl_seconds=60)
    assert await service.get_json("cache:test") == {"value": 7}

    received: list[str] = []

    async def collect(payload: str) -> None:
        received.append(payload)

    listener = asyncio.create_task(service.listen(collect))
    await asyncio.sleep(0.02)
    assert await service.publish("event-payload")
    for _ in range(20):
        if received:
            break
        await asyncio.sleep(0.01)
    listener.cancel()
    await asyncio.gather(listener, return_exceptions=True)
    assert received == ["event-payload"]
    await service.close()


async def test_rate_limit_cache_invalidation_health_and_metrics(
    app, client: AsyncClient, login
) -> None:
    services = app.state.services
    services.redis._client = fakeredis.aioredis.FakeRedis(decode_responses=True)  # type: ignore[assignment]
    services.settings.task_rate_limit_per_minute = 1

    headers = await login("platform-user")
    usage = await client.get("/account/usage", headers=headers)
    assert usage.status_code == 200
    assert await services.redis.get_json("account:usage:" + usage.json()["user_id"]) is not None

    first = await client.post("/tasks", headers=headers, json={"prompt": "first task"})
    assert first.status_code == 201
    assert await services.redis.get_json("account:usage:" + usage.json()["user_id"]) is None

    second = await client.post("/tasks", headers=headers, json={"prompt": "second task"})
    assert second.status_code == 429

    ready = await client.get("/health/ready")
    assert ready.status_code == 200
    assert ready.json()["database"] == "ok"
    assert ready.json()["redis"] == "ok"

    metrics = await client.get("/metrics")
    assert metrics.status_code == 200
    assert "phodex_http_requests_total" in metrics.text
    assert "X-Request-ID" in metrics.headers
