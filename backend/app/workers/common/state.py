import asyncio
from dataclasses import dataclass, field
from uuid import UUID


@dataclass
class ExecutionContext:
    prompt_text: str
    workdir: str | None
    context_name: str | None
    branch: str | None


@dataclass
class RuntimeState:
    task_id: UUID
    job: asyncio.Task[None] | None = None
    process: asyncio.subprocess.Process | None = None
    approval_id: UUID | None = None
    approval_event: asyncio.Event = field(default_factory=asyncio.Event)
    approval_granted: bool | None = None
    pending_replies: list[str] = field(default_factory=list)
    final_summary: str | None = None
    stderr_tail: list[str] = field(default_factory=list)
    runtime_reported_error: bool = False
