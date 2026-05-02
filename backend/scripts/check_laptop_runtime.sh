#!/usr/bin/env bash
set -euo pipefail

CODEX_BIN="${CODEX_COMMAND:-/Applications/Codex.app/Contents/Resources/codex}"

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_bin curl
require_bin jq

if command -v docker >/dev/null 2>&1; then
  echo "docker: $(docker --version)"
else
  echo "docker: not found"
fi

if [[ -x "$CODEX_BIN" ]]; then
  echo "codex: $CODEX_BIN"
  "$CODEX_BIN" --version
elif command -v codex >/dev/null 2>&1; then
  echo "codex: $(command -v codex)"
  codex --version
else
  echo "Codex CLI not found. Expected $CODEX_BIN or codex on PATH." >&2
  exit 1
fi

echo "runtime preflight: OK"
