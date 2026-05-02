import asyncio
import json
from collections.abc import AsyncIterator
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import StreamingResponse

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.tasks import TaskEventEnvelope
from app.services.exceptions import NotFoundError
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/stream", tags=["stream"])


def _sse_data(envelope: TaskEventEnvelope) -> str:
    payload = envelope.model_dump(mode="json")
    return f"id: {payload['event_id']}\nevent: {payload['type']}\ndata: {json.dumps(payload)}\n\n"


@router.get("/tasks/{task_id}")
async def stream_task_events_alias(
    task_id: UUID,
    request: Request,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
    after_sequence: Annotated[int, Query(ge=0)] = 0,
    live: Annotated[bool, Query(description="Keep stream open for live events")] = True,
) -> StreamingResponse:
    try:
        await services.task_service.get_task(current_user.id, task_id)
    except NotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc

    async def generator() -> AsyncIterator[str]:
        backlog = await services.event_service.list_envelopes(
            task_id, after_sequence=after_sequence
        )
        for event in backlog:
            yield _sse_data(event)

        if not live:
            return

        queue = await services.event_service.subscribe(task_id)
        try:
            while True:
                if await request.is_disconnected():
                    break

                try:
                    event = await asyncio.wait_for(queue.get(), timeout=15.0)
                    yield _sse_data(event)
                except TimeoutError:
                    yield ": keep-alive\n\n"
        finally:
            await services.event_service.unsubscribe(task_id, queue)

    return StreamingResponse(
        generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
