# Phodex — AI-Powered Remote Development Platform

A full-stack platform that connects a Flutter mobile app to AI coding workers (Claude, Codex) running on a developer's laptop — enabling remote, approval-gated AI-assisted git operations.

**Tech Stack:** FastAPI · Python 3.11 · PostgreSQL + AsyncPG · Redis · Firebase Cloud Messaging · Flutter/Dart · Riverpod · Alembic

---

## What It Does

Phodex lets developers create AI coding tasks from their phone, have them executed by Claude or Codex on their laptop, review and approve git changes remotely, and watch real-time event streams — all through a polished mobile interface.

```
Mobile App (Flutter)  →  FastAPI Backend  →  Worker (Claude/Codex)  →  Laptop Git Repo
       ↑                      ↓                       ↑                      ↑
   Push Notifications   Real-time Events      Subprocess Orchestrator    Human Approval
```

---

## Salient Features

### 🤖 Multi-Worker AI Orchestration
- **Pluggable worker engines** — Claude Code CLI and OpenAI Codex runtime as interchangeable adapters implementing a shared `WorkerEngine` interface
- **Subprocess lifecycle management** — spawn, stdin/stdout wiring, outcome parsing, cleanup via `ManagedSubprocess`
- **Generic orchestrator state machine** — shared dispatch/approval/cancel flow across all workers
- **Typed output parsers** — extract assistant messages, tool use, final summaries, and error states from JSON-lines output

### 🔐 Human-in-the-Loop Approval System
- **Git operation gating** — every commit requires explicit mobile approval before applying to the working tree
- **Prepare → Confirm/Discard workflow** — full diff visibility with `GitOperation` model tracking status
- **Approval request model** — tracks status, kind, description, and associated task
- **Pending approvals queue** — real-time sync via SSE event stream

### ⚡ Real-Time Event Streaming
- **SSE endpoint** — `GET /tasks/{id}/stream` with `StreamingResponse` for live task progress
- **Structured event envelope** — `TaskEventEnvelope` with typed roles (`user`, `assistant`, `system`, `tool_use`)
- **Session event reducer** — client-side state merging with approval-aware event handling
- **EventBus pattern** — async queue-based pub/sub for internal event distribution

### 🏗️ Backend Architecture

#### Service Registry (Central Dependency Injection)
Single registry resolves all 16 service dependencies — a single point of truth that prevents dependency drift across the API surface.

| Service | Responsibility |
|---------|----------------|
| `TaskService` | Task CRUD, lifecycle transitions, status management |
| `EventService` | Event persistence, EventBus pub/sub, SSE streaming |
| `ApprovalService` | Approval request lifecycle, approve/reject operations |
| `GitService` | Runs git commands on laptop working tree, tracks `GitOperation` |
| `AuthService` | Password auth with bcrypt hashing |
| `GoogleAuthService` | Google Sign-In with token exchange |
| `PushService` | FCM HTTP v1 API push notifications |
| `DeviceService` | Device registration, heartbeat, online status |
| `RepoSyncService` | Repository sync and `ProjectContext` management |
| `RedisService` | Ephemeral coordination, rate limiting cache |
| `AccountService` | User account summary, usage limits, session management |
| `UserAiSettingsService` | Per-user AI provider key management |
| `WorkerDispatcher` | Task dispatch, approval routing, user reply handling |
| `PairingService` | QR code generation, local IP discovery for device pairing |

#### API Surface (11 modules, 34 endpoints)

| Module | Endpoints | Method |
|--------|-----------|--------|
| **Auth** | `/register`, `/login`, `/google`, `/me` | POST × 3, GET × 1 |
| **Tasks** | `/`, `/{id}`, `/{id}/reply`, `/{id}/cancel`, `/{id}/messages`, `/{id}/events`, `/{id}/issues`, `/{id}/stream` | POST × 3, GET × 5 |
| **Approvals** | `/pending`, `/{id}/approve`, `/{id}/reject` | GET × 1, POST × 2 |
| **Repos** | `/sync`, `/`, `/{id}`, `/context/current`, `/{id}/select` | POST × 2, GET × 3 |
| **Git Ops** | `/{task_id}/git/prepare`, `/{task_id}/git/{op_id}/confirm`, `/{task_id}/git/{op_id}/discard` | POST × 3 |
| **Account** | `/me`, `/usage`, `/limits`, `/sessions`, `/sessions/{id}/revoke`, `/sessions/revoke-others` | GET × 4, POST × 2 |
| **Devices** | `/register`, `/heartbeat`, `/`, `/{id}` | POST × 2, GET × 2 |
| **Push** | `/register`, `/unregister` | POST × 2 |
| **AI Settings** | `/ai-settings` (get), `/ai-settings` (update) | GET × 1, PUT × 1 |
| **Health** | `/`, `/live`, `/ready` | GET × 3 |
| **Pairing** | `/` (QR page) | GET × 1 |

#### Database Models (14 models, Alembic migrations)
All models use `UUIDPrimaryKeyMixin` and `TimestampMixin` for consistent ID generation and audit trails.

| Model | Purpose |
|-------|---------|
| `User` | Authentication, profile, Google sub |
| `Task` | Core task entity with status machine (`pending` → `dispatched` → `executing` → `completed`/`cancelled`/`failed`) |
| `TaskEvent` | Event log for task lifecycle |
| `TaskMessage` | Conversational messages with role enum |
| `ApprovalRequest` | Human approval gate with status tracking |
| `Session` | User auth session with revoke support |
| `Device` | Registered mobile device with heartbeat |
| `ProjectContext` | Selected repo + branch on laptop |
| `SyncedRepository` | Synced git repository metadata |
| `GitOperation` | Pending/confirmed/discarded git changes |
| `PushSubscription` | FCM token per device |
| `Artifact` | Task output artifacts |
| `UserAiSettings` | Per-user encrypted AI provider keys |

#### Security & Infrastructure
- **Fernet encryption** for API keys stored in `UserAiSettings`
- **bcrypt password hashing** via `AuthService`
- **Session management** — multi-session tracking with selective revoke
- **Redis-backed rate limiting** with cache invalidation
- **Kubernetes-style health probes** — `/health`, `/live`, `/ready`
- **Structured logging** and application metrics endpoint

### 📱 Mobile App (Flutter)
- **Riverpod state management** — `AsyncNotifierProvider` pattern throughout
- **Repository abstraction** — `Network*Repository` + `Mock*Repository` pairs for testability
- **6 feature modules:** Home, Sessions, Repos, Approvals, Account, AI Engine Settings
- **Phodex Mascot** — animated `CustomPainter` widget with mood states tied to task status
- **Staggered animations** — custom `StaggerIn` widget for list item entrances
- **QR pairing flow** — device-to-laptop connection via QR code scan

---

## Complexity

| Dimension | Count |
|-----------|-------|
| Backend Python files | 91 |
| API modules | 11 |
| Service modules | 16 |
| API endpoints | 34 |
| Database models | 14 |
| Worker engines | 3 (Claude, Codex, Fake) |
| Test files | 15 |
| Async patterns | AsyncPG, SSE streaming, EventBus, subprocess I/O |

---

## Architecture Decisions

1. **Service Registry over per-route DI** — single resolution point prevents dependency drift across 34 endpoints
2. **Worker adapter pattern** — Claude and Codex share `WorkerEngine` interface; new AI providers require zero backend changes
3. **Approval gate before git apply** — safety-first design; workers suggest, humans decide
4. **SSE over WebSockets** — simpler server model, unidirectional event flow, native browser support
5. **Repository pattern on mobile** — identical domain models whether using network or mock store; enables offline-first testing

---

## Project Structure

```
backend/
├── app/
│   ├── api/            # 11 endpoint modules (FastAPI routers)
│   ├── core/           # Settings, config, encryption, logging, telemetry
│   ├── db/             # AsyncPG engine + session factory
│   ├── models/         # 14 SQLAlchemy models
│   ├── schemas/        # Pydantic DTOs
│   ├── services/       # 16 service modules
│   └── workers/
│       ├── claude/     # Claude Code CLI adapter (engine + process runner + parser)
│       ├── codex/      # Codex runtime adapter (engine + process runner + parser)
│       ├── common/     # Orchestrator, state machine, subprocess I/O, context builder
│       └── fake_worker.py  # Test stub
├── tests/              # 15 integration test files
└── alembic/            # Database migrations

mobile/
└── lib/
    ├── core/           # Network (Dio), repositories (network + mock), Riverpod providers
    ├── features/       # 6 feature modules (presentation + application layers)
    └── shared/         # Theme (AppColors, AppTypography), widgets (PhodexMascot, StitchUI)
```

---

*Built as a production-grade full-stack platform with async-first backend design, pluggable AI worker architecture, and human-in-the-loop safety controls.*
