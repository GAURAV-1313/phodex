# Graph Report - phodex  (2026-08-20)

## Corpus Check
- 244 files · ~67,434 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2018 nodes · 4069 edges · 132 communities (112 shown, 20 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 327 edges (avg confidence: 0.54)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `35526597`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- datetime.py
- FlutterWindow
- ServiceRegistry
- claude/process_runner.py
- task_models.dart
- task_dto.dart
- mock_backend_store.dart
- AppDelegate
- account_dto.dart
- package:flutter_riverpod/flutter_riverpod.dart
- session_controller.dart
- codex/process_runner.py
- login
- my_application.cc
- repo_models.dart
- repo_dto.dart
- package:mobile/core/repositories/interfaces/interfaces.dart
- api_client.dart
- home_screen.dart
- api/git_ops.py
- EmailVerifier
- Phodex Android UI Design Spec
- repos_screen.dart
- repository_providers.dart
- account_models.dart
- mock_task_repository.dart
- session_screen.dart
- ApprovalService
- package:flutter/material.dart
- ConsumerWidget
- phodex_mascot.dart
- ai_engine_screen.dart
- stitch_ui.dart
- _
- Phodex Backend (FastAPI)
- RedisService
- package:mobile/core/domain/models/models.dart
- approval_models.dart
- fake_worker.py
- auth_dto.dart
- approval_dto.dart
- network_task_repository.dart
- _
- TaskService
- auth_service.py
- test_codex_worker_integration.py
- Phodex Backend Deployment Checklist
- network_repo_repository.dart
- package:mobile/core/network/api_client.dart
- db/session.py
- account_controller.dart
- approvals_screen.dart
- wWinMain
- api/repos.py
- Phodex mobile
- auth_controller.dart
- session_event_ordering.dart
- manifest.json
- User
- auth_models.dart
- Settings
- api/health.py
- UserAiSettingsService
- mock.dart
- opencode.json
- interfaces.dart
- git_models.dart
- account_repository.dart
- approval_repository.dart
- network.dart
- dto.dart
- recents_screen.dart
- test_claude_worker_integration.py
- smoke_test_codex_worker.sh
- git_dto.dart
- common_dto.dart
- check_laptop_runtime.sh
- MainActivity
- graphify.js
- CLAUDE.md
- smoke_test_backend_platform.sh
- mappers.dart
- LaunchImage.imageset/README.md
- win32_window.cpp
- context.py
- api/auth.py
- session_state.dart
- task_service.py
- git_ops_repository.dart
- Win32Window
- MessageHandler
- user_ai_settings_service.py
- service_registry.py
- EventService
- ApprovalRequest
- ApprovalStatus
- DateTime
- ProjectContext?
- String?
- SyncedRepository
- env.py
- TaskStatus
- ManagedSubprocess
- api/ai_settings.py
- api/approvals.py
- RegisterPlugins
- api/account.py
- _build_service_registry
- .__init__
- GitOperation
- GitOperationStatus
- approval_service.py
- session_event_reducer.dart
- session_reducer_test.dart
- apiClientProvider
- SessionController
- AiSettingsStatus

## God Nodes (most connected - your core abstractions)
1. `Settings` - 62 edges
2. `ServiceRegistry` - 60 edges
3. `TaskService` - 55 edges
4. `User` - 53 edges
5. `get_current_user()` - 46 edges
6. `EventService` - 46 edges
7. `get_services()` - 45 edges
8. `ORMModel` - 41 edges
9. `ApprovalService` - 36 edges
10. `RedisService` - 35 edges

## Surprising Connections (you probably didn't know these)
- `EncryptionKeyNotConfiguredError` --uses--> `Settings`  [INFERRED]
  backend/app/core/crypto.py → backend/app/core/config.py
- `JWTManager` --uses--> `Settings`  [INFERRED]
  backend/app/core/security.py → backend/app/core/config.py
- `TokenError` --uses--> `Settings`  [INFERRED]
  backend/app/core/security.py → backend/app/core/config.py
- `AccountService` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `LimitStatus` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py

## Import Cycles
- None detected.

## Communities (132 total, 20 thin omitted)

### Community 0 - "datetime.py"
Cohesion: 0.07
Nodes (49): Base, ApprovalRequest, Artifact, Device, ApprovalStatus, GitOperationStatus, GitOperation, TimestampMixin (+41 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.13
Nodes (13): DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow, flutter_controller_ (+5 more)

### Community 2 - "ServiceRegistry"
Cohesion: 0.21
Nodes (29): get_current_user(), get_services(), Depends, Request, cancel_task(), create_task(), get_task(), list_events() (+21 more)

### Community 3 - "claude/process_runner.py"
Cohesion: 0.29
Nodes (14): extract_assistant_text(), extract_result_subtype(), extract_result_summary(), extract_tool_use_summaries(), is_error_result(), is_result_event(), is_system_init(), Pure functions for parsing `claude -p ... --output-format stream-json` events.… (+6 more)

### Community 4 - "task_models.dart"
Cohesion: 0.04
Nodes (47): account_models.dart, approval_models.dart, auth_models.dart, git_models.dart, approvals, cancelledAt, code, content (+39 more)

### Community 5 - "task_dto.dart"
Cohesion: 0.05
Nodes (42): approvals, cancelledAt, code, content, createdAt, currentPhase, data, errorMessage (+34 more)

### Community 6 - "mock_backend_store.dart"
Cohesion: 0.04
Nodes (47): _addIssue, _aiSettings, _approvalsById, approve, cancelTask, confirmCommit, createTask, discardCommit (+39 more)

### Community 7 - "AppDelegate"
Cohesion: 0.06
Nodes (25): Any, Cocoa, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS, FlutterPluginRegistry (+17 more)

### Community 8 - "account_dto.dart"
Cohesion: 0.09
Nodes (22): int?, activeSessions, cancelledTasks, completedTasks, currentConcurrentTasks, failedTasks, fromJson, generatedAt (+14 more)

### Community 9 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.11
Nodes (24): AsyncNotifier, repoRepositoryProvider, taskRepositoryProvider, saveSettings, build, createTask, HomeTasksController, refresh (+16 more)

### Community 10 - "session_controller.dart"
Cohesion: 0.13
Nodes (14): _applyIncomingEvent, approve, cancelTask, continueWithNewTask, disposeController, _init, _ref, refresh (+6 more)

### Community 11 - "codex/process_runner.py"
Cohesion: 0.17
Nodes (12): extract_assistant_message(), extract_content_text(), extract_final_summary(), is_blocked_outcome(), Pure functions for parsing structured JSON lines emitted by the Codex runtime., ProcessRunner, Process, UUID (+4 more)

### Community 12 - "login"
Cohesion: 0.08
Nodes (43): client(), login(), AsyncClient, fixture, AsyncClient, test_account_me_reports_device_online_status(), test_account_usage_limits_and_task_issues(), _wait_for_status() (+35 more)

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
Cohesion: 0.08
Nodes (27): getAccountSummary, getLimitStatus, getUsageSummary, _store, getStatus, _store, update, approve (+19 more)

### Community 17 - "api_client.dart"
Cohesion: 0.08
Nodes (23): Dio, Dio get, Future, _accessToken, _authOptions, baseUrl, clearSession, config (+15 more)

### Community 18 - "home_screen.dart"
Cohesion: 0.12
Nodes (17): children, _composer, createState, _CurrentTask, dispose, _FadingRow, HomeScreen, _HomeScreenState (+9 more)

### Community 19 - "api/git_ops.py"
Cohesion: 0.42
Nodes (9): confirm_git_commit(), discard_git_commit(), prepare_git_commit(), Depends, post, UUID, GitConfirmRequest, GitOperationOut (+1 more)

### Community 20 - "EmailVerifier"
Cohesion: 0.11
Nodes (18): Colors, EmailVerifier, export_do_not_send_csv(), export_sendable_csv(), main(), parse_csv_data(), print_header(), print_summary() (+10 more)

### Community 21 - "Phodex Android UI Design Spec"
Cohesion: 0.07
Nodes (26): 10. Empty / Loading / Error States, 11. Motion and polish, 12. Accessibility, 13. V1 Scope Boundaries, 14. Compose Implementation Notes (Next), 15. Design Review Checklist, 16. Changelog, 1. Purpose (+18 more)

### Community 22 - "repos_screen.dart"
Cohesion: 0.08
Nodes (27): Color, ConsumerState, ConsumerStatefulWidget, _pickRepository, repositoriesProvider, build, color, createState (+19 more)

### Community 23 - "repository_providers.dart"
Cohesion: 0.10
Nodes (17): ApiConfig, aiSettingsRepositoryProvider, authRepositoryProvider, mockBackendStoreProvider, sessionEventParserProvider, sessionStreamRepositoryProvider, AiSettingsRepository, getStatus (+9 more)

### Community 24 - "account_models.dart"
Cohesion: 0.09
Nodes (22): activeSessions, cancelledTasks, completedTasks, currentConcurrentTasks, deviceLastSeenAt, deviceOnline, failedTasks, generatedAt (+14 more)

### Community 25 - "mock_task_repository.dart"
Cohesion: 0.09
Nodes (20): cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks, replyToTask (+12 more)

### Community 26 - "session_screen.dart"
Cohesion: 0.06
Nodes (37): bool get, gitOpsRepositoryProvider, sessionProvider, approval, build, busy, _capitalize, _confirm (+29 more)

### Community 27 - "ApprovalService"
Cohesion: 0.28
Nodes (6): ApprovalService, ApprovalRequest, ApprovalStatus, async_sessionmaker, AsyncSession, UUID

### Community 28 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (26): GoRouter, main, state, fadeThroughPage, slideUpPage, main, main, main (+18 more)

### Community 29 - "ConsumerWidget"
Cohesion: 0.19
Nodes (12): ConsumerWidget, build, PhodexApp, appRouterProvider, accountDashboardProvider, AccountScreen, build, authControllerProvider (+4 more)

### Community 30 - "phodex_mascot.dart"
Cohesion: 0.05
Nodes (45): AnimationController, CustomPainter, dart:math, double get, _CommitPushSheet, _CommitPushSheetState, _ExecutionView, _ExecutionViewState (+37 more)

### Community 31 - "ai_engine_screen.dart"
Cohesion: 0.09
Nodes (25): aiSettingsStatusProvider, _AiEngineForm, _AiEngineFormState, AiEngineScreen, _anthropicKey, build, _claudeModel, _clearKey (+17 more)

### Community 32 - "stitch_ui.dart"
Cohesion: 0.07
Nodes (32): dart:ui, EdgeInsets, _RepositoryPicker, _ApprovalBlock, _CompletionCard, _LogsSheet, _Timeline, PhodexMascotGlyph (+24 more)

### Community 33 - "_"
Cohesion: 0.05
Nodes (42): app_colors.dart, app_radii.dart, app_spacing.dart, app_theme.dart, app_typography.dart, _, AppRadii, card (+34 more)

### Community 34 - "Phodex Backend (FastAPI)"
Cohesion: 0.08
Nodes (23): 1. Check local Codex CLI, 2. Create local env, 3. Start local infrastructure, 4. Install deps and migrate, 5. Start backend, 6. Run backend smoke test, 7. Connect Android to laptop backend, Local Laptop Backend Testing (+15 more)

### Community 35 - "RedisService"
Cohesion: 0.07
Nodes (13): EventBus, async_sessionmaker, AsyncSession, TaskEventEnvelope, UUID, Optional Redis adapter for ephemeral coordination; durable data stays in…, RedisService, async_sessionmaker (+5 more)

### Community 36 - "package:mobile/core/domain/models/models.dart"
Cohesion: 0.08
Nodes (24): dart:async, dart:convert, dart:io, toDomainWithIssues, SessionStreamRepository, subscribe, MockSessionStreamRepository, _apiClient (+16 more)

### Community 37 - "approval_models.dart"
Cohesion: 0.12
Nodes (16): ApprovalRequest, ApprovalStatus, ApprovalStatusX, copyWith, createdAt, description, fromValue, id (+8 more)

### Community 38 - "fake_worker.py"
Cohesion: 0.21
Nodes (5): ABC, UUID, WorkerDispatcher, UUID, WorkerEngine

### Community 39 - "auth_dto.dart"
Cohesion: 0.11
Nodes (17): AccountSummaryResponseDto, activeSessions, avatarUrl, createdAt, deviceLastSeenAt, deviceOnline, email, fromJson (+9 more)

### Community 40 - "approval_dto.dart"
Cohesion: 0.12
Nodes (15): Map, ApprovalRequestOutDto, createdAt, description, fromJson, id, items, kind (+7 more)

### Community 41 - "network_task_repository.dart"
Cohesion: 0.20
Nodes (9): _apiClient, cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks (+1 more)

### Community 42 - "_"
Cohesion: 0.09
Nodes (24): _, accentError, accentPrimary, accentPrimaryDeep, accentPrimarySoft, accentSuccess, accentWarning, AppColors (+16 more)

### Community 43 - "TaskService"
Cohesion: 0.23
Nodes (7): Task, ApprovalRequest, TaskEventEnvelope, TaskMessage, TaskStatus, UUID, TaskService

### Community 44 - "auth_service.py"
Cohesion: 0.19
Nodes (14): Centralizes translation of ServiceError subclasses into HTTP responses. Routes…, hash_password(), verify_password(), AuthService, datetime, ConflictError, ForbiddenError, LimitExceededError (+6 more)

### Community 45 - "test_codex_worker_integration.py"
Cohesion: 0.44
Nodes (8): codex_app(), codex_client(), codex_login(), AsyncClient, fixture, test_codex_worker_executes_runtime_after_approval(), _wait_for_status(), _write_stub_runtime()

### Community 46 - "Phodex Backend Deployment Checklist"
Cohesion: 0.20
Nodes (9): 1. Prepare server and runtime, 2. Configure environment, 3. Run migrations, 4. Start backend, 5. Verify health, 6. Run end-to-end smoke test, 7. Post-deploy checks, 8. Rollback basics (+1 more)

### Community 47 - "network_repo_repository.dart"
Cohesion: 0.13
Nodes (13): getRepository, getSelectedProjectContext, listRepositories, RepoRepository, selectRepository, MockRepoRepository, _apiClient, getRepository (+5 more)

### Community 48 - "package:mobile/core/network/api_client.dart"
Cohesion: 0.09
Nodes (22): PhodexApiClient, _apiClient, getAccountSummary, getLimitStatus, getUsageSummary, _apiClient, getStatus, update (+14 more)

### Community 49 - "db/session.py"
Cohesion: 0.39
Nodes (7): AsyncEngine, create_engine_and_sessionmaker(), create_schema(), drop_schema(), get_db_from_sessionmaker(), async_sessionmaker, AsyncSession

### Community 50 - "account_controller.dart"
Cohesion: 0.20
Nodes (11): LimitStatus, AccountSummary, accountRepositoryProvider, AccountDashboard, AccountDashboardController, build, limits, refresh (+3 more)

### Community 51 - "approvals_screen.dart"
Cohesion: 0.07
Nodes (30): IconData?, TaskIssue, icon, label, onTap, _SectionLabel, _Setting, _showComingSoon (+22 more)

### Community 52 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16() (+1 more)

### Community 53 - "api/repos.py"
Cohesion: 0.29
Nodes (18): get_repository(), list_repositories(), Depends, get, post, UUID, select_repository(), sync_repositories() (+10 more)

### Community 54 - "Phodex mobile"
Cohesion: 0.33
Nodes (5): Local demo: Android emulator, Phodex mobile, Real Google sign-in, UI-only mode, Verification

### Community 55 - "auth_controller.dart"
Cohesion: 0.18
Nodes (10): Completer, GoogleSignIn, _authenticateNatively, build, _events, _googleSignIn, _initialized, _tokenCompleter (+2 more)

### Community 56 - "session_event_ordering.dart"
Cohesion: 0.40
Nodes (4): bySequence, mergeOrderedEvents, sorted, return

### Community 57 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 58 - "User"
Cohesion: 0.27
Nodes (16): get_device(), heartbeat(), list_devices(), Depends, get, post, UUID, register_device() (+8 more)

### Community 59 - "auth_models.dart"
Cohesion: 0.22
Nodes (8): avatarUrl, createdAt, email, googleSub, id, name, updatedAt, UserProfile

### Community 60 - "Settings"
Cohesion: 0.17
Nodes (16): FastAPI, register_exception_handlers(), get_settings(), field_validator, Settings, configure_logging(), metrics_response(), configure_runtime_telemetry() (+8 more)

### Community 61 - "api/health.py"
Cohesion: 0.39
Nodes (7): health(), live(), get, Request, ready(), HealthResponse, BaseModel

### Community 62 - "UserAiSettingsService"
Cohesion: 0.16
Nodes (12): Per-user AI provider overrides. Optional by design: if a user never sets…, UserAiSettingsService, ClaudeWorkerEngine, async_sessionmaker, AsyncSession, Claude-specific wiring on top of the shared subprocess worker orchestrator., Worker adapter that runs tasks through the Claude Code CLI in headless mode…, ProcessRunner (+4 more)

### Community 63 - "mock.dart"
Cohesion: 0.20
Nodes (9): mock_account_repository.dart, mock_ai_settings_repository.dart, mock_approval_repository.dart, mock_auth_repository.dart, mock_backend_store.dart, mock_git_ops_repository.dart, mock_repo_repository.dart, mock_session_stream_repository.dart (+1 more)

### Community 64 - "opencode.json"
Cohesion: 0.50
Nodes (3): plugin, $schema, .opencode/plugins/graphify.js

### Community 65 - "interfaces.dart"
Cohesion: 0.22
Nodes (8): account_repository.dart, ai_settings_repository.dart, approval_repository.dart, auth_repository.dart, git_ops_repository.dart, repo_repository.dart, session_stream_repository.dart, task_repository.dart

### Community 66 - "git_models.dart"
Cohesion: 0.10
Nodes (19): commitMessage, copyWith, diffStatOutput, errorMessage, fromValue, GitOperation, GitOperationStatus, GitOperationStatusX (+11 more)

### Community 67 - "account_repository.dart"
Cohesion: 0.29
Nodes (6): AccountRepository, getAccountSummary, getLimitStatus, getUsageSummary, MockAccountRepository, NetworkAccountRepository

### Community 68 - "approval_repository.dart"
Cohesion: 0.29
Nodes (6): ApprovalRepository, approve, listPending, reject, MockApprovalRepository, NetworkApprovalRepository

### Community 69 - "network.dart"
Cohesion: 0.22
Nodes (8): network_account_repository.dart, network_ai_settings_repository.dart, network_approval_repository.dart, network_auth_repository.dart, network_git_ops_repository.dart, network_repo_repository.dart, network_session_stream_repository.dart, network_task_repository.dart

### Community 70 - "dto.dart"
Cohesion: 0.29
Nodes (6): account_dto.dart, approval_dto.dart, auth_dto.dart, git_dto.dart, repo_dto.dart, task_dto.dart

### Community 71 - "recents_screen.dart"
Cohesion: 0.13
Nodes (18): homeTasksProvider, build, initState, _ActivityCard, build, createState, dispose, _filter (+10 more)

### Community 72 - "test_claude_worker_integration.py"
Cohesion: 0.44
Nodes (8): claude_app(), claude_client(), claude_login(), AsyncClient, fixture, test_claude_worker_executes_runtime_after_approval(), _wait_for_status(), _write_stub_runtime()

### Community 74 - "git_dto.dart"
Cohesion: 0.11
Nodes (17): AiSettingsStatusResponseDto, commitMessage, diffStatOutput, errorMessage, fromJson, GitOperationOutDto, hasAnthropicKey, hasOpenaiKey (+9 more)

### Community 75 - "common_dto.dart"
Cohesion: 0.50
Nodes (3): parse, parseDateTime, parseNullableDateTime

### Community 86 - "win32_window.cpp"
Cohesion: 0.18
Nodes (14): wchar_t, Scale(), Create, Destroy, UpdateTheme, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_ (+6 more)

### Community 87 - "context.py"
Cohesion: 0.15
Nodes (16): TaskMessage, compose_prompt(), ExecutionContextBuilder, TaskMessage, UUID, Builds an execution context (prompt text + workdir) from stored task state.…, ProcessRunnerProtocol, Lock (+8 more)

### Community 88 - "api/auth.py"
Cohesion: 0.27
Nodes (15): google_auth(), login(), me(), Depends, get, post, Request, register() (+7 more)

### Community 90 - "session_state.dart"
Cohesion: 0.10
Nodes (20): int get, List, TaskSummary, approvalRepositoryProvider, ApprovalsController, approve, build, refresh (+12 more)

### Community 91 - "task_service.py"
Cohesion: 0.46
Nodes (14): TaskMessageRole, TaskStatus, ApprovalRequestOut, BaseModel, TaskCreateRequest, TaskDetailResponse, TaskEventEnvelope, TaskEventsResponse (+6 more)

### Community 94 - "git_ops_repository.dart"
Cohesion: 0.29
Nodes (6): confirmCommit, discardCommit, GitOpsRepository, prepareCommit, MockGitOpsRepository, NetworkGitOpsRepository

### Community 95 - "Win32Window"
Cohesion: 0.20
Nodes (14): OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate, OnDestroy (+6 more)

### Community 97 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 99 - "user_ai_settings_service.py"
Cohesion: 0.23
Nodes (7): decrypt_secret(), encrypt_secret(), _fernet(), _get_fernet(), Encryption for secrets stored at rest (per-user AI provider API keys). Uses…, UUID, Internal use only (subprocess env building) — never expose decrypted keys over…

### Community 100 - "service_registry.py"
Cohesion: 0.16
Nodes (11): Depends, description, ge, get, Query, Request, StreamingResponse, TaskEventEnvelope (+3 more)

### Community 106 - "EventService"
Cohesion: 0.21
Nodes (5): EventService, Lock, FakeWorkerEngine, UUID, Fake worker for V1. TODO: Replace this with real Codex runtime integration…

### Community 114 - "env.py"
Cohesion: 0.38
Nodes (5): _resolve_database_url(), run_migrations_offline(), run_migrations_online(), EncryptionKeyNotConfiguredError, RuntimeError

### Community 116 - "ManagedSubprocess"
Cohesion: 0.18
Nodes (6): ManagedSubprocess, Process, Writes a follow-up line to stdin. Returns False if stdin is unavailable or…, Waits for exit with a timeout, killing the process if it fires. Always drains…, OnLine, StreamReader

### Community 117 - "api/ai_settings.py"
Cohesion: 0.27
Nodes (8): get_ai_settings(), Depends, get, update_ai_settings(), AiSettingsStatusResponse, AiSettingsUpdateRequest, BaseModel, put

### Community 118 - "api/approvals.py"
Cohesion: 0.33
Nodes (10): approve(), pending_approvals(), Depends, get, post, UUID, reject(), ApprovalDecisionRequest (+2 more)

### Community 120 - "api/account.py"
Cohesion: 0.40
Nodes (9): account_limits(), account_me(), account_usage(), Depends, get, AccountSummaryResponse, LimitStatusResponse, BaseModel (+1 more)

### Community 122 - "_build_service_registry"
Cohesion: 0.15
Nodes (11): JWTManager, datetime, Exception, UUID, TokenError, _build_service_registry(), async_sessionmaker, AsyncSession (+3 more)

### Community 126 - "approval_service.py"
Cohesion: 0.24
Nodes (5): CodexWorkerEngine, async_sessionmaker, AsyncSession, Codex-specific wiring on top of the shared subprocess worker orchestrator., Production-oriented worker adapter for running a real Codex runtime command.…

### Community 127 - "session_event_reducer.dart"
Cohesion: 0.22
Nodes (8): approvalId, approvals, copyWith, errorCode, issues, mergedEvents, reduceSessionWithEvent, task

### Community 128 - "session_reducer_test.dart"
Cohesion: 0.29
Nodes (6): baseState, event, main, package:mobile/core/session/session_event_ordering.dart, package:mobile/features/session/application/session_event_reducer.dart, package:mobile/features/session/application/session_state.dart

### Community 129 - "apiClientProvider"
Cohesion: 0.60
Nodes (5): apiClientProvider, apiConfigProvider, AuthController, signIn, signOut

### Community 130 - "SessionController"
Cohesion: 0.67
Nodes (3): AsyncValue, SessionController, StateNotifier

## Knowledge Gaps
- **754 isolated node(s):** `$schema`, `.opencode/plugins/graphify.js`, `smoke_test_backend_platform.sh script`, `Colors`, `main` (+749 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **20 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Settings` connect `Settings` to `datetime.py`, `ServiceRegistry`, `claude/process_runner.py`, `codex/process_runner.py`, `RedisService`, `fake_worker.py`, `TaskService`, `auth_service.py`, `test_codex_worker_integration.py`, `UserAiSettingsService`, `test_claude_worker_integration.py`, `task_service.py`, `user_ai_settings_service.py`, `service_registry.py`, `EventService`, `env.py`, `_build_service_registry`, `.__init__`, `approval_service.py`?**
  _High betweenness centrality (0.052) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/material.dart`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Why does `ServiceRegistry` connect `ServiceRegistry` to `datetime.py`, `RedisService`, `service_registry.py`, `_build_service_registry`, `fake_worker.py`, `ApprovalService`, `EventService`, `TaskService`, `auth_service.py`, `api/git_ops.py`, `api/ai_settings.py`, `api/approvals.py`, `api/repos.py`, `api/account.py`, `User`, `api/auth.py`, `Settings`, `UserAiSettingsService`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **Are the 17 inferred relationships involving `Settings` (e.g. with `EncryptionKeyNotConfiguredError` and `JWTManager`) actually correct?**
  _`Settings` has 17 INFERRED edges - model-reasoned connections that need verification._
- **Are the 13 inferred relationships involving `ServiceRegistry` (e.g. with `Settings` and `AccountService`) actually correct?**
  _`ServiceRegistry` has 13 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `TaskService` (e.g. with `ServiceRegistry` and `Settings`) actually correct?**
  _`TaskService` has 23 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `User` (e.g. with `Base` and `TimestampMixin`) actually correct?**
  _`User` has 4 INFERRED edges - model-reasoned connections that need verification._