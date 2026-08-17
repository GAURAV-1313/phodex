# Phodex Backend (FastAPI)

Production-oriented backend MVP for an Android-native Codex client.

## What this backend supports (V1)
- Google Sign-In authentication (`POST /auth/google`) with backend-issued JWT sessions
- Account visibility endpoints for phone UI (`/account/me`, `/account/usage`, `/account/limits`)
- Task lifecycle orchestration with persistent messages/events
- SSE streaming for live task events, replayed from Postgres and fanned out via Redis Pub/Sub
- One approval gate in fake worker flow
- Follow-up messages on the same task
- Task cancellation while `running` or `waiting_approval`
- Device registration/heartbeat for Mac companion
- Metadata-only repo sync and repo selection into project contexts

## Tech choices
- FastAPI
- SQLAlchemy 2.x (async)
- PostgreSQL + Alembic
- Pydantic v2
- Service-layer architecture
- Redis (event fan-out, short-lived cache, fixed-window rate limits)
- Prometheus + Grafana metrics and OpenTelemetry traces to Jaeger

## Project structure
```text
backend/
  app/
    api/
    core/
    db/
    models/
    schemas/
    services/
    workers/
    utils/
    main.py
  tests/
  alembic/
  Dockerfile
  docker-compose.yml
  .env.example
  README.md
  Makefile
```

## Quick start
1. Create env file:
```bash
cp .env.example .env
```

2. Start local infrastructure (Postgres, Redis, Prometheus, Grafana, Jaeger):
```bash
docker compose up -d
```

3. Run the backend on the host, which keeps the real Codex worker able to use your logged-in local CLI:
```bash
make install
make migrate
make run
```

4. Open the local surfaces:
- [http://localhost:8000/docs](http://localhost:8000/docs)
- [http://localhost:3001](http://localhost:3001) (Grafana; `admin` / `admin`)
- [http://localhost:16686](http://localhost:16686) (Jaeger)
- [http://localhost:9090](http://localhost:9090) (Prometheus)

To run the backend inside Compose for a fake-worker-only container demo:
```bash
docker compose --profile container-backend up --build
```

## Production deployment
- Copy `/Users/gaurav/phodex/backend/.env.production.example` to `.env` and fill real values.
- Follow `/Users/gaurav/phodex/backend/docs/deploy-checklist.md`.
- Run smoke test after deployment:
  - `PHODEX_BASE_URL=http://127.0.0.1:8000 PHODEX_BEARER_TOKEN=<jwt> /Users/gaurav/phodex/backend/scripts/smoke_test_codex_worker.sh`
  - or `PHODEX_GOOGLE_ID_TOKEN=<google_id_token>` instead of JWT.

## Local development
```bash
make install
make migrate
make run
```

## Laptop-only Codex worker test
For testing the real worker before deployment, use:
- [/Users/gaurav/phodex/backend/.env.laptop.example](/Users/gaurav/phodex/backend/.env.laptop.example)
- [/Users/gaurav/phodex/backend/docs/local-laptop-testing.md](/Users/gaurav/phodex/backend/docs/local-laptop-testing.md)

Start laptop infrastructure with:
```bash
docker compose -f docker-compose.yml -f docker-compose.laptop.yml up -d
```

The Android emulator should call the laptop backend at `http://10.0.2.2:8000`.

## Test
```bash
make test
```

## Core API groups
- `/account`
- `/auth`
- `/tasks`
- `/approvals`
- `/stream`
- `/devices`
- `/repos`
- `/health`

Extra visibility endpoints:
- `GET /tasks/{task_id}/issues` for error-focused task diagnostics

## Worker abstraction
`app/workers/base.py` defines `WorkerEngine`.
`app/workers/fake_worker.py` implements the V1 fake worker.
`app/workers/common/` holds the pieces shared by every subprocess-backed
engine: `subprocess_io.py` (spawn/stream/timeout), `context.py` (builds the
prompt + workdir from task state), `state.py` (shared runtime state), and
`orchestrator.py` (the dispatch/approval/cancel state machine).
`app/workers/codex/` runs tasks through the Codex CLI (`codex exec --json`).
`app/workers/claude/` runs tasks through the Claude Code CLI
(`claude -p ... --output-format stream-json`). Both are thin subclasses of
`SubprocessWorkerOrchestrator` supplying only their own command construction,
output parsing, and approval/timeout settings.

### Worker selection (deployment)
Use environment variables:
- `WORKER_ENGINE=fake` (default), `WORKER_ENGINE=codex`, or `WORKER_ENGINE=claude`

**Codex** (`app/workers/codex/`):
- `CODEX_COMMAND` (example: `codex`)
- `CODEX_ARGS` (space-separated args)
- `CODEX_PROMPT_STDIN=true|false`
- `CODEX_TIMEOUT_SECONDS` (process timeout)
- `CODEX_REQUIRE_INITIAL_APPROVAL=true|false`
- `CODEX_DEFAULT_WORKDIR` (fallback repo path if task context has no local path)

For the local worker, include `--ignore-user-config` in `CODEX_ARGS`. This keeps
the authenticated Codex CLI available but prevents interactive MCP connectors
(such as Figma, GitHub, or browser tools) from blocking an unattended task.

**Claude** (`app/workers/claude/`):
- `CLAUDE_COMMAND` (example: `claude`)
- `CLAUDE_EXTRA_ARGS` (space-separated args, appended after the fixed `-p <prompt> --output-format stream-json --verbose --permission-mode <mode>`)
- `CLAUDE_PERMISSION_MODE` (`bypassPermissions` for unattended runs)
- `CLAUDE_TIMEOUT_SECONDS` (process timeout)
- `CLAUDE_REQUIRE_INITIAL_APPROVAL=true|false`
- `CLAUDE_DEFAULT_WORKDIR` (fallback repo path if task context has no local path)

Unlike Codex, the Claude worker never asks the model for an `OUTCOME:` sentinel
line — the CLI's own terminal `result` event reports success/failure
structurally via `is_error`, so that signal drives the task's final status.

Both workers emit structured `task.log` payloads and support approval-gated
execution + cancellation. Keep them host-run for the local showcase, set the
matching `*_DEFAULT_WORKDIR` to a disposable repository, and use a logged-in
local CLI (`codex login` / `claude` interactive login) — the worker inherits
whatever session is already authenticated on the host.

## Recruiter demo

```bash
# Infra first; then run the backend on the host with WORKER_ENGINE=codex.
docker compose up -d
PHODEX_BASE_URL=http://127.0.0.1:8000 ./scripts/smoke_test_backend_platform.sh
```

The demo verifies liveness/readiness, an approval-gated task lifecycle, persisted SSE replay, and Prometheus metrics. Postgres is the audit/replay source of truth; Redis only distributes new live events and holds short-lived cache/rate-limit state.

Observability endpoints:
- `GET /health/live`
- `GET /health/ready`
- `GET /metrics`

## Security notes
- All task/device/repo/approval queries are scoped by authenticated user.
- JWT sessions are persisted (`Session` model) with revocation support.
- For tests/dev only, insecure fake Google tokens can be enabled with `ALLOW_INSECURE_TEST_TOKENS=true`.

## Event envelope
SSE and event list endpoints expose normalized envelopes:

```json
{
  "event_id": "evt_uuid",
  "task_id": "task_uuid",
  "sequence": 8,
  "type": "task.progress",
  "timestamp": "2026-04-22T12:00:00Z",
  "data": {
    "message": "Reading repository structure"
  }
}
```

SSE endpoints:
- `GET /tasks/{task_id}/stream`
- `GET /stream/tasks/{task_id}` (alias)

Optional query params:
- `after_sequence` for replay from a sequence cursor
- `live=false` to return replay backlog and close immediately (useful for deterministic tests)

Task failures include structured error fields when available (for phone rendering), for example:
- `error_code`: `APPROVAL_REJECTED`, `WORKER_ERROR`, `SESSION_LIMIT_REACHED`, `CONCURRENT_TASK_LIMIT_REACHED`
- `message`
- `is_retryable` (worker/runtime dependent)
