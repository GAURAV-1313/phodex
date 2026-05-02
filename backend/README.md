# Phodex Backend (FastAPI)

Production-oriented backend MVP for an Android-native Codex client.

## What this backend supports (V1)
- Google Sign-In authentication (`POST /auth/google`) with backend-issued JWT sessions
- Account visibility endpoints for phone UI (`/account/me`, `/account/usage`, `/account/limits`)
- Task lifecycle orchestration with persistent messages/events
- SSE streaming for live task events
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

2. Start with Docker:
```bash
docker compose up --build
```

3. Open docs:
- [http://localhost:8000/docs](http://localhost:8000/docs)

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

Start laptop Postgres with:
```bash
docker compose -f docker-compose.yml -f docker-compose.laptop.yml up -d db
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
`app/workers/codex_worker.py` runs a real runtime process via configurable command.

> TODO: Swap fake worker with real Codex runtime while preserving `WorkerEngine` and `WorkerDispatcher`.

### Worker selection (deployment)
Use environment variables:
- `WORKER_ENGINE=fake` (default) or `WORKER_ENGINE=codex`
- `CODEX_COMMAND` (example: `codex`)
- `CODEX_ARGS` (space-separated args)
- `CODEX_PROMPT_STDIN=true|false`
- `CODEX_TIMEOUT_SECONDS` (process timeout)
- `CODEX_REQUIRE_INITIAL_APPROVAL=true|false`
- `CODEX_DEFAULT_WORKDIR` (fallback repo path if task context has no local path)

The codex worker emits structured `task.log` payloads and supports approval-gated execution + cancellation.

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
