"""Pure functions for parsing `claude -p ... --output-format stream-json` events.

Claude Code's headless JSON stream emits typed events: `system` (init and
lifecycle notes), `assistant`/`user` (turn messages), and a single terminal
`result` event carrying the final answer and an explicit `is_error` flag —
unlike Codex, no OUTCOME sentinel convention is needed since the CLI reports
success/failure structurally.
"""


def extract_assistant_text(payload: dict) -> str | None:
    if payload.get("type") != "assistant":
        return None
    message = payload.get("message")
    if not isinstance(message, dict):
        return None
    content = message.get("content")
    if not isinstance(content, list):
        return None
    chunks = [
        block.get("text", "").strip()
        for block in content
        if isinstance(block, dict)
        and block.get("type") == "text"
        and isinstance(block.get("text"), str)
        and block.get("text", "").strip()
    ]
    return "\n".join(chunks) if chunks else None


def extract_tool_use_summaries(payload: dict) -> list[str]:
    if payload.get("type") != "assistant":
        return []
    message = payload.get("message")
    if not isinstance(message, dict):
        return []
    content = message.get("content")
    if not isinstance(content, list):
        return []

    summaries: list[str] = []
    for block in content:
        if not isinstance(block, dict) or block.get("type") != "tool_use":
            continue
        name = block.get("name", "tool")
        tool_input = block.get("input")
        detail = None
        if isinstance(tool_input, dict):
            detail = tool_input.get("file_path") or tool_input.get("path") or tool_input.get(
                "command"
            )
        summaries.append(f"{name}: {detail}" if detail else str(name))
    return summaries


def is_system_init(payload: dict) -> bool:
    return payload.get("type") == "system" and payload.get("subtype") == "init"


def is_result_event(payload: dict) -> bool:
    return payload.get("type") == "result"


def is_error_result(payload: dict) -> bool:
    return bool(payload.get("is_error"))


def extract_result_summary(payload: dict) -> str | None:
    value = payload.get("result")
    if isinstance(value, str) and value.strip():
        return value.strip()
    return None


def extract_result_subtype(payload: dict) -> str | None:
    value = payload.get("subtype")
    if isinstance(value, str) and value.strip():
        return value.strip()
    return None
