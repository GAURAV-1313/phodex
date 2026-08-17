import asyncio
import json
from collections.abc import AsyncIterator
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import StreamingResponse

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.approvals import ApprovalRequestOut
from app.schemas.tasks import (
    TaskCreateRequest,
    TaskDetailResponse,
    TaskEventEnvelope,
    TaskEventsResponse,
    TaskIssueOut,
    TaskIssuesResponse,
    TaskListResponse,
    TaskMessageOut,
    TaskMessagesResponse,
    TaskOut,
    TaskReplyRequest,
)
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/tasks", tags=["tasks"])


def _sse_data(envelope: TaskEventEnvelope) -> str:
    payload = envelope.model_dump(mode="json")
    return f"id: {payload['event_id']}\nevent: {payload['type']}\ndata: {json.dumps(payload)}\n\n"


@router.post("", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
async def create_task(
    payload: TaskCreateRequest,
    request: Request,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskOut:
    allowed = await services.redis.allow(
        f"rate:task:{current_user.id}",
        services.settings.task_rate_limit_per_minute,
        60,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Task rate limit exceeded"
        )
    task = await services.task_service.create_task(
        user_id=current_user.id,
        prompt=payload.prompt,
        project_context_id=payload.project_context_id,
        title=payload.title,
    )
    return TaskOut.model_validate(task)


@router.get("", response_model=TaskListResponse)
async def list_tasks(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskListResponse:
    tasks = await services.task_service.list_tasks(current_user.id)
    return TaskListResponse(items=[TaskOut.model_validate(task) for task in tasks])


@router.get("/{task_id}", response_model=TaskDetailResponse)
async def get_task(
    task_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskDetailResponse:
    task, messages, events, approvals = await services.task_service.get_task_detail(
        current_user.id, task_id
    )
    return TaskDetailResponse(
        task=TaskOut.model_validate(task),
        messages=[TaskMessageOut.model_validate(message) for message in messages],
        events=events,
        approvals=[ApprovalRequestOut.model_validate(approval) for approval in approvals],
    )


@router.post("/{task_id}/reply", response_model=TaskMessageOut)
async def reply_to_task(
    task_id: UUID,
    payload: TaskReplyRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskMessageOut:
    message = await services.task_service.add_reply(current_user.id, task_id, payload.content)
    return TaskMessageOut.model_validate(message)


@router.post("/{task_id}/cancel", response_model=TaskOut)
async def cancel_task(
    task_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskOut:
    task = await services.task_service.cancel_task(current_user.id, task_id)
    return TaskOut.model_validate(task)


@router.get("/{task_id}/messages", response_model=TaskMessagesResponse)
async def list_messages(
    task_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskMessagesResponse:
    messages = await services.task_service.list_messages(current_user.id, task_id)
    return TaskMessagesResponse(
        items=[TaskMessageOut.model_validate(message) for message in messages]
    )


@router.get("/{task_id}/events", response_model=TaskEventsResponse)
async def list_events(
    task_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskEventsResponse:
    events = await services.task_service.list_events(current_user.id, task_id)
    return TaskEventsResponse(items=events)


@router.get("/{task_id}/issues", response_model=TaskIssuesResponse)
async def list_task_issues(
    task_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TaskIssuesResponse:
    issues = await services.task_service.list_issues(current_user.id, task_id)
    return TaskIssuesResponse(items=[TaskIssueOut.model_validate(issue) for issue in issues])


@router.get("/{task_id}/stream")
async def stream_task_events(
    task_id: UUID,
    request: Request,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
    after_sequence: Annotated[int, Query(ge=0)] = 0,
    live: Annotated[bool, Query(description="Keep stream open for live events")] = True,
) -> StreamingResponse:
    await services.task_service.get_task(current_user.id, task_id)

    async def generator() -> AsyncIterator[str]:
        queue = await services.event_service.subscribe(task_id)
        from app.core.metrics import SSE_CONNECTIONS

        SSE_CONNECTIONS.inc()
        backlog = await services.event_service.list_envelopes(
            task_id, after_sequence=after_sequence
        )
        last_sequence = after_sequence
        for event in backlog:
            yield _sse_data(event)
            last_sequence = event.sequence

        if not live:
            return

        try:
            while True:
                if await request.is_disconnected():
                    break

                try:
                    event = await asyncio.wait_for(queue.get(), timeout=15.0)
                    if event.sequence > last_sequence:
                        yield _sse_data(event)
                        last_sequence = event.sequence
                except TimeoutError:
                    yield ": keep-alive\n\n"
        finally:
            SSE_CONNECTIONS.dec()
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
