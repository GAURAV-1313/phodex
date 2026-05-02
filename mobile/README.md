# Phodex Mobile (Flutter)

Android-first Flutter client for the Phodex backend.

## Current phase
Phase 1 implemented: UI-first with backend-contract-accurate mock data.

## Stack
- Flutter
- Riverpod
- go_router
- dio (reserved for Phase 2 API wiring)
- json_annotation + json_serializable tooling
- sse package (reserved for Phase 2 stream transport)

## App architecture
- `lib/app`: app shell + router
- `lib/core`: contracts, DTOs, repositories, providers, session utilities
- `lib/features`: home, session, repos, approvals, account
- `lib/shared`: theme tokens and reusable widgets

## Implemented screens
- Home
- Interactive Session
- Repositories
- Approvals
- Account

## Mock behavior coverage
- Task create/list/detail/reply/cancel
- Task event timeline (ordered by sequence)
- Approval requested/approved/rejected
- Issue surfaces (error_code/message)
- Repo selection as active project context
- Account usage and limits

## Test coverage
- DTO parsing from fixtures
- Event ordering and reducer behavior
- Widget tests for home/session/approvals/account
- Integration test for app navigation flow

## Phase 2 TODO
- Replace mock repositories with real network repositories
- Implement Google Sign-In + `/auth/google` token exchange
- Implement real SSE stream via `/tasks/{task_id}/stream`
- Persist auth token securely (Android Keystore)

## Run
```bash
flutter run
```

## Test
```bash
flutter test
```
