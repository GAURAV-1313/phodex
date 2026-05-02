# Phodex Backend Deployment Checklist

This checklist is for deploying the backend with the real command-based Codex worker.

## 1. Prepare server and runtime
- Install Python 3.11+ or use Docker.
- Install PostgreSQL 16+ (or managed Postgres).
- Install Codex runtime CLI on the server.
- Confirm Codex CLI is available: `codex --version`.
- Login once on the server account used by backend: `codex login`.

## 2. Configure environment
- Copy `/Users/gaurav/phodex/backend/.env.production.example` to `.env`.
- Set `DATABASE_URL` and `ALEMBIC_DATABASE_URL` to your production Postgres.
- Set a strong `JWT_SECRET_KEY`.
- Set real `GOOGLE_CLIENT_ID`.
- Keep `ALLOW_INSECURE_TEST_TOKENS=false`.
- Ensure `WORKER_ENGINE=codex`.
- Set `CODEX_COMMAND=codex`.
- Optionally set `CODEX_ARGS` if your runtime supports a structured output mode.

## 3. Run migrations
- `cd /Users/gaurav/phodex/backend`
- `alembic upgrade head`

## 4. Start backend
- Docker:
  - `docker compose up -d --build`
- Or Python:
  - `uvicorn app.main:app --host 0.0.0.0 --port 8000`

## 5. Verify health
- `curl -fsS http://127.0.0.1:8000/health`

## 6. Run end-to-end smoke test
- Use either an existing app JWT or Google ID token:
  - `export PHODEX_BASE_URL=http://127.0.0.1:8000`
  - `export PHODEX_BEARER_TOKEN="<jwt>"` or `export PHODEX_GOOGLE_ID_TOKEN="<google_id_token>"`
- Run:
  - `/Users/gaurav/phodex/backend/scripts/smoke_test_codex_worker.sh`

The smoke test validates:
- task creation
- approval requested
- approval resolve
- worker run/completion (or failure reason)
- persisted events/messages
- SSE replay endpoint output

## 7. Post-deploy checks
- Verify logs contain worker lifecycle and no repeated runtime failures.
- Confirm `/tasks/{id}/stream` events are visible from mobile client.
- Confirm `/account/usage` and `/account/limits` return expected values.

## 8. Rollback basics
- Switch to fake worker quickly if needed:
  - set `WORKER_ENGINE=fake`
  - restart backend
- Keep DB schema as-is; no rollback required for worker engine switch.
