#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${PHODEX_BASE_URL:-http://127.0.0.1:8000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

curl -fsS "$BASE_URL/health/live" >/dev/null
curl -fsS "$BASE_URL/health/ready" >/dev/null
"$SCRIPT_DIR/smoke_test_codex_worker.sh"
curl -fsS "$BASE_URL/metrics" | grep -q 'phodex_http_requests_total'

echo "Platform smoke test passed: health, lifecycle/SSE, and metrics verified."
