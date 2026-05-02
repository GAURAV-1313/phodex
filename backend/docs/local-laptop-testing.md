# Local Laptop Backend Testing

Use this before deploying. It runs the FastAPI backend on your laptop, uses local Postgres, and launches your locally logged-in Codex CLI.

## 1. Check local Codex CLI

```bash
/Users/gaurav/phodex/backend/scripts/check_laptop_runtime.sh
```

If Codex is not logged in yet:

```bash
/Applications/Codex.app/Contents/Resources/codex login
```

## 2. Create local env

```bash
cd /Users/gaurav/phodex/backend
cp .env.laptop.example .env
```

The laptop env uses:

```text
WORKER_ENGINE=codex
CODEX_COMMAND=/Applications/Codex.app/Contents/Resources/codex
CODEX_ARGS=exec --json --skip-git-repo-check -
ALLOW_INSECURE_TEST_TOKENS=true
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5433/phodex
POSTGRES_IMAGE=arm64v8/postgres:16-alpine
POSTGRES_HOST_PORT=5433
```

For safer real-worker testing, point `CODEX_DEFAULT_WORKDIR` to a disposable repo or sandbox folder.

## 3. Start Postgres

```bash
cd /Users/gaurav/phodex/backend
docker compose -f docker-compose.yml -f docker-compose.laptop.yml up -d db
```

The laptop override maps Docker Postgres to `localhost:5433` so it does not conflict with a Mac-installed Postgres already using `5432`.

## 4. Install deps and migrate

```bash
cd /Users/gaurav/phodex/backend
/opt/homebrew/bin/python3.11 -m pip install -r requirements-dev.txt
alembic upgrade head
```

## 5. Start backend

```bash
cd /Users/gaurav/phodex/backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend docs will be available at:

```text
http://127.0.0.1:8000/docs
```

## 6. Run backend smoke test

Because `.env.laptop.example` enables local-only insecure test tokens, no Google setup is needed for this smoke test:

```bash
PHODEX_BASE_URL=http://127.0.0.1:8000 \
PHODEX_GOOGLE_ID_TOKEN='test-token|local-user|gaurav@example.com|Gaurav Local' \
/Users/gaurav/phodex/backend/scripts/smoke_test_codex_worker.sh
```

Expected flow:

```text
created -> waiting_approval -> approve -> running -> completed
```

If the Codex CLI returns a runtime/limit/auth error, the backend should persist it as task events/issues so the phone UI can show it.

## 7. Connect Android to laptop backend

Android emulator base URL:

```text
http://10.0.2.2:8000
```

Physical Android phone on same Wi-Fi:

```bash
ipconfig getifaddr en0
```

Then use:

```text
http://<your-laptop-ip>:8000
```

Keep backend bound to `0.0.0.0` for phone access.
