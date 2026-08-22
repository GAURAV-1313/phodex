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

## Device agent (connecting real repos)

The backend has no automatic way to discover your repos on its own — something
has to tell it what's on disk. `scripts/device_agent.py` is that something: it
registers this machine as a `Device`, scans configured directories for git
repos, and keeps them synced with periodic `/repos/sync` + `/devices/heartbeat`
calls, so the mobile app's "Desktop runtime" status and repo picker reflect
reality instead of requiring a hand-run `curl` sequence.

```bash
PHODEX_BASE_URL=http://127.0.0.1:8000 \
PHODEX_GOOGLE_ID_TOKEN='test-token|local-user|you@example.com|Your Name' \
PHODEX_WATCH_DIRS=~/code:~/projects \
python3 scripts/device_agent.py
```

Pass `PHODEX_AUTH_TOKEN` instead of `PHODEX_GOOGLE_ID_TOKEN` if you already
have a bearer JWT. `--once` registers, syncs, and sends a single heartbeat
without looping — useful for testing or a cron job instead of a long-running
process. See the script's own module docstring for the full list of env vars
(`PHODEX_DEVICE_NAME`, `PHODEX_SYNC_INTERVAL_SECONDS`,
`PHODEX_HEARTBEAT_INTERVAL_SECONDS`).

## Setting up real Google Sign-In

Both sides already do the real work — the mobile app calls the native Google
Sign-In SDK for a real ID token, and `GoogleAuthService.verify_id_token`
really validates it against Google. All that's missing is your own OAuth
client registration in Google Cloud Console:

1. In the [Google Cloud Console](https://console.cloud.google.com/), pick or
   create a project, then **APIs & Services → Credentials → Create
   Credentials → OAuth client ID**.
2. Configure the **OAuth consent screen** first if you haven't (External or
   Internal, whichever applies to you — for personal use, "Testing" mode with
   yourself as a test user is enough, no Google review needed).
3. Create **three** OAuth client IDs:
   - **Web application** — this is the one the backend validates tokens
     against. No redirect URI needed for this app's flow.
   - **iOS** — bundle ID `com.phodex.mobile`.
   - **Android** — package name `com.phodex.mobile`, plus your debug (and
     later release) keystore's SHA-1 fingerprint. Get the debug one with:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
4. Set the **Web** client ID as `GOOGLE_CLIENT_ID` in the backend's `.env`.
5. Build the mobile app with the other two client IDs (see
   `mobile/README.md`'s "Real Google sign-in" section) — the **iOS** client
   ID also needs its *reversed* form pasted into
   `mobile/ios/Runner/Info.plist` (there's a marked placeholder there
   already — the file itself explains exactly what to replace).

No code changes needed beyond that — sign-in works for real as soon as these
are in place.

## Setting up real push notifications

The backend already sends real pushes (approval needed, task completed/
failed) via the FCM HTTP v1 API whenever `FIREBASE_SERVICE_ACCOUNT_JSON` and
`FIREBASE_PROJECT_ID` are set — see the comment above those two lines in
`.env.example`. To get there:

1. In the [Firebase console](https://console.firebase.google.com/), create a
   project (or use an existing one — it doesn't need to be the same project
   as your GCP OAuth setup above, though it can be).
2. **Project settings → Service accounts → Generate new private key.** Save
   the downloaded JSON file somewhere on this machine — **not inside the
   repo** — and set:
   ```bash
   FIREBASE_SERVICE_ACCOUNT_JSON=/absolute/path/to/that-file.json
   FIREBASE_PROJECT_ID=your-firebase-project-id
   ```
3. From `mobile/`, run `flutterfire configure` (installs via
   `dart pub global activate flutterfire_cli` if you don't have it) signed in
   to the same Firebase project. This single command replaces the placeholder
   `mobile/lib/firebase_options.dart` with real values and drops the matching
   native config files (`google-services.json` for Android,
   `GoogleService-Info.plist` for iOS) in the right place automatically —
   nothing to hand-edit.
4. **iOS only:** in Firebase console → Project settings → Cloud Messaging,
   upload an APNs authentication key (Apple Developer account → Keys). Then
   in Xcode, open `mobile/ios/Runner.xcworkspace` → Runner target → Signing &
   Capabilities → **+ Capability → Push Notifications** (this is the one step
   that has to happen in Xcode itself, not a config file — it wires up the
   entitlement safely).
5. Rebuild the app. The Account → Notifications screen will show a real
   "Enable notifications" prompt instead of "not set up on this build yet"
   once Firebase actually initializes.

Until you do this, push notifications degrade to a no-op everywhere (backend
silently skips sending; the app shows an honest "not set up yet" screen) —
nothing else in the app is affected by leaving it unconfigured.

## Connecting your phone remotely

The mobile app needs to know this backend's address before it can do
anything — and by default it only guesses a same-Wi-Fi address. Two setups:

**Same Wi-Fi as your laptop (easiest, works out of the box):**
1. Make sure the backend is running (`make run`).
2. On your phone, open the Phodex app → Welcome screen → **Connect to your
   desktop**.
3. On your laptop, open [http://localhost:8000/pair](http://localhost:8000/pair)
   in a browser and scan the QR code with the app (or type the address shown
   there by hand).

That's it — the app remembers this address until you reconnect elsewhere.

**From anywhere (cellular data, a different network) — recommended: Tailscale:**
1. Install [Tailscale](https://tailscale.com/download) on your laptop and on
   your phone, and sign in to the same account on both (free for personal
   use).
2. On your laptop, find its Tailscale address: `tailscale ip -4` (looks like
   `100.x.x.x`).
3. Add this to your backend's `.env`:
   ```bash
   PUBLIC_BASE_URL=http://100.x.x.x:8000
   ```
   (use the address from step 2)
4. Restart the backend (`make run`), then open
   [http://localhost:8000/pair](http://localhost:8000/pair) — it now shows a
   QR code for that Tailscale address instead of a guessed local one, with no
   "same Wi-Fi only" warning.
5. Scan it from the app, from anywhere Tailscale reaches (which is anywhere
   both devices have internet).

Tailscale forms a private, encrypted network between just your own devices —
nothing is exposed to the public internet, and no port forwarding is needed.
An `ngrok`/Cloudflare Tunnel URL works the same way if you'd rather use one of
those instead: just set `PUBLIC_BASE_URL` to whatever public URL they give
you.

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
- `/pair` (unauthenticated pairing page — see "Connecting your phone remotely")

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
