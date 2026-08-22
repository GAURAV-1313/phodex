# Graph Report - phodex  (2026-08-21)

## Corpus Check
- 252 files · ~74,259 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2184 nodes · 4384 edges · 141 communities (121 shown, 20 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 344 edges (avg confidence: 0.54)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `35526597`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- datetime.py
- FlutterWindow
- TaskService
- RedisService
- task_models.dart
- task_dto.dart
- mock_backend_store.dart
- GeneratedPluginRegistrant.swift
- account_dto.dart
- repos_controller.dart
- session_controller.dart
- GitService
- login
- my_application.cc
- repo_models.dart
- repo_dto.dart
- package:mobile/core/repositories/interfaces/interfaces.dart
- api_client.dart
- home_screen.dart
- sessions_screen.dart
- EmailVerifier
- Phodex Android UI Design Spec
- repos_screen.dart
- package:mobile/core/domain/models/models.dart
- account_models.dart
- mock_task_repository.dart
- session_screen.dart
- ApprovalService
- package:flutter/material.dart
- device_agent.py
- phodex_mascot.dart
- ai_engine_screen.dart
- stitch_ui.dart
- _
- Phodex Backend (FastAPI)
- EventBus
- repository_providers.dart
- approval_models.dart
- FakeWorkerEngine
- auth_dto.dart
- approval_dto.dart
- network_task_repository.dart
- app_colors.dart
- stagger_in.dart
- Settings
- test_codex_worker_integration.py
- Phodex Backend Deployment Checklist
- network_repo_repository.dart
- network_account_repository.dart
- State
- test_claude_output_parser.py
- account_screen.dart
- wWinMain
- ORMModel
- Phodex mobile
- auth_controller.dart
- ProcessRunner
- manifest.json
- api/git_ops.py
- auth_models.dart
- db/session.py
- api/health.py
- theme_mode_controller.dart
- mock.dart
- opencode.json
- interfaces.dart
- git_models.dart
- mock_account_repository.dart
- network_approval_repository.dart
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
- EventService
- api/auth.py
- List
- api/tasks.py
- network_git_ops_repository.dart
- Win32Window
- MessageHandler
- UserAiSettingsService
- stream_task_events_alias
- RepoSyncService
- ApprovalRequest
- ApprovalStatus
- DateTime
- ProjectContext?
- String?
- SyncedRepository
- models.dart
- TaskStatus
- claude/process_runner.py
- ServiceRegistry
- api/approvals.py
- RegisterPlugins
- get_services
- approvals_screen.dart
- .build
- GitOperation
- GitOperationStatus
- AppColors
- app_router.dart
- AiSettingsStatus
- account_screen_test.dart
- AppColorsContext
- TaskMessageRole
- approvals_screen_test.dart
- session_screen_test.dart
- widget_test.dart
- package:flutter_test/flutter_test.dart
- home_screen_test.dart
- sessions_screen_test.dart
- test_helpers.dart
- CustomPainter

## God Nodes (most connected - your core abstractions)
1. `ServiceRegistry` - 65 edges
2. `Settings` - 62 edges
3. `TaskService` - 55 edges
4. `User` - 54 edges
5. `get_services()` - 50 edges
6. `get_current_user()` - 47 edges
7. `EventService` - 46 edges
8. `ORMModel` - 42 edges
9. `ApprovalService` - 36 edges
10. `NotFoundError` - 36 edges

## Surprising Connections (you probably didn't know these)
- `EncryptionKeyNotConfiguredError` --uses--> `Settings`  [INFERRED]
  backend/app/core/crypto.py → backend/app/core/config.py
- `AccountService` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `LimitStatus` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `UsageSummary` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `ServiceRegistry` --uses--> `Settings`  [INFERRED]
  backend/app/services/service_registry.py → backend/app/core/config.py

## Import Cycles
- None detected.

## Communities (141 total, 20 thin omitted)

### Community 0 - "datetime.py"
Cohesion: 0.10
Nodes (36): _resolve_database_url(), run_migrations_offline(), run_migrations_online(), Base, ApprovalRequest, Artifact, Device, ApprovalStatus (+28 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.12
Nodes (15): DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow, flutter_controller_ (+7 more)

### Community 2 - "TaskService"
Cohesion: 0.14
Nodes (19): FastAPI, Centralizes translation of ServiceError subclasses into HTTP responses. Routes…, register_exception_handlers(), Task, ConflictError, ForbiddenError, LimitExceededError, NotFoundError (+11 more)

### Community 3 - "RedisService"
Cohesion: 0.12
Nodes (5): Optional Redis adapter for ephemeral coordination; durable data stays in…, RedisService, async_sessionmaker, AsyncSession, test_redis_cache_rate_limit_and_pubsub()

### Community 4 - "task_models.dart"
Cohesion: 0.05
Nodes (40): bool get, approvals, cancelledAt, code, content, copyWith, createdAt, currentPhase (+32 more)

### Community 5 - "task_dto.dart"
Cohesion: 0.05
Nodes (42): approvals, cancelledAt, code, content, createdAt, currentPhase, data, errorMessage (+34 more)

### Community 6 - "mock_backend_store.dart"
Cohesion: 0.04
Nodes (51): _addIssue, _aiSettings, _approvalsById, approve, cancelTask, confirmCommit, createTask, discardCommit (+43 more)

### Community 7 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (28): Any, Cocoa, Flutter, flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS (+20 more)

### Community 8 - "account_dto.dart"
Cohesion: 0.07
Nodes (28): activeSessions, cancelledTasks, completedTasks, createdAt, currentConcurrentTasks, expiresAt, failedTasks, fromJson (+20 more)

### Community 9 - "repos_controller.dart"
Cohesion: 0.15
Nodes (19): AsyncNotifier, repoRepositoryProvider, taskRepositoryProvider, saveSettings, build, createTask, HomeTasksController, refresh (+11 more)

### Community 10 - "session_controller.dart"
Cohesion: 0.06
Nodes (31): AsyncValue, _applyIncomingEvent, approve, cancelTask, continueWithNewTask, disposeController, _init, _ref (+23 more)

### Community 11 - "GitService"
Cohesion: 0.17
Nodes (11): GitService, async_sessionmaker, AsyncSession, GitOperation, GitOperationStatus, UUID, async_sessionmaker, AsyncSession (+3 more)

### Community 12 - "login"
Cohesion: 0.07
Nodes (51): client(), login(), AsyncClient, fixture, AsyncClient, test_account_me_reports_device_online_status(), test_account_usage_limits_and_task_issues(), _wait_for_status() (+43 more)

### Community 13 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 14 - "repo_models.dart"
Cohesion: 0.08
Nodes (26): branch, createdAt, currentBranch, defaultBranch, deviceId, deviceName, fromValue, gitRoot (+18 more)

### Community 15 - "repo_dto.dart"
Cohesion: 0.08
Nodes (25): branch, createdAt, currentBranch, defaultBranch, deviceId, deviceName, fromJson, gitRoot (+17 more)

### Community 16 - "package:mobile/core/repositories/interfaces/interfaces.dart"
Cohesion: 0.09
Nodes (23): getStatus, _store, update, approve, listPending, reject, _store, getMe (+15 more)

### Community 17 - "api_client.dart"
Cohesion: 0.06
Nodes (31): Dio, Dio get, FlutterSecureStorage?, Future, _accessToken, _authOptions, baseUrl, clearSession (+23 more)

### Community 18 - "home_screen.dart"
Cohesion: 0.09
Nodes (22): ConsumerState, ConsumerStatefulWidget, children, _composer, createState, _CurrentTask, dispose, _FadingRow (+14 more)

### Community 19 - "sessions_screen.dart"
Cohesion: 0.14
Nodes (17): SessionInfo, sessionsProvider, build, createState, onRevoke, _revoke, _revokeOthers, revoking (+9 more)

### Community 20 - "EmailVerifier"
Cohesion: 0.11
Nodes (18): Colors, EmailVerifier, export_do_not_send_csv(), export_sendable_csv(), main(), parse_csv_data(), print_header(), print_summary() (+10 more)

### Community 21 - "Phodex Android UI Design Spec"
Cohesion: 0.07
Nodes (26): 10. Empty / Loading / Error States, 11. Motion and polish, 12. Accessibility, 13. V1 Scope Boundaries, 14. Compose Implementation Notes (Next), 15. Design Review Checklist, 16. Changelog, 1. Purpose (+18 more)

### Community 22 - "repos_screen.dart"
Cohesion: 0.07
Nodes (33): Color, ConsumerWidget, accountDashboardProvider, AccountScreen, build, SessionsScreen, repositoriesProvider, build (+25 more)

### Community 23 - "package:mobile/core/domain/models/models.dart"
Cohesion: 0.12
Nodes (14): AiSettingsRepository, getStatus, update, getMe, MockAiSettingsRepository, _apiClient, getStatus, NetworkAiSettingsRepository (+6 more)

### Community 24 - "account_models.dart"
Cohesion: 0.07
Nodes (27): int?, activeSessions, cancelledTasks, completedTasks, createdAt, currentConcurrentTasks, deviceLastSeenAt, deviceOnline (+19 more)

### Community 25 - "mock_task_repository.dart"
Cohesion: 0.09
Nodes (20): cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks, replyToTask (+12 more)

### Community 26 - "session_screen.dart"
Cohesion: 0.05
Nodes (38): sessionProvider, approval, build, busy, _capitalize, _confirm, createState, _discard (+30 more)

### Community 27 - "ApprovalService"
Cohesion: 0.28
Nodes (6): ApprovalService, ApprovalRequest, ApprovalStatus, async_sessionmaker, AsyncSession, UUID

### Community 28 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (16): build, PhodexApp, appRouterProvider, TaskIssue, _showAppearancePicker, main, themeModeProvider, build (+8 more)

### Community 29 - "device_agent.py"
Cohesion: 0.22
Nodes (12): ApiClient, Config, _default_device_name(), discover_repos(), exchange_google_id_token(), _git(), load_config(), load_device_id() (+4 more)

### Community 30 - "phodex_mascot.dart"
Cohesion: 0.07
Nodes (26): AnimationController, dart:math, double get, build, color, colors, _controller, createState (+18 more)

### Community 31 - "ai_engine_screen.dart"
Cohesion: 0.09
Nodes (25): aiSettingsStatusProvider, _AiEngineForm, _AiEngineFormState, AiEngineScreen, _anthropicKey, build, _claudeModel, _clearKey (+17 more)

### Community 32 - "stitch_ui.dart"
Cohesion: 0.07
Nodes (33): dart:ui, EdgeInsets, _ApprovalBlock, _CompletionCard, _LogsSheet, _Timeline, PhodexMascotGlyph, active (+25 more)

### Community 33 - "_"
Cohesion: 0.05
Nodes (43): app_colors.dart, app_radii.dart, app_spacing.dart, app_theme.dart, app_typography.dart, _, AppRadii, card (+35 more)

### Community 34 - "Phodex Backend (FastAPI)"
Cohesion: 0.08
Nodes (24): 1. Check local Codex CLI, 2. Create local env, 3. Start local infrastructure, 4. Install deps and migrate, 5. Start backend, 6. Run backend smoke test, 7. Connect Android to laptop backend, Local Laptop Backend Testing (+16 more)

### Community 35 - "EventBus"
Cohesion: 0.18
Nodes (6): EventBus, async_sessionmaker, AsyncSession, TaskEventEnvelope, UUID, Queue

### Community 36 - "repository_providers.dart"
Cohesion: 0.09
Nodes (24): dart:async, dart:convert, ApiConfig, authRepositoryProvider, gitOpsRepositoryProvider, mockBackendStoreProvider, sessionEventParserProvider, sessionStreamRepositoryProvider (+16 more)

### Community 37 - "approval_models.dart"
Cohesion: 0.12
Nodes (16): ApprovalRequest, ApprovalStatus, ApprovalStatusX, copyWith, createdAt, description, fromValue, id (+8 more)

### Community 38 - "FakeWorkerEngine"
Cohesion: 0.13
Nodes (8): ABC, UUID, WorkerDispatcher, UUID, WorkerEngine, FakeWorkerEngine, UUID, Fake worker for V1. TODO: Replace this with real Codex runtime integration…

### Community 39 - "auth_dto.dart"
Cohesion: 0.11
Nodes (17): AccountSummaryResponseDto, activeSessions, avatarUrl, createdAt, deviceLastSeenAt, deviceOnline, email, fromJson (+9 more)

### Community 40 - "approval_dto.dart"
Cohesion: 0.12
Nodes (15): Map, ApprovalRequestOutDto, createdAt, description, fromJson, id, items, kind (+7 more)

### Community 41 - "network_task_repository.dart"
Cohesion: 0.11
Nodes (17): dart:io, toDomainWithIssues, _apiClient, cancelTask, createTask, getTaskDetail, listEvents, listIssues (+9 more)

### Community 42 - "app_colors.dart"
Cohesion: 0.07
Nodes (28): AppColors get, Color get, accentError, accentPrimary, accentPrimaryDeep, accentPrimarySoft, accentSuccess, accentWarning (+20 more)

### Community 43 - "stagger_in.dart"
Cohesion: 0.22
Nodes (9): build, child, createState, index, initState, StaggerIn, _StaggerInState, _visible (+1 more)

### Community 44 - "Settings"
Cohesion: 0.09
Nodes (33): get_settings(), field_validator, Settings, configure_logging(), metrics_response(), hash_password(), JWTManager, datetime (+25 more)

### Community 45 - "test_codex_worker_integration.py"
Cohesion: 0.22
Nodes (14): extract_assistant_message(), extract_content_text(), extract_final_summary(), is_blocked_outcome(), Pure functions for parsing structured JSON lines emitted by the Codex runtime., codex_app(), codex_client(), codex_login() (+6 more)

### Community 46 - "Phodex Backend Deployment Checklist"
Cohesion: 0.20
Nodes (9): 1. Prepare server and runtime, 2. Configure environment, 3. Run migrations, 4. Start backend, 5. Verify health, 6. Run end-to-end smoke test, 7. Post-deploy checks, 8. Rollback basics (+1 more)

### Community 47 - "network_repo_repository.dart"
Cohesion: 0.13
Nodes (13): getRepository, getSelectedProjectContext, listRepositories, RepoRepository, selectRepository, MockRepoRepository, _apiClient, getRepository (+5 more)

### Community 48 - "network_account_repository.dart"
Cohesion: 0.13
Nodes (13): PhodexApiClient, AuthRepository, MockAuthRepository, _apiClient, getAccountSummary, getLimitStatus, getUsageSummary, listSessions (+5 more)

### Community 49 - "State"
Cohesion: 0.24
Nodes (11): _CommitPushSheet, _CommitPushSheetState, _ExecutionView, _ExecutionViewState, _FollowUpTaskSheet, _FollowUpTaskSheetState, PhodexMascot, _PhodexMascotState (+3 more)

### Community 50 - "test_claude_output_parser.py"
Cohesion: 0.30
Nodes (13): extract_assistant_text(), extract_result_subtype(), extract_result_summary(), extract_tool_use_summaries(), is_error_result(), is_result_event(), is_system_init(), Pure functions for parsing `claude -p ... --output-format stream-json` events.… (+5 more)

### Community 51 - "account_screen.dart"
Cohesion: 0.09
Nodes (22): IconData?, fadeThroughPage, slideUpPage, _AppearanceOption, icon, label, mode, onTap (+14 more)

### Community 52 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16() (+1 more)

### Community 53 - "ORMModel"
Cohesion: 0.26
Nodes (22): get_current_context(), get_repository(), list_repositories(), Depends, get, post, UUID, select_repository() (+14 more)

### Community 54 - "Phodex mobile"
Cohesion: 0.33
Nodes (5): Local demo: Android emulator, Phodex mobile, Real Google sign-in, UI-only mode, Verification

### Community 55 - "auth_controller.dart"
Cohesion: 0.17
Nodes (15): Completer, GoogleSignIn, apiClientProvider, apiConfigProvider, AuthController, _authenticateNatively, build, _events (+7 more)

### Community 56 - "ProcessRunner"
Cohesion: 0.21
Nodes (7): EncryptionKeyNotConfiguredError, ProcessRunner, Lock, Process, UUID, Looks up this task's owner's optional API-key/model override. Returns (env,…, RuntimeError

### Community 57 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 58 - "api/git_ops.py"
Cohesion: 0.39
Nodes (10): confirm_git_commit(), discard_git_commit(), prepare_git_commit(), Depends, post, UUID, GitOperationStatus, GitConfirmRequest (+2 more)

### Community 59 - "auth_models.dart"
Cohesion: 0.22
Nodes (8): avatarUrl, createdAt, email, googleSub, id, name, updatedAt, UserProfile

### Community 60 - "db/session.py"
Cohesion: 0.39
Nodes (7): AsyncEngine, create_engine_and_sessionmaker(), create_schema(), drop_schema(), get_db_from_sessionmaker(), async_sessionmaker, AsyncSession

### Community 61 - "api/health.py"
Cohesion: 0.39
Nodes (7): health(), live(), get, Request, ready(), HealthResponse, BaseModel

### Community 62 - "theme_mode_controller.dart"
Cohesion: 0.20
Nodes (9): build, _prefsKey, _restore, setThemeMode, ThemeModeController, Notifier, package:shared_preferences/shared_preferences.dart, static const (+1 more)

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

### Community 67 - "mock_account_repository.dart"
Cohesion: 0.11
Nodes (16): AccountRepository, getAccountSummary, getLimitStatus, getUsageSummary, listSessions, revokeOtherSessions, revokeSession, getAccountSummary (+8 more)

### Community 68 - "network_approval_repository.dart"
Cohesion: 0.17
Nodes (10): ApprovalRepository, approve, listPending, reject, MockApprovalRepository, _apiClient, approve, listPending (+2 more)

### Community 69 - "network.dart"
Cohesion: 0.22
Nodes (8): network_account_repository.dart, network_ai_settings_repository.dart, network_approval_repository.dart, network_auth_repository.dart, network_git_ops_repository.dart, network_repo_repository.dart, network_session_stream_repository.dart, network_task_repository.dart

### Community 70 - "dto.dart"
Cohesion: 0.29
Nodes (6): account_dto.dart, approval_dto.dart, auth_dto.dart, git_dto.dart, repo_dto.dart, task_dto.dart

### Community 71 - "recents_screen.dart"
Cohesion: 0.09
Nodes (26): approvalRepositoryProvider, ApprovalsController, approve, build, refresh, reject, homeTasksProvider, build (+18 more)

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

### Community 87 - "EventService"
Cohesion: 0.10
Nodes (22): EventService, ClaudeWorkerEngine, async_sessionmaker, AsyncSession, Claude-specific wiring on top of the shared subprocess worker orchestrator., Worker adapter that runs tasks through the Claude Code CLI in headless mode…, ProcessRunner, Lock (+14 more)

### Community 88 - "api/auth.py"
Cohesion: 0.26
Nodes (14): google_auth(), login(), me(), Depends, get, post, Request, register() (+6 more)

### Community 90 - "List"
Cohesion: 0.08
Nodes (28): int get, LimitStatus, List, AccountSummary, TaskSummary, accountRepositoryProvider, AccountDashboard, AccountDashboardController (+20 more)

### Community 91 - "api/tasks.py"
Cohesion: 0.19
Nodes (36): cancel_task(), create_task(), get_task(), list_events(), list_messages(), list_task_issues(), list_tasks(), Depends (+28 more)

### Community 94 - "network_git_ops_repository.dart"
Cohesion: 0.17
Nodes (10): confirmCommit, discardCommit, GitOpsRepository, prepareCommit, MockGitOpsRepository, _apiClient, confirmCommit, discardCommit (+2 more)

### Community 95 - "Win32Window"
Cohesion: 0.23
Nodes (12): OnCreate, HWND, Win32Window, child_content_, GetClientArea, OnCreate, quit_on_close_, SetChildContent (+4 more)

### Community 97 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 99 - "UserAiSettingsService"
Cohesion: 0.12
Nodes (16): decrypt_secret(), encrypt_secret(), _fernet(), _get_fernet(), Encryption for secrets stored at rest (per-user AI provider API keys). Uses…, async_sessionmaker, AsyncSession, UUID (+8 more)

### Community 100 - "stream_task_events_alias"
Cohesion: 0.22
Nodes (9): Depends, description, ge, get, Query, Request, StreamingResponse, UUID (+1 more)

### Community 106 - "RepoSyncService"
Cohesion: 0.27
Nodes (6): async_sessionmaker, AsyncSession, ProjectContext, SyncedRepository, UUID, RepoSyncService

### Community 114 - "models.dart"
Cohesion: 0.29
Nodes (6): account_models.dart, approval_models.dart, auth_models.dart, git_models.dart, repo_models.dart, task_models.dart

### Community 116 - "claude/process_runner.py"
Cohesion: 0.13
Nodes (9): Owns the Claude Code runtime subprocess: spawning, output streaming, and…, Owns the Codex runtime subprocess: spawning, stdin/stdout wiring, and outcome…, ManagedSubprocess, Process, Generic async subprocess runner shared by worker engines. Handles spawning,…, Writes a follow-up line to stdin. Returns False if stdin is unavailable or…, Waits for exit with a timeout, killing the process if it fires. Always drains…, OnLine (+1 more)

### Community 117 - "ServiceRegistry"
Cohesion: 0.19
Nodes (22): get_ai_settings(), Depends, get, update_ai_settings(), get_current_user(), get_device(), heartbeat(), list_devices() (+14 more)

### Community 118 - "api/approvals.py"
Cohesion: 0.33
Nodes (10): approve(), pending_approvals(), Depends, get, post, UUID, reject(), ApprovalDecisionRequest (+2 more)

### Community 120 - "get_services"
Cohesion: 0.22
Nodes (24): account_limits(), account_me(), account_usage(), list_sessions(), Depends, get, post, UUID (+16 more)

### Community 122 - "approvals_screen.dart"
Cohesion: 0.15
Nodes (13): approvalsProvider, approval, _ApprovalReview, ApprovalsScreen, build, _NoApprovals, onApprove, onReject (+5 more)

### Community 123 - ".build"
Cohesion: 0.50
Nodes (3): compose_prompt(), TaskMessage, UUID

### Community 126 - "AppColors"
Cohesion: 1.00
Nodes (3): @immutable, AppColors, ThemeExtension

### Community 128 - "app_router.dart"
Cohesion: 0.29
Nodes (6): GoRouter, state, package:mobile/app/router/page_transitions.dart, package:mobile/features/home/presentation/recents_screen.dart, package:mobile/features/repos/presentation/repos_screen.dart, package:mobile/features/welcome/presentation/welcome_screen.dart

### Community 129 - "AiSettingsStatus"
Cohesion: 0.50
Nodes (4): AiSettingsStatus, aiSettingsRepositoryProvider, AiSettingsController, build

### Community 130 - "account_screen_test.dart"
Cohesion: 0.29
Nodes (6): drag, main, pump, scrollDown, settle, package:mobile/features/account/presentation/account_screen.dart

### Community 134 - "approvals_screen_test.dart"
Cohesion: 0.33
Nodes (5): main, pump, settle, textAnywhere, package:mobile/features/approvals/presentation/approvals_screen.dart

### Community 135 - "session_screen_test.dart"
Cohesion: 0.33
Nodes (5): main, pump, settle, textAnywhere, package:mobile/features/session/presentation/session_screen.dart

### Community 136 - "widget_test.dart"
Cohesion: 0.33
Nodes (5): buildTestApp, main, pump, settle, package:mobile/app/app.dart

### Community 137 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.40
Nodes (4): main, package:flutter_test/flutter_test.dart, package:integration_test/integration_test.dart, package:mobile/main.dart

### Community 138 - "home_screen_test.dart"
Cohesion: 0.40
Nodes (4): main, pump, settle, package:mobile/features/home/presentation/home_screen.dart

### Community 139 - "sessions_screen_test.dart"
Cohesion: 0.40
Nodes (4): main, pump, settle, package:mobile/features/account/presentation/sessions_screen.dart

### Community 141 - "test_helpers.dart"
Cohesion: 0.50
Nodes (3): main, package:mobile/features/ai_engine/presentation/ai_engine_screen.dart, test_helpers.dart

### Community 142 - "CustomPainter"
Cohesion: 0.67
Nodes (3): CustomPainter, _RobinGlyphPainter, _RobinPainter

## Knowledge Gaps
- **837 isolated node(s):** `$schema`, `.opencode/plugins/graphify.js`, `smoke_test_backend_platform.sh script`, `Colors`, `main` (+832 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **20 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `RedisService` connect `RedisService` to `datetime.py`, `TaskService`, `EventBus`, `Settings`, `ServiceRegistry`, `EventService`, `ApprovalService`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **Why does `login()` connect `login` to `Settings`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **Why does `Settings` connect `Settings` to `datetime.py`, `TaskService`, `UserAiSettingsService`, `RedisService`, `FakeWorkerEngine`, `test_claude_worker_integration.py`, `test_codex_worker_integration.py`, `claude/process_runner.py`, `ServiceRegistry`, `EventService`, `ProcessRunner`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Are the 13 inferred relationships involving `ServiceRegistry` (e.g. with `Settings` and `AccountService`) actually correct?**
  _`ServiceRegistry` has 13 INFERRED edges - model-reasoned connections that need verification._
- **Are the 17 inferred relationships involving `Settings` (e.g. with `EncryptionKeyNotConfiguredError` and `JWTManager`) actually correct?**
  _`Settings` has 17 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `TaskService` (e.g. with `ServiceRegistry` and `Settings`) actually correct?**
  _`TaskService` has 23 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `User` (e.g. with `Base` and `TimestampMixin`) actually correct?**
  _`User` has 4 INFERRED edges - model-reasoned connections that need verification._