from app.workers.claude.output_parser import (
    extract_assistant_text,
    extract_result_subtype,
    extract_result_summary,
    extract_tool_use_summaries,
    is_error_result,
    is_result_event,
    is_system_init,
)


def test_extract_assistant_text_joins_text_blocks():
    payload = {
        "type": "assistant",
        "message": {
            "role": "assistant",
            "content": [
                {"type": "text", "text": "First line."},
                {"type": "tool_use", "name": "Edit", "input": {"file_path": "a.py"}},
                {"type": "text", "text": "Second line."},
            ],
        },
    }
    assert extract_assistant_text(payload) == "First line.\nSecond line."


def test_extract_assistant_text_ignores_non_assistant_events():
    assert extract_assistant_text({"type": "system", "subtype": "init"}) is None
    assert extract_assistant_text({"type": "assistant", "message": None}) is None


def test_extract_tool_use_summaries_prefers_file_path_then_command():
    payload = {
        "type": "assistant",
        "message": {
            "content": [
                {"type": "tool_use", "name": "Edit", "input": {"file_path": "app/main.py"}},
                {"type": "tool_use", "name": "Bash", "input": {"command": "pytest -q"}},
                {"type": "tool_use", "name": "Glob"},
            ]
        },
    }
    assert extract_tool_use_summaries(payload) == [
        "Edit: app/main.py",
        "Bash: pytest -q",
        "Glob",
    ]


def test_is_system_init_matches_only_init_subtype():
    assert is_system_init({"type": "system", "subtype": "init"})
    assert not is_system_init({"type": "system", "subtype": "post_turn_summary"})
    assert not is_system_init({"type": "assistant"})


def test_result_event_helpers():
    success = {"type": "result", "subtype": "success", "is_error": False, "result": "Done."}
    failure = {"type": "result", "subtype": "error_during_execution", "is_error": True}

    assert is_result_event(success)
    assert not is_result_event({"type": "assistant"})

    assert not is_error_result(success)
    assert is_error_result(failure)

    assert extract_result_summary(success) == "Done."
    assert extract_result_summary(failure) is None

    assert extract_result_subtype(failure) == "error_during_execution"
