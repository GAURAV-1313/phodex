"""Pure functions for parsing structured JSON lines emitted by the Codex runtime."""


def extract_final_summary(payload: dict) -> str | None:
    for key in ("final_summary", "summary"):
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value
    return None


def is_blocked_outcome(summary: str) -> bool:
    normalized = summary.upper()
    return "OUTCOME: BLOCKED" in normalized or "**BLOCKED**" in normalized


def extract_assistant_message(payload: dict) -> str | None:
    for key in ("assistant_message", "assistant", "final_answer", "output_text"):
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value

    if payload.get("role") == "assistant":
        content = extract_content_text(payload.get("content"))
        if content:
            return content

    if payload.get("type") in {"assistant_message", "agent_message"}:
        for key in ("message", "text"):
            message = payload.get(key)
            if isinstance(message, str) and message.strip():
                return message

    for key in ("message", "msg", "item", "delta", "event"):
        nested = payload.get(key)
        if isinstance(nested, dict):
            message = extract_assistant_message(nested)
            if message:
                return message

    return None


def extract_content_text(content: object) -> str | None:
    if isinstance(content, str) and content.strip():
        return content
    if isinstance(content, dict):
        for key in ("text", "output_text", "content"):
            value = content.get(key)
            if isinstance(value, str) and value.strip():
                return value
        return None
    if isinstance(content, list):
        chunks: list[str] = []
        for item in content:
            text = extract_content_text(item)
            if text:
                chunks.append(text)
        if chunks:
            return "\n".join(chunks)
    return None
