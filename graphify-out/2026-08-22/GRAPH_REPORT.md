# Graph Report - phodex  (2026-08-21)

## Corpus Check
- 261 files · ~77,081 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2261 nodes · 4522 edges · 144 communities (123 shown, 21 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 344 edges (avg confidence: 0.54)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `35526597`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- datetime.py
- FlutterWindow
- NotFoundError
- main.py
- task_models.dart
- task_dto.dart
- mock_backend_store.dart
- GeneratedPluginRegistrant.swift
- account_dto.dart
- List
- session_controller.dart
- git_service.py
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
- package:mobile/shared/theme/theme.dart
- device_agent.py
- phodex_mascot.dart
- ai_engine_screen.dart
- stitch_ui.dart
- _
- Phodex Backend (FastAPI)
- TaskEventEnvelope
- network_session_stream_repository.dart
- approval_models.dart
- _build_service_registry
- auth_dto.dart
- approval_dto.dart
- network_task_repository.dart
- app_colors.dart
- stagger_in.dart
- auth_service.py
- test_codex_worker_integration.py
- Phodex Backend Deployment Checklist
- repo_repository.dart
- repository_providers.dart
- State
- claude/process_runner.py
- account_screen.dart
- wWinMain
- api/repos.py
- Phodex mobile
- auth_controller.dart
- ProcessRunner
- manifest.json
- TaskService
- Settings
- db/session.py
- api/health.py
- package:flutter_riverpod/flutter_riverpod.dart
- mock.dart
- opencode.json
- interfaces.dart
- git_models.dart
- network_account_repository.dart
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
- orchestrator.py
- api/auth.py
- account_controller.dart
- ORMModel
- git_ops_repository.dart
- Win32Window
- MessageHandler
- UserAiSettingsService
- stream_task_events_alias
- ProcessRunner
- ApprovalRequest
- ApprovalStatus
- DateTime
- ProjectContext?
- String?
- SyncedRepository
- connect_desktop_screen.dart
- TaskStatus
- ManagedSubprocess
- User
- get_current_user
- RegisterPlugins
- ServiceRegistry
- approvals_screen.dart
- utcnow
- GitOperation
- GitOperationStatus
- api/devices.py
- package:flutter/material.dart
- security.py
- session_state.dart
- connect_desktop_controller.dart
- DeviceService
- TaskMessageRole
- crypto.py
- qr_scan_screen.dart
- pairing.py
- FakeWorkerEngine
- env.py
- test_pairing.py
- sessionProvider
- .__init__
- CustomPainter
- TaskDetailResponseDto

## God Nodes (most connected - your core abstractions)
1. `ServiceRegistry` - 67 edges
2. `Settings` - 64 edges
3. `TaskService` - 55 edges
4. `User` - 54 edges
5. `get_services()` - 52 edges
6. `get_current_user()` - 47 edges
7. `EventService` - 46 edges
8. `ORMModel` - 42 edges
9. `ApprovalService` - 36 edges
10. `NotFoundError` - 36 edges

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

## Communities (144 total, 21 thin omitted)

### Community 0 - "datetime.py"
Cohesion: 0.28
Nodes (12): Base, Artifact, GitOperation, TimestampMixin, UUIDPrimaryKeyMixin, ProjectContext, SyncedRepository, TaskMessage (+4 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.13
Nodes (13): DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow, flutter_controller_ (+5 more)

### Community 2 - "NotFoundError"
Cohesion: 0.12
Nodes (12): NotFoundError, async_sessionmaker, AsyncSession, ProjectContext, SyncedRepository, UUID, RepoSyncService, ApprovalRequest (+4 more)

### Community 3 - "main.py"
Cohesion: 0.12
Nodes (14): configure_logging(), metrics_response(), ApprovalRequest, ApprovalStatus, TaskEvent, Task, LimitStatus, UsageSummary (+6 more)

### Community 4 - "task_models.dart"
Cohesion: 0.05
Nodes (39): approvals, cancelledAt, code, content, copyWith, createdAt, currentPhase, data (+31 more)

### Community 5 - "task_dto.dart"
Cohesion: 0.05
Nodes (40): approvals, cancelledAt, code, content, createdAt, currentPhase, data, errorMessage (+32 more)

### Community 6 - "mock_backend_store.dart"
Cohesion: 0.04
Nodes (51): _addIssue, _aiSettings, _approvalsById, approve, cancelTask, confirmCommit, createTask, discardCommit (+43 more)

### Community 7 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (29): Any, Cocoa, Flutter, flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS (+21 more)

### Community 8 - "account_dto.dart"
Cohesion: 0.07
Nodes (28): activeSessions, cancelledTasks, completedTasks, createdAt, currentConcurrentTasks, expiresAt, failedTasks, fromJson (+20 more)

### Community 9 - "List"
Cohesion: 0.09
Nodes (31): AsyncNotifier, List, AiSettingsStatus, aiSettingsRepositoryProvider, approvalRepositoryProvider, repoRepositoryProvider, taskRepositoryProvider, SessionsController (+23 more)

### Community 10 - "session_controller.dart"
Cohesion: 0.06
Nodes (32): AsyncValue, _applyIncomingEvent, approve, cancelTask, continueWithNewTask, disposeController, _init, _ref (+24 more)

### Community 11 - "git_service.py"
Cohesion: 0.20
Nodes (11): GitOperationStatus, GitCommandError, GitService, Exception, GitOperation, GitOperationStatus, UUID, Runs real git commands directly on this machine's working tree. Phodex is… (+3 more)

### Community 12 - "login"
Cohesion: 0.07
Nodes (49): client(), login(), AsyncClient, fixture, AsyncClient, test_account_me_reports_device_online_status(), test_account_usage_limits_and_task_issues(), _wait_for_status() (+41 more)

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
Cohesion: 0.07
Nodes (32): getAccountSummary, getLimitStatus, getUsageSummary, listSessions, revokeOtherSessions, revokeSession, _store, getStatus (+24 more)

### Community 17 - "api_client.dart"
Cohesion: 0.06
Nodes (33): Dio, Dio get, FlutterSecureStorage?, Future, _accessToken, _authOptions, baseUrl, clearSession (+25 more)

### Community 18 - "home_screen.dart"
Cohesion: 0.10
Nodes (20): children, _composer, createState, _CurrentTask, dispose, _FadingRow, HomeScreen, _HomeScreenState (+12 more)

### Community 19 - "sessions_screen.dart"
Cohesion: 0.13
Nodes (17): ConsumerWidget, SessionInfo, sessionsProvider, build, createState, onRevoke, _revoke, _revokeOthers (+9 more)

### Community 20 - "EmailVerifier"
Cohesion: 0.11
Nodes (18): Colors, EmailVerifier, export_do_not_send_csv(), export_sendable_csv(), main(), parse_csv_data(), print_header(), print_summary() (+10 more)

### Community 21 - "Phodex Android UI Design Spec"
Cohesion: 0.07
Nodes (26): 10. Empty / Loading / Error States, 11. Motion and polish, 12. Accessibility, 13. V1 Scope Boundaries, 14. Compose Implementation Notes (Next), 15. Design Review Checklist, 16. Changelog, 1. Purpose (+18 more)

### Community 22 - "repos_screen.dart"
Cohesion: 0.10
Nodes (22): Color, repositoriesProvider, build, color, createState, _DetailRow, dispose, icon (+14 more)

### Community 23 - "package:mobile/core/domain/models/models.dart"
Cohesion: 0.06
Nodes (34): dart:io, toDomainWithIssues, PhodexApiClient, _apiClient, getStatus, update, _apiClient, approve (+26 more)

### Community 24 - "account_models.dart"
Cohesion: 0.05
Nodes (41): account_models.dart, approval_models.dart, auth_models.dart, git_models.dart, int?, activeSessions, cancelledTasks, completedTasks (+33 more)

### Community 25 - "mock_task_repository.dart"
Cohesion: 0.09
Nodes (20): cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks, replyToTask (+12 more)

### Community 26 - "session_screen.dart"
Cohesion: 0.06
Nodes (34): approval, busy, _capitalize, _confirm, createState, _discard, dispose, events (+26 more)

### Community 27 - "ApprovalService"
Cohesion: 0.28
Nodes (6): ApprovalService, ApprovalRequest, ApprovalStatus, async_sessionmaker, AsyncSession, UUID

### Community 28 - "package:mobile/shared/theme/theme.dart"
Cohesion: 0.18
Nodes (11): build, PhodexApp, appRouterProvider, TaskIssue, _showAppearancePicker, themeModeProvider, build, issue (+3 more)

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
Cohesion: 0.07
Nodes (25): 1. Check local Codex CLI, 2. Create local env, 3. Start local infrastructure, 4. Install deps and migrate, 5. Start backend, 6. Run backend smoke test, 7. Connect Android to laptop backend, Local Laptop Backend Testing (+17 more)

### Community 35 - "TaskEventEnvelope"
Cohesion: 0.31
Nodes (3): TaskEventEnvelope, UUID, Queue

### Community 36 - "network_session_stream_repository.dart"
Cohesion: 0.13
Nodes (14): dart:async, dart:convert, SessionStreamRepository, subscribe, MockSessionStreamRepository, _apiClient, NetworkSessionStreamRepository, _parser (+6 more)

### Community 37 - "approval_models.dart"
Cohesion: 0.11
Nodes (17): Map, ApprovalRequest, ApprovalStatus, ApprovalStatusX, copyWith, createdAt, description, fromValue (+9 more)

### Community 38 - "_build_service_registry"
Cohesion: 0.16
Nodes (8): ABC, _build_service_registry(), async_sessionmaker, AsyncSession, UUID, WorkerDispatcher, UUID, WorkerEngine

### Community 39 - "auth_dto.dart"
Cohesion: 0.12
Nodes (16): AccountSummaryResponseDto, activeSessions, avatarUrl, createdAt, deviceLastSeenAt, deviceOnline, email, fromJson (+8 more)

### Community 40 - "approval_dto.dart"
Cohesion: 0.12
Nodes (15): ApprovalRequestOutDto, createdAt, description, fromJson, id, items, kind, payloadJson (+7 more)

### Community 41 - "network_task_repository.dart"
Cohesion: 0.12
Nodes (14): _apiClient, cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks (+6 more)

### Community 42 - "app_colors.dart"
Cohesion: 0.06
Nodes (33): @immutable, AppColors get, BuildContext, Color get, accentError, accentPrimary, accentPrimaryDeep, accentPrimarySoft (+25 more)

### Community 43 - "stagger_in.dart"
Cohesion: 0.22
Nodes (9): build, child, createState, index, initState, StaggerIn, _StaggerInState, _visible (+1 more)

### Community 44 - "auth_service.py"
Cohesion: 0.17
Nodes (16): FastAPI, Centralizes translation of ServiceError subclasses into HTTP responses. Routes…, register_exception_handlers(), hash_password(), verify_password(), AuthService, datetime, ConflictError (+8 more)

### Community 45 - "test_codex_worker_integration.py"
Cohesion: 0.35
Nodes (10): is_blocked_outcome(), codex_app(), codex_client(), codex_login(), AsyncClient, fixture, test_codex_worker_executes_runtime_after_approval(), test_codex_worker_recognizes_explicit_blocked_outcomes() (+2 more)

### Community 46 - "Phodex Backend Deployment Checklist"
Cohesion: 0.20
Nodes (9): 1. Prepare server and runtime, 2. Configure environment, 3. Run migrations, 4. Start backend, 5. Verify health, 6. Run end-to-end smoke test, 7. Post-deploy checks, 8. Rollback basics (+1 more)

### Community 47 - "repo_repository.dart"
Cohesion: 0.25
Nodes (7): getRepository, getSelectedProjectContext, listRepositories, RepoRepository, selectRepository, MockRepoRepository, NetworkRepoRepository

### Community 48 - "repository_providers.dart"
Cohesion: 0.10
Nodes (18): ApiConfig, authRepositoryProvider, gitOpsRepositoryProvider, mockBackendStoreProvider, persisted, persistedServerUrlOverrideProvider, sessionEventParserProvider, sessionStreamRepositoryProvider (+10 more)

### Community 49 - "State"
Cohesion: 0.24
Nodes (11): _CommitPushSheet, _CommitPushSheetState, _ExecutionView, _ExecutionViewState, _FollowUpTaskSheet, _FollowUpTaskSheetState, PhodexMascot, _PhodexMascotState (+3 more)

### Community 50 - "claude/process_runner.py"
Cohesion: 0.29
Nodes (14): extract_assistant_text(), extract_result_subtype(), extract_result_summary(), extract_tool_use_summaries(), is_error_result(), is_result_event(), is_system_init(), Pure functions for parsing `claude -p ... --output-format stream-json` events.… (+6 more)

### Community 51 - "account_screen.dart"
Cohesion: 0.07
Nodes (33): IconData?, fadeThroughPage, slideUpPage, accountDashboardProvider, AccountScreen, _AppearanceOption, build, icon (+25 more)

### Community 52 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16() (+1 more)

### Community 53 - "api/repos.py"
Cohesion: 0.28
Nodes (20): get_current_context(), get_repository(), list_repositories(), Depends, get, post, UUID, select_repository() (+12 more)

### Community 54 - "Phodex mobile"
Cohesion: 0.29
Nodes (6): Connecting to a real desktop (no rebuild needed), Local demo: Android emulator, Phodex mobile, Real Google sign-in, UI-only mode, Verification

### Community 55 - "auth_controller.dart"
Cohesion: 0.10
Nodes (24): bool get, Completer, GoogleSignIn, build, forget, isConfigured, _restore, ServerUrlController (+16 more)

### Community 56 - "ProcessRunner"
Cohesion: 0.23
Nodes (7): ProcessRunner, Process, UUID, Looks up this task's owner's optional API-key/model override. Returns (env,…, compose_prompt(), TaskMessage, RuntimeError

### Community 57 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 58 - "TaskService"
Cohesion: 0.11
Nodes (12): EventService, async_sessionmaker, AsyncSession, async_sessionmaker, AsyncSession, async_sessionmaker, AsyncSession, TaskService (+4 more)

### Community 59 - "Settings"
Cohesion: 0.20
Nodes (12): get_settings(), field_validator, Settings, configure_runtime_telemetry(), instrument_fastapi(), FastAPI, Register FastAPI middleware before the application lifespan begins., Configure optional exporters and runtime integrations during startup. (+4 more)

### Community 60 - "db/session.py"
Cohesion: 0.39
Nodes (7): AsyncEngine, create_engine_and_sessionmaker(), create_schema(), drop_schema(), get_db_from_sessionmaker(), async_sessionmaker, AsyncSession

### Community 61 - "api/health.py"
Cohesion: 0.39
Nodes (7): health(), live(), get, Request, ready(), HealthResponse, BaseModel

### Community 62 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.11
Nodes (17): main, pairedServerUrl, prefs, build, _prefsKey, _restore, setThemeMode, buildTestApp (+9 more)

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

### Community 67 - "network_account_repository.dart"
Cohesion: 0.11
Nodes (16): AccountRepository, getAccountSummary, getLimitStatus, getUsageSummary, listSessions, revokeOtherSessions, revokeSession, MockAccountRepository (+8 more)

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
Cohesion: 0.12
Nodes (19): homeTasksProvider, build, initState, _ActivityCard, build, createState, dispose, _filter (+11 more)

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

### Community 87 - "orchestrator.py"
Cohesion: 0.17
Nodes (13): ExecutionContextBuilder, async_sessionmaker, AsyncSession, ProcessRunnerProtocol, Lock, Process, UUID, Generic dispatch/approval/cancel orchestration shared by subprocess-backed… (+5 more)

### Community 88 - "api/auth.py"
Cohesion: 0.26
Nodes (14): google_auth(), login(), me(), Depends, get, post, Request, register() (+6 more)

### Community 90 - "account_controller.dart"
Cohesion: 0.16
Nodes (14): LimitStatus, AccountSummary, accountRepositoryProvider, AccountDashboard, AccountDashboardController, build, limits, refresh (+6 more)

### Community 91 - "ORMModel"
Cohesion: 0.18
Nodes (38): cancel_task(), create_task(), get_task(), list_events(), list_messages(), list_task_issues(), list_tasks(), Depends (+30 more)

### Community 94 - "git_ops_repository.dart"
Cohesion: 0.29
Nodes (6): confirmCommit, discardCommit, GitOpsRepository, prepareCommit, MockGitOpsRepository, NetworkGitOpsRepository

### Community 95 - "Win32Window"
Cohesion: 0.20
Nodes (14): OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate, OnDestroy (+6 more)

### Community 97 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 99 - "UserAiSettingsService"
Cohesion: 0.17
Nodes (12): UUID, Per-user AI provider overrides. Optional by design: if a user never sets…, Internal use only (subprocess env building) — never expose decrypted keys over…, UserAiSettingsService, CodexWorkerEngine, Codex-specific wiring on top of the shared subprocess worker orchestrator., Production-oriented worker adapter for running a real Codex runtime command.…, extract_assistant_message() (+4 more)

### Community 100 - "stream_task_events_alias"
Cohesion: 0.22
Nodes (9): Depends, description, ge, get, Query, Request, StreamingResponse, UUID (+1 more)

### Community 106 - "ProcessRunner"
Cohesion: 0.18
Nodes (9): ClaudeWorkerEngine, async_sessionmaker, AsyncSession, Claude-specific wiring on top of the shared subprocess worker orchestrator., Worker adapter that runs tasks through the Claude Code CLI in headless mode…, ProcessRunner, Process, UUID (+1 more)

### Community 114 - "connect_desktop_screen.dart"
Cohesion: 0.14
Nodes (16): ConsumerState, ConsumerStatefulWidget, _SessionsList, _SessionsListState, connectDesktopControllerProvider, build, ConnectDesktopScreen, _ConnectDesktopScreenState (+8 more)

### Community 116 - "ManagedSubprocess"
Cohesion: 0.14
Nodes (7): ManagedSubprocess, Process, Generic async subprocess runner shared by worker engines. Handles spawning,…, Writes a follow-up line to stdin. Returns False if stdin is unavailable or…, Waits for exit with a timeout, killing the process if it fires. Always drains…, OnLine, StreamReader

### Community 117 - "User"
Cohesion: 0.16
Nodes (22): get_ai_settings(), Depends, get, update_ai_settings(), get_services(), Request, confirm_git_commit(), discard_git_commit() (+14 more)

### Community 118 - "get_current_user"
Cohesion: 0.25
Nodes (14): approve(), pending_approvals(), Depends, get, post, UUID, reject(), get_current_user() (+6 more)

### Community 120 - "ServiceRegistry"
Cohesion: 0.28
Nodes (21): account_limits(), account_me(), account_usage(), list_sessions(), Depends, get, post, UUID (+13 more)

### Community 122 - "approvals_screen.dart"
Cohesion: 0.11
Nodes (18): approvalsProvider, approval, _ApprovalReview, ApprovalsScreen, build, _NoApprovals, onApprove, onReject (+10 more)

### Community 123 - "utcnow"
Cohesion: 0.24
Nodes (7): AccountService, async_sessionmaker, AsyncSession, TaskStatus, UUID, datetime, utcnow()

### Community 126 - "api/devices.py"
Cohesion: 0.31
Nodes (13): get_device(), heartbeat(), list_devices(), Depends, get, post, UUID, register_device() (+5 more)

### Community 128 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (37): GoRouter, main, state, drag, main, pump, scrollDown, settle (+29 more)

### Community 129 - "security.py"
Cohesion: 0.19
Nodes (8): JWTManager, datetime, Exception, UUID, TokenError, async_sessionmaker, AsyncSession, timedelta

### Community 130 - "session_state.dart"
Cohesion: 0.15
Nodes (12): int get, TaskSummary, approvals, copyWith, events, isResolvingApproval, isSendingReply, issues (+4 more)

### Community 131 - "connect_desktop_controller.dart"
Cohesion: 0.18
Nodes (12): serverUrlProvider, build, ConnectDesktopController, ConnectDesktopState, ConnectionTestStatus, copyWith, errorMessage, _normalize (+4 more)

### Community 132 - "DeviceService"
Cohesion: 0.33
Nodes (5): Device, DeviceService, async_sessionmaker, AsyncSession, UUID

### Community 134 - "crypto.py"
Cohesion: 0.27
Nodes (6): decrypt_secret(), encrypt_secret(), EncryptionKeyNotConfiguredError, _fernet(), _get_fernet(), Encryption for secrets stored at rest (per-user AI provider API keys). Uses…

### Community 135 - "qr_scan_screen.dart"
Cohesion: 0.22
Nodes (9): build, _controller, createState, dispose, _handled, _onDetect, QrScanScreen, _QrScanScreenState (+1 more)

### Community 136 - "pairing.py"
Cohesion: 0.36
Nodes (7): pairing_page(), Depends, get, generate_qr_data_uri(), _guess_local_ip(), Returns (base_url, is_guessed). is_guessed is True when no PUBLIC_BASE_URL was…, resolve_public_base_url()

### Community 137 - "FakeWorkerEngine"
Cohesion: 0.42
Nodes (3): FakeWorkerEngine, UUID, Fake worker for V1. TODO: Replace this with real Codex runtime integration…

### Community 138 - "env.py"
Cohesion: 0.83
Nodes (3): _resolve_database_url(), run_migrations_offline(), run_migrations_online()

### Community 139 - "test_pairing.py"
Cohesion: 0.67
Nodes (3): AsyncClient, test_pairing_page_serves_a_qr_code_with_no_auth(), test_pairing_page_warns_when_address_is_guessed()

### Community 140 - "sessionProvider"
Cohesion: 0.50
Nodes (4): sessionProvider, build, SessionScreen, Route /activity

### Community 142 - "CustomPainter"
Cohesion: 0.67
Nodes (3): CustomPainter, _RobinGlyphPainter, _RobinPainter

## Knowledge Gaps
- **876 isolated node(s):** `$schema`, `.opencode/plugins/graphify.js`, `smoke_test_backend_platform.sh script`, `Colors`, `main` (+871 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Settings` connect `Settings` to `security.py`, `main.py`, `UserAiSettingsService`, `ProcessRunner`, `_build_service_registry`, `crypto.py`, `pairing.py`, `FakeWorkerEngine`, `env.py`, `ProcessRunner`, `auth_service.py`, `.__init__`, `test_claude_worker_integration.py`, `test_codex_worker_integration.py`, `claude/process_runner.py`, `ServiceRegistry`, `TaskService`, `utcnow`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **Why does `login()` connect `login` to `main.py`, `Settings`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/material.dart`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **Are the 13 inferred relationships involving `ServiceRegistry` (e.g. with `Settings` and `AccountService`) actually correct?**
  _`ServiceRegistry` has 13 INFERRED edges - model-reasoned connections that need verification._
- **Are the 17 inferred relationships involving `Settings` (e.g. with `EncryptionKeyNotConfiguredError` and `JWTManager`) actually correct?**
  _`Settings` has 17 INFERRED edges - model-reasoned connections that need verification._
- **Are the 23 inferred relationships involving `TaskService` (e.g. with `ServiceRegistry` and `Settings`) actually correct?**
  _`TaskService` has 23 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `User` (e.g. with `Base` and `TimestampMixin`) actually correct?**
  _`User` has 4 INFERRED edges - model-reasoned connections that need verification._