# Phodex Cloud runtime

The original design runs the backend **on your laptop**: the worker spawns the
Claude/Codex CLI as a local subprocess and git operates on repositories that
already live on disk. Close the laptop and nothing runs.

`RUNTIME_MODE=cloud` runs the same backend **on a server**. Users connect GitHub
repositories, which are cloned under `WORKSPACES_ROOT`, and the worker engine
executes tasks there. The server registers itself as a synthetic device named
"Phodex Cloud" for every user, so the mobile app's runtime status shows online
without any laptop involved. Both modes share every other code path (tasks,
approvals, SSE, commit-and-push).

## What changes in cloud mode

| Desktop mode | Cloud mode |
|---|---|
| `scripts/device_agent.py` registers the laptop and syncs repo metadata | The server upserts a "Phodex Cloud" device per user and heartbeats it itself |
| Repos come from `/repos/sync` (paths on the laptop) | Repos come from `POST /repos/github/connect` (cloned into `WORKSPACES_ROOT/<user>/<owner>__<repo>`) |
| CLI inherits `claude login` on the host | CLI uses `ANTHROPIC_API_KEY` (server-wide) or the user's own key from Account → AI engine |
| git push reuses the laptop's credentials | git push uses the user's GitHub token (stored encrypted) or `GITHUB_DEFAULT_TOKEN`, injected through an inline credential helper and scrubbed from logs |
| Discarding changes leaves the tree dirty for local inspection | Discarding resets the cloud workspace (`git checkout -- . && git clean -fd`) |

Before each task, a cloud workspace is fetched and fast-forwarded when its tree
is clean, and re-cloned if the disk was wiped (Fly machines have ephemeral
disks unless you mount a volume). A dirty tree is never reset before a task.

## Endpoints added

- `GET /runtime/public` (no auth): `mode`, `runner_name`, `demo_available`, `worker_engine`
- `GET /runtime`: mode, the caller's runner device, `has_github_token`
- `POST /repos/github/connect` `{url, branch?, token?}`: clone or refresh, returns a synced repository
- `PUT /repos/github/credentials` `{token}` / `{clear: true}`: store or clear the user's GitHub token
- `POST /auth/demo`: sign into the public demo account (404 when not configured)

## Deploying to Fly.io

1. **Postgres and Redis.** Create a [Neon](https://neon.tech) project and an
   [Upstash](https://upstash.com) Redis database (both have free tiers). Note
   the asyncpg/psycopg URLs and the `rediss://` URL.
2. **Secrets.** Generate keys:
   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(64))"      # JWT_SECRET_KEY
   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"  # SETTINGS_ENCRYPTION_KEY
   ```
3. **GitHub token.** Create a fine-grained PAT with *Contents: read and write*
   on the demo repository only, for `GITHUB_DEFAULT_TOKEN`. Users can store
   their own token from the app for other repositories.
4. **Launch.**
   ```bash
   cd backend
   flyctl launch --no-deploy --copy-config --name phodex-cloud
   flyctl secrets set \
     DATABASE_URL='postgresql+asyncpg://...' \
     ALEMBIC_DATABASE_URL='postgresql+psycopg://...' \
     REDIS_URL='rediss://...' \
     JWT_SECRET_KEY='...' SETTINGS_ENCRYPTION_KEY='...' \
     ANTHROPIC_API_KEY='sk-ant-...' GITHUB_DEFAULT_TOKEN='github_pat_...' \
     DEMO_ACCOUNT_EMAIL='demo@phodex.dev' DEMO_ACCOUNT_PASSWORD='...' \
     DEMO_REPO_ALLOWLIST='https://github.com/<you>/phodex-demo-playground' \
     GOOGLE_CLIENT_ID='...apps.googleusercontent.com'
   flyctl deploy
   ```
   Adjust `PUBLIC_BASE_URL` and `ALLOWED_ORIGINS` in `fly.toml` to your app name.
5. **Smoke test.**
   ```bash
   PHODEX_BASE_URL=https://phodex-cloud.fly.dev \
   PHODEX_REPO_URL=https://github.com/<you>/phodex-demo-playground \
   ./scripts/smoke_test_cloud_runtime.sh
   ```
6. **CI deploys.** `.github/workflows/backend.yml` deploys on every push to
   `main` once the `FLY_API_TOKEN` repository secret exists (`flyctl tokens
   create deploy -x 999999h`). Without the secret the job is skipped.

Railway works the same way: point a service at `backend/Dockerfile`, add the
Postgres and Redis plugins, and set the same variables.

## Running cloud mode locally

```bash
cd backend
cp .env.cloud.example .env   # then set DATABASE_URL/REDIS_URL to your local infra
docker compose up -d db redis
export RUNTIME_MODE=cloud WORKSPACES_ROOT=/tmp/phodex-workspaces ALLOW_LOCAL_GIT_URLS=true
make migrate && make run
```

`ALLOW_LOCAL_GIT_URLS=true` lets `POST /repos/github/connect` take a local path
(handy for trying the flow against a scratch repo without GitHub). The
integration tests in `tests/test_cloud_runtime.py` use exactly that.

## Managed Agents engine (`WORKER_ENGINE=managed`)

The cloud runner above still executes the Claude Code CLI inside this
server's container. The third engine hands execution to **Anthropic Managed
Agents** instead: Anthropic hosts the agent loop and a per-session sandbox,
the task's GitHub repository is mounted into that sandbox through Anthropic's
git proxy (the token never enters the container), and this backend only maps
the session's event stream onto Phodex tasks, messages, and approvals.

| WorkerEngine call | Managed Agents |
|---|---|
| `dispatch_task` | `sessions.create` with a `github_repository` resource, then `user.message` (stream-first) |
| `handle_approval` | `user.tool_confirmation` allow/deny — `bash` is `always_ask` on the agent, so every command is a phone approval |
| `handle_user_reply` | `user.message` |
| `cancel_task` | `user.interrupt` |
| event stream | `agent.message` → assistant message, `agent.tool_use`/`tool_result` → task log, `session.status_idle` → completion, `session.error` → failure, dropped streams reconnect with history consolidation |

Setup, once per deployment:

```bash
pip install anthropic
ANTHROPIC_API_KEY=sk-ant-... python3 scripts/setup_managed_agent.py --model claude-opus-5
# prints MANAGED_AGENT_ID / MANAGED_ENVIRONMENT_ID — add them to the environment
```

Then set `WORKER_ENGINE=managed`. No Node, no CLI, and no `WORKSPACES_ROOT`
are needed for execution; the cloud runner's repository registration
(`POST /repos/github/connect`) is still what tells Phodex which repository and
branch a task targets. Users' own Anthropic keys (Account → AI engine) are
honoured per task; otherwise the server's `ANTHROPIC_API_KEY` is used.
Managed Agents is a beta API: `tests/test_managed_worker.py` exercises the
mapping against a scripted fake client, and the first real run should be
watched in the Anthropic Console session viewer.

## Security notes for a public demo

- The demo account can only connect repositories in `DEMO_REPO_ALLOWLIST`.
- `MAX_CONCURRENT_TASKS_PER_USER=1` and the existing task rate limit keep one
  shared machine predictable.
- The approval gate (`CLAUDE_REQUIRE_INITIAL_APPROVAL=true`) stays on, so no
  task runs a CLI process until someone taps Approve on the phone.
- The container runs as a non-root user; the Claude CLI refuses
  `bypassPermissions` as root anyway.
- Tokens never appear in remote URLs, and streamed git output is scrubbed.
- Everything inside the workspace directory is disposable: the `phodex-demo-
  playground` repository should be one you are happy to let strangers edit.
