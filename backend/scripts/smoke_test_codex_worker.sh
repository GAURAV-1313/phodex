#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${PHODEX_BASE_URL:-http://127.0.0.1:8000}"
PROMPT="${PHODEX_SMOKE_PROMPT:-Phodex worker lifecycle verification. Do not execute shell commands or edit files. Reply with exactly: OUTCOME: COMPLETED\nReal Codex runtime lifecycle verified.}"
POLL_INTERVAL_SECONDS="${PHODEX_POLL_INTERVAL_SECONDS:-2}"
POLL_TIMEOUT_SECONDS="${PHODEX_POLL_TIMEOUT_SECONDS:-240}"
DEFAULT_LOCAL_TEST_TOKEN="test-token|local-user|gaurav@example.com|Gaurav Local"

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_bin curl
require_bin jq

auth_header() {
  if [[ -n "${PHODEX_BEARER_TOKEN:-}" ]]; then
    echo "Authorization: Bearer ${PHODEX_BEARER_TOKEN}"
    return
  fi

  local login_payload
  local login_response
  local login_body_file
  local login_status
  local login_token
  local token

  login_token="${PHODEX_GOOGLE_ID_TOKEN:-}"
  if [[ -z "$login_token" ]]; then
    case "$BASE_URL" in
      http://127.0.0.1:*|http://localhost:*|http://0.0.0.0:*)
        login_token="$DEFAULT_LOCAL_TEST_TOKEN"
        ;;
      *)
        echo "Set PHODEX_BEARER_TOKEN or PHODEX_GOOGLE_ID_TOKEN before running smoke test." >&2
        exit 1
        ;;
    esac
  fi

  login_payload="$(jq -cn --arg id_token "$login_token" '{id_token: $id_token}')"
  login_body_file="$(mktemp)"
  login_status="$(curl -sS -o "$login_body_file" -w "%{http_code}" -X POST "$BASE_URL/auth/google" \
    -H "Content-Type: application/json" \
    --data "$login_payload")"
  login_response="$(cat "$login_body_file")"
  rm -f "$login_body_file"

  if [[ "$login_status" != "200" ]]; then
    echo "/auth/google failed with HTTP $login_status." >&2
    echo "$login_response" >&2
    echo "For laptop testing, confirm .env has ALLOW_INSECURE_TEST_TOKENS=true and run migrations." >&2
    exit 1
  fi

  token="$(echo "$login_response" | jq -r '.access_token // empty')"
  if [[ -z "$token" ]]; then
    echo "Unable to get access token from /auth/google response." >&2
    echo "$login_response" >&2
    exit 1
  fi

  echo "Authorization: Bearer $token"
}

poll_task_until() {
  local task_id="$1"
  local target_states="$2"
  local auth="$3"
  local deadline
  local now
  local detail
  local status_value

  deadline=$(( $(date +%s) + POLL_TIMEOUT_SECONDS ))
  while true; do
    now="$(date +%s)"
    if (( now > deadline )); then
      echo "Timed out waiting for task $task_id to reach one of: $target_states" >&2
      return 1
    fi

    detail="$(curl -fsS "$BASE_URL/tasks/$task_id" -H "$auth")"
    status_value="$(echo "$detail" | jq -r '.task.status')"
    echo "Task $task_id status: $status_value" >&2

    case "$status_value" in
      queued|starting|running)
        sleep "$POLL_INTERVAL_SECONDS"
        ;;
      waiting_approval|completed|failed|cancelled)
        if [[ " $target_states " == *" $status_value "* ]]; then
          echo "$detail"
          return 0
        fi
        sleep "$POLL_INTERVAL_SECONDS"
        ;;
      *)
        echo "Unknown task status: $status_value" >&2
        echo "$detail" >&2
        return 1
        ;;
    esac
  done
}

AUTH_HEADER="$(auth_header)"
echo "Using base URL: $BASE_URL"

create_payload="$(jq -cn --arg prompt "$PROMPT" '{prompt: $prompt}')"
create_response="$(curl -fsS -X POST "$BASE_URL/tasks" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  --data "$create_payload")"

TASK_ID="$(echo "$create_response" | jq -r '.id // empty')"
if [[ -z "$TASK_ID" ]]; then
  echo "Task creation failed: no task id in response" >&2
  echo "$create_response" >&2
  exit 1
fi
echo "Created task: $TASK_ID"

detail_json="$(poll_task_until "$TASK_ID" "waiting_approval completed failed cancelled" "$AUTH_HEADER")"
current_status="$(echo "$detail_json" | jq -r '.task.status')"

if [[ "$current_status" == "waiting_approval" ]]; then
  echo "Task is waiting approval. Resolving approval..."
  pending_response="$(curl -fsS "$BASE_URL/approvals/pending" -H "$AUTH_HEADER")"
  approval_id="$(
    echo "$pending_response" | jq -r --arg task_id "$TASK_ID" \
      '.items[] | select(.task_id == $task_id and .status == "pending") | .id' | head -n 1
  )"

  if [[ -z "$approval_id" ]]; then
    echo "No pending approval found for task $TASK_ID" >&2
    echo "$pending_response" >&2
    exit 1
  fi

  curl -fsS -X POST "$BASE_URL/approvals/$approval_id/approve" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    --data '{}' >/dev/null
  echo "Approved request: $approval_id"

  detail_json="$(poll_task_until "$TASK_ID" "completed failed cancelled" "$AUTH_HEADER")"
  current_status="$(echo "$detail_json" | jq -r '.task.status')"
fi

issues_response="$(curl -fsS "$BASE_URL/tasks/$TASK_ID/issues" -H "$AUTH_HEADER")"
issues_count="$(echo "$issues_response" | jq '.items | length')"
events_count="$(echo "$detail_json" | jq '.events | length')"
messages_count="$(echo "$detail_json" | jq '.messages | length')"
final_summary="$(echo "$detail_json" | jq -r '.task.final_summary // empty')"

echo
echo "Smoke test result"
echo "-----------------"
echo "task_id: $TASK_ID"
echo "status: $current_status"
echo "events: $events_count"
echo "messages: $messages_count"
echo "issues: $issues_count"
if [[ -n "$final_summary" ]]; then
  echo "final_summary: $final_summary"
fi

echo
echo "Validating SSE replay endpoint..."
sse_output="$(curl -fsS "$BASE_URL/tasks/$TASK_ID/stream?after_sequence=0&live=false" -H "$AUTH_HEADER")"
if grep -q '^event:' <<<"$sse_output"; then
  echo "SSE replay check: OK"
else
  echo "SSE replay check: FAILED (no event lines found)" >&2
  exit 1
fi

if [[ "$current_status" == "completed" ]]; then
  echo "Smoke test passed."
  exit 0
fi

echo
echo "Task failure details:" >&2
echo "$issues_response" | jq '.items[] | {sequence, type, code, message, data}' >&2

echo "Smoke test finished with non-completed status: $current_status" >&2
exit 1
