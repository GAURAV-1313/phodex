# Graph Report - phodex  (2026-08-17)

## Corpus Check
- 225 files · ~58,979 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1729 nodes · 3466 edges · 110 communities (94 shown, 16 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 280 edges (avg confidence: 0.53)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `68284789`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- TaskService
- Win32Window
- ServiceRegistry
- claude/process_runner.py
- task_models.dart
- task_dto.dart
- mock_backend_store.dart
- AppDelegate
- account_dto.dart
- repos_controller.dart
- session_controller.dart
- SubprocessWorkerOrchestrator
- login
- my_application.cc
- repo_models.dart
- repo_dto.dart
- package:mobile/core/repositories/interfaces/interfaces.dart
- api_client.dart
- home_screen.dart
- composer_bar.dart
- EmailVerifier
- Phodex Android UI Design Spec
- repos_screen.dart
- repository_providers.dart
- account_models.dart
- task_repository.dart
- session_screen.dart
- ApprovalService
- app_router.dart
- package:flutter/material.dart
- recents_screen.dart
- _
- StatelessWidget
- _
- Phodex Backend (FastAPI)
- EventBus
- network_session_stream_repository.dart
- approval_models.dart
- fake_worker.py
- auth_dto.dart
- approval_dto.dart
- network_task_repository.dart
- _
- orchestrator.py
- auth_service.py
- test_codex_worker_integration.py
- Phodex Backend Deployment Checklist
- network_repo_repository.dart
- mock_task_repository.dart
- session_event_reducer.dart
- account_controller.dart
- session_reducer_test.dart
- wWinMain
- approvals_screen.dart
- Phodex mobile
- auth_controller.dart
- package:mobile/core/domain/models/models.dart
- manifest.json
- _build_service_registry
- auth_models.dart
- main.py
- api/health.py
- EventService
- mock.dart
- opencode.json
- interfaces.dart
- widgets.dart
- network_account_repository.dart
- network_approval_repository.dart
- network.dart
- dto.dart
- SessionController
- test_claude_worker_integration.py
- smoke_test_codex_worker.sh
- apiClientProvider
- common_dto.dart
- check_laptop_runtime.sh
- MainActivity
- graphify.js
- CLAUDE.md
- smoke_test_backend_platform.sh
- mappers.dart
- LaunchImage.imageset/README.md
- Settings
- ManagedSubprocess
- codex/process_runner.py
- session_state.dart
- models.dart
- ApprovalRequest
- ApprovalStatus
- DateTime
- ProjectContext?
- String?
- SyncedRepository
- TaskEventEnvelope
- TaskStatus

## God Nodes (most connected - your core abstractions)
1. `Settings` - 54 edges
2. `TaskService` - 54 edges
3. `ServiceRegistry` - 51 edges
4. `User` - 46 edges
5. `EventService` - 42 edges
6. `get_current_user()` - 39 edges
7. `get_services()` - 38 edges
8. `ORMModel` - 38 edges
9. `ApprovalService` - 36 edges
10. `RedisService` - 35 edges

## Surprising Connections (you probably didn't know these)
- `JWTManager` --uses--> `Settings`  [INFERRED]
  backend/app/core/security.py → backend/app/core/config.py
- `TokenError` --uses--> `Settings`  [INFERRED]
  backend/app/core/security.py → backend/app/core/config.py
- `AccountService` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `LimitStatus` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `UsageSummary` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py

## Import Cycles
- None detected.

## Communities (110 total, 16 thin omitted)

### Community 0 - "TaskService"
Cohesion: 0.05
Nodes (54): FastAPI, Centralizes translation of ServiceError subclasses into HTTP responses. Routes…, register_exception_handlers(), Base, ApprovalRequest, Artifact, Device, ApprovalStatus (+46 more)

### Community 1 - "Win32Window"
Cohesion: 0.06
Nodes (53): RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+45 more)

### Community 2 - "ServiceRegistry"
Cohesion: 0.06
Nodes (122): account_limits(), account_me(), account_usage(), Depends, get, approve(), pending_approvals(), Depends (+114 more)

### Community 3 - "claude/process_runner.py"
Cohesion: 0.27
Nodes (15): extract_assistant_text(), extract_result_subtype(), extract_result_summary(), extract_tool_use_summaries(), is_error_result(), is_result_event(), is_system_init(), Pure functions for parsing `claude -p ... --output-format stream-json` events.… (+7 more)

### Community 4 - "task_models.dart"
Cohesion: 0.05
Nodes (42): bool get, approvals, cancelledAt, code, content, copyWith, createdAt, currentPhase (+34 more)

### Community 5 - "task_dto.dart"
Cohesion: 0.05
Nodes (42): approvals, cancelledAt, code, content, createdAt, currentPhase, data, errorMessage (+34 more)

### Community 6 - "mock_backend_store.dart"
Cohesion: 0.05
Nodes (41): dart:math, _addIssue, _approvalsById, approve, cancelTask, createTask, _emitEvent, _enableDynamicSimulation (+33 more)

### Community 7 - "AppDelegate"
Cohesion: 0.06
Nodes (25): Any, Cocoa, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS, FlutterPluginRegistry (+17 more)

### Community 8 - "account_dto.dart"
Cohesion: 0.09
Nodes (21): activeSessions, cancelledTasks, completedTasks, currentConcurrentTasks, failedTasks, fromJson, generatedAt, LimitStatusResponseDto (+13 more)

### Community 9 - "repos_controller.dart"
Cohesion: 0.12
Nodes (25): AsyncNotifier, List, approvalRepositoryProvider, repoRepositoryProvider, taskRepositoryProvider, ApprovalsController, approve, build (+17 more)

### Community 10 - "session_controller.dart"
Cohesion: 0.13
Nodes (14): _applyIncomingEvent, approve, cancelTask, continueWithNewTask, disposeController, _init, _ref, refresh (+6 more)

### Community 11 - "SubprocessWorkerOrchestrator"
Cohesion: 0.22
Nodes (8): ProcessRunnerProtocol, Lock, Process, UUID, Shared dispatch/approval/cancel state machine for subprocess-backed worker…, SubprocessWorkerOrchestrator, RuntimeState, Protocol

### Community 12 - "login"
Cohesion: 0.10
Nodes (25): client(), login(), AsyncClient, fixture, AsyncClient, test_account_usage_limits_and_task_issues(), _wait_for_status(), AsyncClient (+17 more)

### Community 13 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 14 - "repo_models.dart"
Cohesion: 0.08
Nodes (25): branch, createdAt, currentBranch, defaultBranch, deviceId, fromValue, gitRoot, id (+17 more)

### Community 15 - "repo_dto.dart"
Cohesion: 0.08
Nodes (24): branch, createdAt, currentBranch, defaultBranch, deviceId, fromJson, gitRoot, id (+16 more)

### Community 16 - "package:mobile/core/repositories/interfaces/interfaces.dart"
Cohesion: 0.11
Nodes (20): getAccountSummary, getLimitStatus, getUsageSummary, _store, approve, listPending, reject, _store (+12 more)

### Community 17 - "api_client.dart"
Cohesion: 0.09
Nodes (22): Dio, Dio get, Future, _accessToken, _authOptions, baseUrl, clearSession, config (+14 more)

### Community 18 - "home_screen.dart"
Cohesion: 0.12
Nodes (15): _composer, _ContextPill, createState, _CurrentTask, dispose, icon, label, onTap (+7 more)

### Community 19 - "composer_bar.dart"
Cohesion: 0.10
Nodes (22): _ExecutionView, _ExecutionViewState, build, ComposerBar, _ComposerBarState, _controller, createState, dispose (+14 more)

### Community 20 - "EmailVerifier"
Cohesion: 0.11
Nodes (18): Colors, EmailVerifier, export_do_not_send_csv(), export_sendable_csv(), main(), parse_csv_data(), print_header(), print_summary() (+10 more)

### Community 21 - "Phodex Android UI Design Spec"
Cohesion: 0.07
Nodes (26): 10. Empty / Loading / Error States, 11. Motion and polish, 12. Accessibility, 13. V1 Scope Boundaries, 14. Compose Implementation Notes (Next), 15. Design Review Checklist, 16. Changelog, 1. Purpose (+18 more)

### Community 22 - "repos_screen.dart"
Cohesion: 0.08
Nodes (34): Color, ConsumerWidget, IconData?, accountDashboardProvider, AccountScreen, build, icon, label (+26 more)

### Community 23 - "repository_providers.dart"
Cohesion: 0.13
Nodes (15): ApiConfig, PhodexApiClient, authRepositoryProvider, mockBackendStoreProvider, sessionEventParserProvider, sessionStreamRepositoryProvider, AuthRepository, MockAuthRepository (+7 more)

### Community 24 - "account_models.dart"
Cohesion: 0.09
Nodes (21): int?, activeSessions, cancelledTasks, completedTasks, currentConcurrentTasks, failedTasks, generatedAt, LimitStatus (+13 more)

### Community 25 - "task_repository.dart"
Cohesion: 0.17
Nodes (11): cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks, replyToTask (+3 more)

### Community 26 - "session_screen.dart"
Cohesion: 0.10
Nodes (20): sessionProvider, approval, build, busy, createState, dispose, events, messages (+12 more)

### Community 27 - "ApprovalService"
Cohesion: 0.39
Nodes (4): ApprovalService, ApprovalRequest, ApprovalStatus, UUID

### Community 28 - "app_router.dart"
Cohesion: 0.10
Nodes (19): GoRouter, main, state, main, main, main, main, package:flutter_test/flutter_test.dart (+11 more)

### Community 29 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (24): build, PhodexApp, appRouterProvider, TaskIssue, main, build, contextModel, ContextPill (+16 more)

### Community 30 - "recents_screen.dart"
Cohesion: 0.14
Nodes (17): ConsumerState, ConsumerStatefulWidget, homeTasksProvider, build, HomeScreen, _HomeScreenState, _ActivityCard, build (+9 more)

### Community 31 - "_"
Cohesion: 0.16
Nodes (15): app_colors.dart, app_radii.dart, app_spacing.dart, app_theme.dart, app_typography.dart, _, AppTheme, dark (+7 more)

### Community 32 - "StatelessWidget"
Cohesion: 0.08
Nodes (27): EdgeInsets, _RepositoryChip, _RepositoryPicker, _ApprovalBlock, _CompletionCard, _LogsSheet, _Timeline, active (+19 more)

### Community 33 - "_"
Cohesion: 0.14
Nodes (16): _, AppRadii, card, global, input, pill, _, AppSpacing (+8 more)

### Community 34 - "Phodex Backend (FastAPI)"
Cohesion: 0.08
Nodes (23): 1. Check local Codex CLI, 2. Create local env, 3. Start local infrastructure, 4. Install deps and migrate, 5. Start backend, 6. Run backend smoke test, 7. Connect Android to laptop backend, Local Laptop Backend Testing (+15 more)

### Community 35 - "EventBus"
Cohesion: 0.18
Nodes (6): EventBus, async_sessionmaker, AsyncSession, TaskEventEnvelope, UUID, Queue

### Community 36 - "network_session_stream_repository.dart"
Cohesion: 0.20
Nodes (10): dart:async, dart:convert, _apiClient, _parser, subscribe, JsonSessionEventParser, parse, SessionEventParser (+2 more)

### Community 37 - "approval_models.dart"
Cohesion: 0.12
Nodes (16): ApprovalRequest, ApprovalStatus, ApprovalStatusX, copyWith, createdAt, description, fromValue, id (+8 more)

### Community 38 - "fake_worker.py"
Cohesion: 0.21
Nodes (5): ABC, UUID, WorkerDispatcher, UUID, WorkerEngine

### Community 39 - "auth_dto.dart"
Cohesion: 0.12
Nodes (15): AccountSummaryResponseDto, activeSessions, avatarUrl, createdAt, email, fromJson, generatedAt, googleSub (+7 more)

### Community 40 - "approval_dto.dart"
Cohesion: 0.12
Nodes (15): Map, ApprovalRequestOutDto, createdAt, description, fromJson, id, items, kind (+7 more)

### Community 41 - "network_task_repository.dart"
Cohesion: 0.11
Nodes (17): dart:io, toDomainWithIssues, _apiClient, cancelTask, createTask, getTaskDetail, listEvents, listIssues (+9 more)

### Community 42 - "_"
Cohesion: 0.14
Nodes (15): _, accentError, accentPrimary, accentSuccess, accentWarning, AppColors, bgCard, bgInput (+7 more)

### Community 43 - "orchestrator.py"
Cohesion: 0.15
Nodes (14): CodexWorkerEngine, async_sessionmaker, AsyncSession, Codex-specific wiring on top of the shared subprocess worker orchestrator., Production-oriented worker adapter for running a real Codex runtime command.…, compose_prompt(), ExecutionContextBuilder, async_sessionmaker (+6 more)

### Community 44 - "auth_service.py"
Cohesion: 0.18
Nodes (12): hash_password(), JWTManager, datetime, Exception, UUID, TokenError, verify_password(), AuthService (+4 more)

### Community 45 - "test_codex_worker_integration.py"
Cohesion: 0.44
Nodes (8): codex_app(), codex_client(), codex_login(), AsyncClient, fixture, test_codex_worker_executes_runtime_after_approval(), _wait_for_status(), _write_stub_runtime()

### Community 46 - "Phodex Backend Deployment Checklist"
Cohesion: 0.20
Nodes (9): 1. Prepare server and runtime, 2. Configure environment, 3. Run migrations, 4. Start backend, 5. Verify health, 6. Run end-to-end smoke test, 7. Post-deploy checks, 8. Rollback basics (+1 more)

### Community 47 - "network_repo_repository.dart"
Cohesion: 0.13
Nodes (13): getRepository, getSelectedProjectContext, listRepositories, RepoRepository, selectRepository, MockRepoRepository, _apiClient, getRepository (+5 more)

### Community 48 - "mock_task_repository.dart"
Cohesion: 0.20
Nodes (9): cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks, replyToTask (+1 more)

### Community 49 - "session_event_reducer.dart"
Cohesion: 0.22
Nodes (8): approvalId, approvals, copyWith, errorCode, issues, mergedEvents, reduceSessionWithEvent, task

### Community 50 - "account_controller.dart"
Cohesion: 0.20
Nodes (11): LimitStatus, AccountSummary, accountRepositoryProvider, AccountDashboard, AccountDashboardController, build, limits, refresh (+3 more)

### Community 51 - "session_reducer_test.dart"
Cohesion: 0.29
Nodes (6): baseState, event, main, package:mobile/core/session/session_event_ordering.dart, package:mobile/features/session/application/session_event_reducer.dart, package:mobile/features/session/application/session_state.dart

### Community 52 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16() (+1 more)

### Community 53 - "approvals_screen.dart"
Cohesion: 0.11
Nodes (17): approvalsProvider, approval, _ApprovalReview, ApprovalsScreen, build, _NoApprovals, onApprove, onReject (+9 more)

### Community 54 - "Phodex mobile"
Cohesion: 0.33
Nodes (5): Local demo: Android emulator, Phodex mobile, Real Google sign-in, UI-only mode, Verification

### Community 55 - "auth_controller.dart"
Cohesion: 0.18
Nodes (10): Completer, GoogleSignIn, _authenticateNatively, build, _events, _googleSignIn, _initialized, _tokenCompleter (+2 more)

### Community 56 - "package:mobile/core/domain/models/models.dart"
Cohesion: 0.15
Nodes (10): getMe, SessionStreamRepository, subscribe, MockSessionStreamRepository, NetworkSessionStreamRepository, bySequence, mergeOrderedEvents, sorted (+2 more)

### Community 57 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 58 - "_build_service_registry"
Cohesion: 0.24
Nodes (6): _build_service_registry(), async_sessionmaker, AsyncSession, FakeWorkerEngine, UUID, Fake worker for V1. TODO: Replace this with real Codex runtime integration…

### Community 59 - "auth_models.dart"
Cohesion: 0.22
Nodes (8): avatarUrl, createdAt, email, googleSub, id, name, updatedAt, UserProfile

### Community 60 - "main.py"
Cohesion: 0.17
Nodes (17): AsyncEngine, configure_logging(), metrics_response(), configure_runtime_telemetry(), instrument_fastapi(), FastAPI, Register FastAPI middleware before the application lifespan begins., Configure optional exporters and runtime integrations during startup. (+9 more)

### Community 61 - "api/health.py"
Cohesion: 0.39
Nodes (7): health(), live(), get, Request, ready(), HealthResponse, BaseModel

### Community 62 - "EventService"
Cohesion: 0.12
Nodes (12): async_sessionmaker, AsyncSession, EventService, ClaudeWorkerEngine, async_sessionmaker, AsyncSession, Claude-specific wiring on top of the shared subprocess worker orchestrator., Worker adapter that runs tasks through the Claude Code CLI in headless mode… (+4 more)

### Community 63 - "mock.dart"
Cohesion: 0.25
Nodes (7): mock_account_repository.dart, mock_approval_repository.dart, mock_auth_repository.dart, mock_backend_store.dart, mock_repo_repository.dart, mock_session_stream_repository.dart, mock_task_repository.dart

### Community 64 - "opencode.json"
Cohesion: 0.50
Nodes (3): plugin, $schema, .opencode/plugins/graphify.js

### Community 65 - "interfaces.dart"
Cohesion: 0.29
Nodes (6): account_repository.dart, approval_repository.dart, auth_repository.dart, repo_repository.dart, session_stream_repository.dart, task_repository.dart

### Community 66 - "widgets.dart"
Cohesion: 0.29
Nodes (6): approval_card.dart, composer_bar.dart, context_pill.dart, issue_card.dart, task_status_chip.dart, trace_card.dart

### Community 67 - "network_account_repository.dart"
Cohesion: 0.17
Nodes (10): AccountRepository, getAccountSummary, getLimitStatus, getUsageSummary, MockAccountRepository, _apiClient, getAccountSummary, getLimitStatus (+2 more)

### Community 68 - "network_approval_repository.dart"
Cohesion: 0.17
Nodes (10): ApprovalRepository, approve, listPending, reject, MockApprovalRepository, _apiClient, approve, listPending (+2 more)

### Community 69 - "network.dart"
Cohesion: 0.29
Nodes (6): network_account_repository.dart, network_approval_repository.dart, network_auth_repository.dart, network_repo_repository.dart, network_session_stream_repository.dart, network_task_repository.dart

### Community 70 - "dto.dart"
Cohesion: 0.33
Nodes (5): account_dto.dart, approval_dto.dart, auth_dto.dart, repo_dto.dart, task_dto.dart

### Community 71 - "SessionController"
Cohesion: 0.67
Nodes (3): AsyncValue, SessionController, StateNotifier

### Community 72 - "test_claude_worker_integration.py"
Cohesion: 0.44
Nodes (8): claude_app(), claude_client(), claude_login(), AsyncClient, fixture, test_claude_worker_executes_runtime_after_approval(), _wait_for_status(), _write_stub_runtime()

### Community 74 - "apiClientProvider"
Cohesion: 0.60
Nodes (5): apiClientProvider, apiConfigProvider, AuthController, signIn, signOut

### Community 75 - "common_dto.dart"
Cohesion: 0.50
Nodes (3): parse, parseDateTime, parseNullableDateTime

### Community 86 - "Settings"
Cohesion: 0.21
Nodes (10): _resolve_database_url(), run_migrations_offline(), run_migrations_online(), get_settings(), field_validator, Settings, UnauthorizedError, GoogleAuthService (+2 more)

### Community 87 - "ManagedSubprocess"
Cohesion: 0.14
Nodes (7): ManagedSubprocess, Process, Generic async subprocess runner shared by worker engines. Handles spawning,…, Writes a follow-up line to stdin. Returns False if stdin is unavailable or…, Waits for exit with a timeout, killing the process if it fires. Always drains…, OnLine, StreamReader

### Community 88 - "codex/process_runner.py"
Cohesion: 0.23
Nodes (10): extract_assistant_message(), extract_content_text(), extract_final_summary(), is_blocked_outcome(), Pure functions for parsing structured JSON lines emitted by the Codex runtime., ProcessRunner, Process, UUID (+2 more)

### Community 90 - "session_state.dart"
Cohesion: 0.15
Nodes (12): int get, TaskSummary, approvals, copyWith, events, isResolvingApproval, isSendingReply, issues (+4 more)

### Community 91 - "models.dart"
Cohesion: 0.33
Nodes (5): account_models.dart, approval_models.dart, auth_models.dart, repo_models.dart, task_models.dart

## Knowledge Gaps
- **617 isolated node(s):** `$schema`, `.opencode/plugins/graphify.js`, `smoke_test_backend_platform.sh script`, `Colors`, `main` (+612 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Settings` connect `Settings` to `TaskService`, `ServiceRegistry`, `claude/process_runner.py`, `fake_worker.py`, `test_claude_worker_integration.py`, `orchestrator.py`, `auth_service.py`, `test_codex_worker_integration.py`, `codex/process_runner.py`, `_build_service_registry`, `main.py`, `EventService`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Why does `ServiceRegistry` connect `ServiceRegistry` to `TaskService`, `fake_worker.py`, `auth_service.py`, `Settings`, `_build_service_registry`, `ApprovalService`, `main.py`, `EventService`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **Why does `EventService` connect `EventService` to `TaskService`, `ServiceRegistry`, `EventBus`, `claude/process_runner.py`, `fake_worker.py`, `orchestrator.py`, `SubprocessWorkerOrchestrator`, `codex/process_runner.py`, `_build_service_registry`, `ApprovalService`, `main.py`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Are the 15 inferred relationships involving `Settings` (e.g. with `JWTManager` and `TokenError`) actually correct?**
  _`Settings` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `TaskService` (e.g. with `ServiceRegistry` and `Settings`) actually correct?**
  _`TaskService` has 23 INFERRED edges - model-reasoned connections that need verification._
- **Are the 11 inferred relationships involving `ServiceRegistry` (e.g. with `Settings` and `AccountService`) actually correct?**
  _`ServiceRegistry` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `User` (e.g. with `Base` and `TimestampMixin`) actually correct?**
  _`User` has 4 INFERRED edges - model-reasoned connections that need verification._