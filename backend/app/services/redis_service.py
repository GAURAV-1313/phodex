import asyncio
import json
from collections.abc import Awaitable, Callable

import structlog
from redis.asyncio import Redis
from redis.asyncio.client import PubSub

from app.core.metrics import REDIS_PUBLISH_FAILURES

logger = structlog.get_logger(__name__)


class RedisService:
    """Optional Redis adapter for ephemeral coordination; durable data stays in Postgres."""

    def __init__(self, redis_url: str | None, channel: str) -> None:
        self._redis_url = redis_url
        self._channel = channel
        self._client: Redis | None = None

    @property
    def enabled(self) -> bool:
        return self._client is not None

    async def connect(self) -> None:
        if not self._redis_url:
            return
        self._client = Redis.from_url(self._redis_url, decode_responses=True)
        await self._client.ping()

    async def close(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    async def ping(self) -> bool:
        if self._client is None:
            return False
        try:
            return bool(await self._client.ping())
        except Exception:
            return False

    async def get_json(self, key: str) -> dict | list | None:
        if self._client is None:
            return None
        value = await self._client.get(key)
        return json.loads(value) if value else None

    async def set_json(self, key: str, value: dict | list, ttl_seconds: int) -> None:
        if self._client is not None:
            await self._client.set(key, json.dumps(value, default=str), ex=ttl_seconds)

    async def delete(self, *keys: str) -> None:
        if self._client is not None and keys:
            await self._client.delete(*keys)

    async def allow(self, key: str, limit: int, window_seconds: int) -> bool:
        if self._client is None or limit <= 0:
            return True
        count = await self._client.incr(key)
        if count == 1:
            await self._client.expire(key, window_seconds)
        return int(count) <= limit

    async def publish(self, payload: str) -> bool:
        if self._client is None:
            return False
        try:
            await self._client.publish(self._channel, payload)
            return True
        except Exception as exc:
            REDIS_PUBLISH_FAILURES.inc()
            logger.warning("redis.publish_failed", error=str(exc))
            return False

    async def listen(self, handler: Callable[[str], Awaitable[None]]) -> None:
        if self._client is None:
            return
        pubsub: PubSub = self._client.pubsub()
        await pubsub.subscribe(self._channel)
        try:
            async for message in pubsub.listen():
                if message.get("type") == "message" and isinstance(message.get("data"), str):
                    await handler(message["data"])
        except asyncio.CancelledError:
            raise
        finally:
            await pubsub.unsubscribe(self._channel)
            await pubsub.aclose()
