#!/usr/bin/env bash
# End-to-end smoke test for a deployed Phodex Cloud runtime:
#   demo login -> connect repo -> select -> create task -> approve -> completed
#
#   PHODEX_BASE_URL=https://phodex-cloud.fly.dev \
#   PHODEX_REPO_URL=https://github.com/owner/demo-repo \
#   ./scripts/smoke_test_cloud_runtime.sh
#
# Pass PHODEX_BEARER_TOKEN to use an existing session instead of /auth/demo.
set -euo pipefail

BASE_URL="${PHODEX_BASE_URL:-http://127.0.0.1:8000}"
REPO_URL="${PHODEX_REPO_URL:?Set PHODEX_REPO_URL to a GitHub repository URL}"
PROMPT="${PHODEX_PROMPT:-Add a line to README.md that says this change was made from Phodex Cloud.}"

for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "Missing required command: $bin" >&2; exit 1; }
done

echo "runtime: $(curl -fsS "$BASE_URL/runtime/public")"

TOKEN="${PHODEX_BEARER_TOKEN:-}"
if [[ -z "$TOKEN" ]]; then
  TOKEN="$(curl -fsS -X POST "$BASE_URL/auth/demo" | jq -r .access_token)"
  echo "signed in as demo account"
fi
AUTH=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")

echo "runner: $(curl -fsS "${AUTH[@]}" "$BASE_URL/runtime" | jq -c '.runner | {name, status}')"

REPO_ID="$(curl -fsS "${AUTH[@]}" -X POST "$BASE_URL/repos/github/connect" \
  -d "{\"url\": \"$REPO_URL\"}" | jq -r .id)"
echo "connected repo $REPO_ID"

CONTEXT_ID="$(curl -fsS "${AUTH[@]}" -X POST "$BASE_URL/repos/$REPO_ID/select" -d '{}' \
  | jq -r .project_context.id)"

TASK_ID="$(curl -fsS "${AUTH[@]}" -X POST "$BASE_URL/tasks" \
  -d "{\"prompt\": $(jq -Rn --arg p "$PROMPT" '$p'), \"project_context_id\": \"$CONTEXT_ID\"}" \
  | jq -r .id)"
echo "created task $TASK_ID"

status=""
for _ in $(seq 1 600); do
  detail="$(curl -fsS "${AUTH[@]}" "$BASE_URL/tasks/$TASK_ID")"
  status="$(echo "$detail" | jq -r .task.status)"
  if [[ "$status" == "waiting_approval" ]]; then
    approval_id="$(echo "$detail" | jq -r '.approvals[] | select(.status == "pending") | .id' | head -n 1)"
    if [[ -n "$approval_id" ]]; then
      curl -fsS "${AUTH[@]}" -X POST "$BASE_URL/approvals/$approval_id/approve" -d '{}' >/dev/null
      echo "approved $approval_id"
    fi
  elif [[ "$status" == "completed" || "$status" == "failed" || "$status" == "cancelled" ]]; then
    break
  fi
  sleep 2
done

echo "final status: $status"
curl -fsS "${AUTH[@]}" "$BASE_URL/tasks/$TASK_ID/issues" | jq '.items[] | {code, message}' || true
[[ "$status" == "completed" ]]
