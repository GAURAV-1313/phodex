# Graph Report - phodex  (2026-08-22)

## Corpus Check
- 275 files · ~80,521 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2369 nodes · 4724 edges · 161 communities (142 shown, 19 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 355 edges (avg confidence: 0.54)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0b295866`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- EventBus
- datetime.py
- mock_backend_store.dart
- GitService
- GeneratedPluginRegistrant.swift
- _
- task_dto.dart
- task_models.dart
- EventService
- PushService
- login
- session_screen.dart
- app_colors.dart
- session_controller.dart
- stitch_ui.dart
- api_client.dart
- package:mobile/core/network/api_client.dart
- package:mobile/core/repositories/interfaces/interfaces.dart
- api/tasks.py
- phodex_mascot.dart
- network_session_stream_repository.dart
- EmailVerifier
- account_dto.dart
- task_service.py
- Phodex Android UI Design Spec
- account_models.dart
- get_services
- Phodex Backend (FastAPI)
- repo_models.dart
- auth_service.py
- my_application.cc
- notifications_screen.dart
- repo_dto.dart
- ai_engine_screen.dart
- codex/process_runner.py
- account_screen.dart
- List
- git_models.dart
- repos_screen.dart
- ApprovalService
- package:flutter/material.dart
- mock_task_repository.dart
- repository_providers.dart
- TaskService
- sessions_screen.dart
- recents_screen.dart
- home_screen.dart
- test_claude_worker_integration.py
- claude/process_runner.py
- orchestrator.py
- server_connection_controller.dart
- package:flutter_riverpod/flutter_riverpod.dart
- RedisService
- device_agent.py
- git_dto.dart
- network_account_repository.dart
- ServiceRegistry
- auth_controller.dart
- account_controller.dart
- approval_models.dart
- auth_dto.dart
- WorkerDispatcher
- api/auth.py
- User
- approval_dto.dart
- network_repo_repository.dart
- FlutterWindow
- MessageHandler
- session_event_reducer.dart
- firebase_options.dart
- utcnow
- win32_window.cpp
- approvals_screen.dart
- DeviceService
- git_service.py
- push_notification_controller.dart
- RepoSyncService
- session_state.dart
- connect_desktop_controller.dart
- connect_desktop_screen.dart
- get_current_user
- ORMModel
- wWinMain
- mock.dart
- State
- manifest.json
- interfaces.dart
- api/ai_settings.py
- FakeWorkerEngine
- Phodex Backend Deployment Checklist
- network.dart
- network_task_repository.dart
- qr_scan_screen.dart
- stagger_in.dart
- api/health.py
- test_codex_worker_integration.py
- stream_task_events_alias
- auth_models.dart
- Win32Window
- db/session.py
- dto.dart
- SessionStreamRepository
- app_router.dart
- mock_approval_repository.dart
- AiSettingsStatus
- Phodex mobile
- account_screen_test.dart
- Settings
- package:mobile/core/domain/models/models.dart
- PushRepository
- approvals_screen_test.dart
- widget_test.dart
- smoke_test_codex_worker.sh
- package:flutter_test/flutter_test.dart
- AppColors
- CustomPainter
- connect_desktop_screen_test.dart
- home_screen_test.dart
- notifications_screen_test.dart
- sessions_screen_test.dart
- RegisterPlugins
- test_pairing.py
- common_dto.dart
- sessionProvider
- test_helpers.dart
- opencode.json
- check_laptop_runtime.sh
- MainActivity
- graphify.js
- _PhodexMascotState
- smoke_test_backend_platform.sh
- CLAUDE.md
- LaunchImage.imageset/README.md
- mappers.dart
- AppColorsContext
- ApprovalRequest
- ApprovalStatus
- DateTime
- GitOperation
- GitOperationStatus
- ProjectContext?
- String?
- SyncedRepository
- TaskStatus

## God Nodes (most connected - your core abstractions)
1. `ServiceRegistry` - 71 edges
2. `Settings` - 67 edges
3. `User` - 57 edges
4. `TaskService` - 56 edges
5. `get_services()` - 55 edges
6. `get_current_user()` - 50 edges
7. `EventService` - 46 edges
8. `ORMModel` - 42 edges
9. `ApprovalService` - 37 edges
10. `NotFoundError` - 36 edges

## Surprising Connections (you probably didn't know these)
- `AccountService` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `LimitStatus` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `UsageSummary` --uses--> `Settings`  [INFERRED]
  backend/app/services/account_service.py → backend/app/core/config.py
- `AuthService` --uses--> `Settings`  [INFERRED]
  backend/app/services/auth_service.py → backend/app/core/config.py
- `GoogleAuthService` --uses--> `Settings`  [INFERRED]
  backend/app/services/google_auth_service.py → backend/app/core/config.py

## Import Cycles
- None detected.

## Communities (161 total, 19 thin omitted)

### Community 0 - "EventBus"
Cohesion: 0.18
Nodes (6): EventBus, async_sessionmaker, AsyncSession, TaskEventEnvelope, UUID, Queue

### Community 1 - "datetime.py"
Cohesion: 0.25
Nodes (13): _resolve_database_url(), run_migrations_offline(), Base, Artifact, TimestampMixin, UUIDPrimaryKeyMixin, ProjectContext, PushSubscription (+5 more)

### Community 2 - "mock_backend_store.dart"
Cohesion: 0.04
Nodes (51): _addIssue, _aiSettings, _approvalsById, approve, cancelTask, confirmCommit, createTask, discardCommit (+43 more)

### Community 3 - "GitService"
Cohesion: 0.12
Nodes (12): GitService, async_sessionmaker, AsyncSession, GitOperation, GitOperationStatus, UUID, ManagedSubprocess, Process (+4 more)

### Community 4 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (31): Any, Cocoa, firebase_core, firebase_messaging, Flutter, flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge (+23 more)

### Community 5 - "_"
Cohesion: 0.05
Nodes (43): app_colors.dart, app_radii.dart, app_spacing.dart, app_theme.dart, app_typography.dart, _, AppRadii, card (+35 more)

### Community 6 - "task_dto.dart"
Cohesion: 0.05
Nodes (42): approvals, cancelledAt, code, content, createdAt, currentPhase, data, errorMessage (+34 more)

### Community 7 - "task_models.dart"
Cohesion: 0.04
Nodes (47): account_models.dart, approval_models.dart, auth_models.dart, git_models.dart, approvals, cancelledAt, code, content (+39 more)

### Community 8 - "EventService"
Cohesion: 0.08
Nodes (22): _build_service_registry(), async_sessionmaker, AsyncSession, EventService, async_sessionmaker, AsyncSession, UUID, Per-user AI provider overrides. Optional by design: if a user never sets… (+14 more)

### Community 9 - "PushService"
Cohesion: 0.13
Nodes (14): PushService, async_sessionmaker, AsyncSession, UUID, Sends real push notifications via the FCM HTTP v1 API directly (service-account…, push_service(), AsyncClient, fixture (+6 more)

### Community 10 - "login"
Cohesion: 0.07
Nodes (49): client(), login(), AsyncClient, fixture, AsyncClient, test_account_me_reports_device_online_status(), test_account_usage_limits_and_task_issues(), _wait_for_status() (+41 more)

### Community 11 - "session_screen.dart"
Cohesion: 0.06
Nodes (34): approval, busy, _capitalize, _confirm, createState, _discard, dispose, events (+26 more)

### Community 12 - "app_colors.dart"
Cohesion: 0.07
Nodes (28): AppColors get, Color get, accentError, accentPrimary, accentPrimaryDeep, accentPrimarySoft, accentSuccess, accentWarning (+20 more)

### Community 13 - "session_controller.dart"
Cohesion: 0.11
Nodes (17): AsyncValue, _applyIncomingEvent, approve, cancelTask, continueWithNewTask, disposeController, _init, _ref (+9 more)

### Community 14 - "stitch_ui.dart"
Cohesion: 0.07
Nodes (34): dart:ui, EdgeInsets, _FadingRow, _ApprovalBlock, _CompletionCard, _LogsSheet, _Timeline, PhodexMascotGlyph (+26 more)

### Community 15 - "api_client.dart"
Cohesion: 0.06
Nodes (33): Dio, Dio get, FlutterSecureStorage?, Future, _accessToken, _authOptions, baseUrl, clearSession (+25 more)

### Community 16 - "package:mobile/core/network/api_client.dart"
Cohesion: 0.10
Nodes (20): toDomainWithIssues, PhodexApiClient, _apiClient, getStatus, update, _apiClient, approve, listPending (+12 more)

### Community 17 - "package:mobile/core/repositories/interfaces/interfaces.dart"
Cohesion: 0.07
Nodes (28): getAccountSummary, getLimitStatus, getUsageSummary, listSessions, revokeOtherSessions, revokeSession, _store, getStatus (+20 more)

### Community 18 - "api/tasks.py"
Cohesion: 0.19
Nodes (34): cancel_task(), create_task(), get_task(), list_events(), list_messages(), list_task_issues(), list_tasks(), Depends (+26 more)

### Community 19 - "phodex_mascot.dart"
Cohesion: 0.07
Nodes (26): AnimationController, dart:math, double get, build, color, colors, _controller, createState (+18 more)

### Community 20 - "network_session_stream_repository.dart"
Cohesion: 0.10
Nodes (18): dart:async, dart:convert, dart:io, _apiClient, _parser, subscribe, JsonSessionEventParser, parse (+10 more)

### Community 21 - "EmailVerifier"
Cohesion: 0.11
Nodes (18): Colors, EmailVerifier, export_do_not_send_csv(), export_sendable_csv(), main(), parse_csv_data(), print_header(), print_summary() (+10 more)

### Community 22 - "account_dto.dart"
Cohesion: 0.07
Nodes (28): activeSessions, cancelledTasks, completedTasks, createdAt, currentConcurrentTasks, expiresAt, failedTasks, fromJson (+20 more)

### Community 23 - "task_service.py"
Cohesion: 0.47
Nodes (6): ApprovalRequest, ApprovalStatus, TaskStatus, TaskEvent, LimitStatus, UsageSummary

### Community 24 - "Phodex Android UI Design Spec"
Cohesion: 0.07
Nodes (26): 10. Empty / Loading / Error States, 11. Motion and polish, 12. Accessibility, 13. V1 Scope Boundaries, 14. Compose Implementation Notes (Next), 15. Design Review Checklist, 16. Changelog, 1. Purpose (+18 more)

### Community 25 - "account_models.dart"
Cohesion: 0.07
Nodes (27): int?, activeSessions, cancelledTasks, completedTasks, createdAt, currentConcurrentTasks, deviceLastSeenAt, deviceOnline (+19 more)

### Community 26 - "get_services"
Cohesion: 0.26
Nodes (22): account_limits(), account_me(), account_usage(), list_sessions(), Depends, get, post, UUID (+14 more)

### Community 27 - "Phodex Backend (FastAPI)"
Cohesion: 0.07
Nodes (27): 1. Check local Codex CLI, 2. Create local env, 3. Start local infrastructure, 4. Install deps and migrate, 5. Start backend, 6. Run backend smoke test, 7. Connect Android to laptop backend, Local Laptop Backend Testing (+19 more)

### Community 28 - "repo_models.dart"
Cohesion: 0.08
Nodes (26): branch, createdAt, currentBranch, defaultBranch, deviceId, deviceName, fromValue, gitRoot (+18 more)

### Community 29 - "auth_service.py"
Cohesion: 0.15
Nodes (18): FastAPI, Centralizes translation of ServiceError subclasses into HTTP responses. Routes…, register_exception_handlers(), hash_password(), verify_password(), AuthService, async_sessionmaker, AsyncSession (+10 more)

### Community 30 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 31 - "notifications_screen.dart"
Cohesion: 0.14
Nodes (13): pushNotificationControllerProvider, _bodyFor, build, _colorFor, _iconFor, NotificationsScreen, _titleFor, main (+5 more)

### Community 32 - "repo_dto.dart"
Cohesion: 0.08
Nodes (25): branch, createdAt, currentBranch, defaultBranch, deviceId, deviceName, fromJson, gitRoot (+17 more)

### Community 33 - "ai_engine_screen.dart"
Cohesion: 0.09
Nodes (25): aiSettingsStatusProvider, _AiEngineForm, _AiEngineFormState, AiEngineScreen, _anthropicKey, build, _claudeModel, _clearKey (+17 more)

### Community 34 - "codex/process_runner.py"
Cohesion: 0.15
Nodes (14): run_migrations_online(), extract_assistant_message(), extract_content_text(), extract_final_summary(), is_blocked_outcome(), Pure functions for parsing structured JSON lines emitted by the Codex runtime., ProcessRunner, Process (+6 more)

### Community 35 - "account_screen.dart"
Cohesion: 0.08
Nodes (28): IconData?, accountDashboardProvider, AccountScreen, _AppearanceOption, build, icon, label, mode (+20 more)

### Community 36 - "List"
Cohesion: 0.16
Nodes (19): AsyncNotifier, List, repoRepositoryProvider, taskRepositoryProvider, SessionsController, build, createTask, HomeTasksController (+11 more)

### Community 37 - "git_models.dart"
Cohesion: 0.10
Nodes (19): commitMessage, copyWith, diffStatOutput, errorMessage, fromValue, GitOperation, GitOperationStatus, GitOperationStatusX (+11 more)

### Community 38 - "repos_screen.dart"
Cohesion: 0.09
Nodes (24): Color, ConsumerWidget, SessionsScreen, repositoriesProvider, build, color, createState, _DetailRow (+16 more)

### Community 39 - "ApprovalService"
Cohesion: 0.28
Nodes (6): ApprovalService, ApprovalRequest, ApprovalStatus, async_sessionmaker, AsyncSession, UUID

### Community 40 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (20): build, PhodexApp, appRouterProvider, TaskIssue, _showAppearancePicker, _handleMessageTap, build, _prefsKey (+12 more)

### Community 41 - "mock_task_repository.dart"
Cohesion: 0.09
Nodes (20): cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks, replyToTask (+12 more)

### Community 42 - "repository_providers.dart"
Cohesion: 0.09
Nodes (21): ApiConfig, authRepositoryProvider, _baseUrlFromEnv, gitOpsRepositoryProvider, _googleIdTokenFromEnv, _googleIosClientIdFromEnv, _googleServerClientIdFromEnv, mockBackendStoreProvider (+13 more)

### Community 43 - "TaskService"
Cohesion: 0.21
Nodes (10): Task, NotFoundError, ApprovalRequest, TaskEventEnvelope, TaskMessage, TaskStatus, UUID, TaskService (+2 more)

### Community 44 - "sessions_screen.dart"
Cohesion: 0.14
Nodes (17): SessionInfo, sessionsProvider, build, createState, onRevoke, _revoke, _revokeOthers, revoking (+9 more)

### Community 45 - "recents_screen.dart"
Cohesion: 0.11
Nodes (21): ConsumerState, ConsumerStatefulWidget, homeTasksProvider, build, initState, _ActivityCard, build, createState (+13 more)

### Community 46 - "home_screen.dart"
Cohesion: 0.11
Nodes (19): children, _composer, createState, _CurrentTask, dispose, HomeScreen, _HomeScreenState, icon (+11 more)

### Community 47 - "test_claude_worker_integration.py"
Cohesion: 0.44
Nodes (8): claude_app(), claude_client(), claude_login(), AsyncClient, fixture, test_claude_worker_executes_runtime_after_approval(), _wait_for_status(), _write_stub_runtime()

### Community 48 - "claude/process_runner.py"
Cohesion: 0.18
Nodes (18): extract_assistant_text(), extract_result_subtype(), extract_result_summary(), extract_tool_use_summaries(), is_error_result(), is_result_event(), is_system_init(), Pure functions for parsing `claude -p ... --output-format stream-json` events.… (+10 more)

### Community 49 - "orchestrator.py"
Cohesion: 0.18
Nodes (12): ExecutionContextBuilder, UUID, ProcessRunnerProtocol, Lock, Process, UUID, Generic dispatch/approval/cancel orchestration shared by subprocess-backed…, Shared dispatch/approval/cancel state machine for subprocess-backed worker… (+4 more)

### Community 50 - "server_connection_controller.dart"
Cohesion: 0.20
Nodes (9): bool get, build, forget, isConfigured, _restore, ServerUrlController, serverUrlPrefsKey, setServerUrl (+1 more)

### Community 51 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.10
Nodes (22): approvalRepositoryProvider, saveSettings, ApprovalsController, approve, build, refresh, reject, firebaseAvailable (+14 more)

### Community 52 - "RedisService"
Cohesion: 0.12
Nodes (7): Optional Redis adapter for ephemeral coordination; durable data stays in…, RedisService, async_sessionmaker, AsyncSession, AsyncClient, test_rate_limit_cache_invalidation_health_and_metrics(), test_redis_cache_rate_limit_and_pubsub()

### Community 53 - "device_agent.py"
Cohesion: 0.22
Nodes (12): ApiClient, Config, _default_device_name(), discover_repos(), exchange_google_id_token(), _git(), load_config(), load_device_id() (+4 more)

### Community 54 - "git_dto.dart"
Cohesion: 0.11
Nodes (17): AiSettingsStatusResponseDto, commitMessage, diffStatOutput, errorMessage, fromJson, GitOperationOutDto, hasAnthropicKey, hasOpenaiKey (+9 more)

### Community 55 - "network_account_repository.dart"
Cohesion: 0.11
Nodes (16): AccountRepository, getAccountSummary, getLimitStatus, getUsageSummary, listSessions, revokeOtherSessions, revokeSession, MockAccountRepository (+8 more)

### Community 56 - "ServiceRegistry"
Cohesion: 0.12
Nodes (24): approve(), pending_approvals(), Depends, get, post, UUID, reject(), pairing_page() (+16 more)

### Community 57 - "auth_controller.dart"
Cohesion: 0.17
Nodes (15): Completer, GoogleSignIn, apiClientProvider, apiConfigProvider, AuthController, _authenticateNatively, build, _events (+7 more)

### Community 58 - "account_controller.dart"
Cohesion: 0.16
Nodes (14): LimitStatus, AccountSummary, accountRepositoryProvider, AccountDashboard, AccountDashboardController, build, limits, refresh (+6 more)

### Community 59 - "approval_models.dart"
Cohesion: 0.12
Nodes (15): ApprovalRequest, ApprovalStatus, ApprovalStatusX, copyWith, createdAt, description, fromValue, id (+7 more)

### Community 60 - "auth_dto.dart"
Cohesion: 0.11
Nodes (17): AccountSummaryResponseDto, activeSessions, avatarUrl, createdAt, deviceLastSeenAt, deviceOnline, email, fromJson (+9 more)

### Community 61 - "WorkerDispatcher"
Cohesion: 0.22
Nodes (5): ABC, UUID, WorkerDispatcher, UUID, WorkerEngine

### Community 62 - "api/auth.py"
Cohesion: 0.26
Nodes (14): google_auth(), login(), me(), Depends, get, post, Request, register() (+6 more)

### Community 63 - "User"
Cohesion: 0.32
Nodes (14): get_device(), heartbeat(), list_devices(), Depends, get, post, UUID, register_device() (+6 more)

### Community 64 - "approval_dto.dart"
Cohesion: 0.12
Nodes (15): Map, ApprovalRequestOutDto, createdAt, description, fromJson, id, items, kind (+7 more)

### Community 65 - "network_repo_repository.dart"
Cohesion: 0.13
Nodes (13): getRepository, getSelectedProjectContext, listRepositories, RepoRepository, selectRepository, MockRepoRepository, _apiClient, getRepository (+5 more)

### Community 66 - "FlutterWindow"
Cohesion: 0.13
Nodes (13): DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow, flutter_controller_ (+5 more)

### Community 67 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 68 - "session_event_reducer.dart"
Cohesion: 0.13
Nodes (14): approvalId, approvals, copyWith, errorCode, issues, mergedEvents, reduceSessionWithEvent, task (+6 more)

### Community 69 - "firebase_options.dart"
Cohesion: 0.14
Nodes (13): @pragma, firebaseMessagingBackgroundHandler, initializeFirebase, android, DefaultFirebaseOptions, ios, placeholderMarker, package:firebase_core/firebase_core.dart (+5 more)

### Community 70 - "utcnow"
Cohesion: 0.24
Nodes (7): AccountService, async_sessionmaker, AsyncSession, TaskStatus, UUID, datetime, utcnow()

### Community 71 - "win32_window.cpp"
Cohesion: 0.18
Nodes (14): wchar_t, Scale(), Create, Destroy, UpdateTheme, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_ (+6 more)

### Community 72 - "approvals_screen.dart"
Cohesion: 0.15
Nodes (13): approvalsProvider, approval, _ApprovalReview, ApprovalsScreen, build, _NoApprovals, onApprove, onReject (+5 more)

### Community 73 - "DeviceService"
Cohesion: 0.33
Nodes (5): Device, DeviceService, async_sessionmaker, AsyncSession, UUID

### Community 74 - "git_service.py"
Cohesion: 0.19
Nodes (11): GitOperationStatus, GitOperation, GitCommandError, Exception, Runs real git commands directly on this machine's working tree. Phodex is…, async_sessionmaker, AsyncSession, ProjectContext (+3 more)

### Community 75 - "push_notification_controller.dart"
Cohesion: 0.18
Nodes (13): firebaseAvailableProvider, build, _listenForTaps, _mapStatus, _openedAppSub, _platformName, PushNotificationController, PushPermissionStatus (+5 more)

### Community 76 - "RepoSyncService"
Cohesion: 0.27
Nodes (6): async_sessionmaker, AsyncSession, ProjectContext, SyncedRepository, UUID, RepoSyncService

### Community 77 - "session_state.dart"
Cohesion: 0.15
Nodes (12): int get, TaskSummary, approvals, copyWith, events, isResolvingApproval, isSendingReply, issues (+4 more)

### Community 78 - "connect_desktop_controller.dart"
Cohesion: 0.18
Nodes (12): serverUrlProvider, build, ConnectDesktopController, ConnectDesktopState, ConnectionTestStatus, copyWith, errorMessage, _normalize (+4 more)

### Community 79 - "connect_desktop_screen.dart"
Cohesion: 0.13
Nodes (15): fadeThroughPage, slideUpPage, connectDesktopControllerProvider, build, ConnectDesktopScreen, _ConnectDesktopScreenState, createState, dispose (+7 more)

### Community 80 - "get_current_user"
Cohesion: 0.29
Nodes (13): get_current_user(), Depends, confirm_git_commit(), discard_git_commit(), prepare_git_commit(), Depends, post, UUID (+5 more)

### Community 81 - "ORMModel"
Cohesion: 0.26
Nodes (22): get_current_context(), get_repository(), list_repositories(), Depends, get, post, UUID, select_repository() (+14 more)

### Community 82 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16() (+1 more)

### Community 83 - "mock.dart"
Cohesion: 0.18
Nodes (10): mock_account_repository.dart, mock_ai_settings_repository.dart, mock_approval_repository.dart, mock_auth_repository.dart, mock_backend_store.dart, mock_git_ops_repository.dart, mock_push_repository.dart, mock_repo_repository.dart (+2 more)

### Community 84 - "State"
Cohesion: 0.32
Nodes (8): _CommitPushSheet, _CommitPushSheetState, _ExecutionView, _ExecutionViewState, _FollowUpTaskSheet, _FollowUpTaskSheetState, State, StatefulWidget

### Community 85 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 86 - "interfaces.dart"
Cohesion: 0.20
Nodes (9): account_repository.dart, ai_settings_repository.dart, approval_repository.dart, auth_repository.dart, git_ops_repository.dart, push_repository.dart, repo_repository.dart, session_stream_repository.dart (+1 more)

### Community 87 - "api/ai_settings.py"
Cohesion: 0.36
Nodes (8): get_ai_settings(), Depends, get, update_ai_settings(), AiSettingsStatusResponse, AiSettingsUpdateRequest, BaseModel, put

### Community 88 - "FakeWorkerEngine"
Cohesion: 0.42
Nodes (3): FakeWorkerEngine, UUID, Fake worker for V1. TODO: Replace this with real Codex runtime integration…

### Community 89 - "Phodex Backend Deployment Checklist"
Cohesion: 0.20
Nodes (9): 1. Prepare server and runtime, 2. Configure environment, 3. Run migrations, 4. Start backend, 5. Verify health, 6. Run end-to-end smoke test, 7. Post-deploy checks, 8. Rollback basics (+1 more)

### Community 90 - "network.dart"
Cohesion: 0.20
Nodes (9): network_account_repository.dart, network_ai_settings_repository.dart, network_approval_repository.dart, network_auth_repository.dart, network_git_ops_repository.dart, network_push_repository.dart, network_repo_repository.dart, network_session_stream_repository.dart (+1 more)

### Community 91 - "network_task_repository.dart"
Cohesion: 0.20
Nodes (9): _apiClient, cancelTask, createTask, getTaskDetail, listEvents, listIssues, listMessages, listTasks (+1 more)

### Community 92 - "qr_scan_screen.dart"
Cohesion: 0.22
Nodes (9): build, _controller, createState, dispose, _handled, _onDetect, QrScanScreen, _QrScanScreenState (+1 more)

### Community 93 - "stagger_in.dart"
Cohesion: 0.22
Nodes (9): build, child, createState, index, initState, StaggerIn, _StaggerInState, _visible (+1 more)

### Community 94 - "api/health.py"
Cohesion: 0.39
Nodes (7): health(), live(), get, Request, ready(), HealthResponse, BaseModel

### Community 95 - "test_codex_worker_integration.py"
Cohesion: 0.44
Nodes (8): codex_app(), codex_client(), codex_login(), AsyncClient, fixture, test_codex_worker_executes_runtime_after_approval(), _wait_for_status(), _write_stub_runtime()

### Community 96 - "stream_task_events_alias"
Cohesion: 0.22
Nodes (9): Depends, description, ge, get, Query, Request, StreamingResponse, UUID (+1 more)

### Community 97 - "auth_models.dart"
Cohesion: 0.22
Nodes (8): avatarUrl, createdAt, email, googleSub, id, name, updatedAt, UserProfile

### Community 98 - "Win32Window"
Cohesion: 0.20
Nodes (14): OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate, OnDestroy (+6 more)

### Community 99 - "db/session.py"
Cohesion: 0.39
Nodes (7): AsyncEngine, create_engine_and_sessionmaker(), create_schema(), drop_schema(), get_db_from_sessionmaker(), async_sessionmaker, AsyncSession

### Community 100 - "dto.dart"
Cohesion: 0.29
Nodes (6): account_dto.dart, approval_dto.dart, auth_dto.dart, git_dto.dart, repo_dto.dart, task_dto.dart

### Community 101 - "SessionStreamRepository"
Cohesion: 0.40
Nodes (4): SessionStreamRepository, subscribe, MockSessionStreamRepository, NetworkSessionStreamRepository

### Community 102 - "app_router.dart"
Cohesion: 0.29
Nodes (6): GoRouter, state, package:mobile/app/router/page_transitions.dart, package:mobile/features/home/presentation/recents_screen.dart, package:mobile/features/repos/presentation/repos_screen.dart, package:mobile/features/welcome/presentation/welcome_screen.dart

### Community 103 - "mock_approval_repository.dart"
Cohesion: 0.17
Nodes (10): ApprovalRepository, approve, listPending, reject, approve, listPending, MockApprovalRepository, reject (+2 more)

### Community 104 - "AiSettingsStatus"
Cohesion: 0.50
Nodes (4): AiSettingsStatus, aiSettingsRepositoryProvider, AiSettingsController, build

### Community 105 - "Phodex mobile"
Cohesion: 0.25
Nodes (7): Connecting to a real desktop (no rebuild needed), Local demo: Android emulator, Phodex mobile, Push notifications, Real Google sign-in, UI-only mode, Verification

### Community 106 - "account_screen_test.dart"
Cohesion: 0.29
Nodes (6): drag, main, pump, scrollDown, settle, package:mobile/features/account/presentation/account_screen.dart

### Community 107 - "Settings"
Cohesion: 0.09
Nodes (29): get_settings(), field_validator, Settings, decrypt_secret(), encrypt_secret(), EncryptionKeyNotConfiguredError, _fernet(), _get_fernet() (+21 more)

### Community 108 - "package:mobile/core/domain/models/models.dart"
Cohesion: 0.11
Nodes (14): AiSettingsRepository, getStatus, update, getMe, confirmCommit, discardCommit, prepareCommit, MockAiSettingsRepository (+6 more)

### Community 109 - "PushRepository"
Cohesion: 0.33
Nodes (5): PushRepository, registerToken, unregisterToken, MockPushRepository, NetworkPushRepository

### Community 110 - "approvals_screen_test.dart"
Cohesion: 0.33
Nodes (5): main, pump, settle, textAnywhere, package:mobile/features/approvals/presentation/approvals_screen.dart

### Community 111 - "widget_test.dart"
Cohesion: 0.29
Nodes (6): buildTestApp, main, pump, settle, package:mobile/app/app.dart, package:mobile/features/session/presentation/session_screen.dart

### Community 113 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.40
Nodes (4): main, package:flutter_test/flutter_test.dart, package:integration_test/integration_test.dart, package:mobile/main.dart

### Community 114 - "AppColors"
Cohesion: 1.00
Nodes (3): @immutable, AppColors, ThemeExtension

### Community 115 - "CustomPainter"
Cohesion: 0.67
Nodes (3): CustomPainter, _RobinGlyphPainter, _RobinPainter

### Community 116 - "connect_desktop_screen_test.dart"
Cohesion: 0.40
Nodes (4): main, pump, settle, package:mobile/features/welcome/presentation/connect_desktop_screen.dart

### Community 117 - "home_screen_test.dart"
Cohesion: 0.40
Nodes (4): main, pump, settle, package:mobile/features/home/presentation/home_screen.dart

### Community 118 - "notifications_screen_test.dart"
Cohesion: 0.40
Nodes (4): main, pump, settle, package:mobile/features/notifications/presentation/notifications_screen.dart

### Community 119 - "sessions_screen_test.dart"
Cohesion: 0.40
Nodes (4): main, pump, settle, package:mobile/features/account/presentation/sessions_screen.dart

### Community 121 - "test_pairing.py"
Cohesion: 0.67
Nodes (3): AsyncClient, test_pairing_page_serves_a_qr_code_with_no_auth(), test_pairing_page_warns_when_address_is_guessed()

### Community 122 - "common_dto.dart"
Cohesion: 0.50
Nodes (3): parse, parseDateTime, parseNullableDateTime

### Community 123 - "sessionProvider"
Cohesion: 0.50
Nodes (4): sessionProvider, build, SessionScreen, Route /activity

### Community 124 - "test_helpers.dart"
Cohesion: 0.50
Nodes (3): main, package:mobile/features/ai_engine/presentation/ai_engine_screen.dart, test_helpers.dart

### Community 125 - "opencode.json"
Cohesion: 0.50
Nodes (3): plugin, $schema, .opencode/plugins/graphify.js

### Community 134 - "_PhodexMascotState"
Cohesion: 0.67
Nodes (3): PhodexMascot, _PhodexMascotState, SingleTickerProviderStateMixin

## Knowledge Gaps
- **913 isolated node(s):** `$schema`, `.opencode/plugins/graphify.js`, `smoke_test_backend_platform.sh script`, `Colors`, `main` (+908 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **19 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Settings` connect `Settings` to `datetime.py`, `codex/process_runner.py`, `utcnow`, `EventService`, `PushService`, `TaskService`, `test_claude_worker_integration.py`, `claude/process_runner.py`, `RedisService`, `task_service.py`, `ServiceRegistry`, `FakeWorkerEngine`, `auth_service.py`, `test_codex_worker_integration.py`?**
  _High betweenness centrality (0.048) - this node is a cross-community bridge._
- **Why does `ServiceRegistry` connect `ServiceRegistry` to `GitService`, `EventService`, `PushService`, `api/tasks.py`, `get_services`, `auth_service.py`, `ApprovalService`, `TaskService`, `RedisService`, `WorkerDispatcher`, `api/auth.py`, `User`, `utcnow`, `DeviceService`, `RepoSyncService`, `get_current_user`, `ORMModel`, `api/ai_settings.py`, `stream_task_events_alias`, `Settings`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `GitService` connect `GitService` to `datetime.py`, `EventService`, `git_service.py`, `Settings`, `TaskService`, `ServiceRegistry`, `auth_service.py`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `ServiceRegistry` (e.g. with `Settings` and `AccountService`) actually correct?**
  _`ServiceRegistry` has 14 INFERRED edges - model-reasoned connections that need verification._
- **Are the 18 inferred relationships involving `Settings` (e.g. with `EncryptionKeyNotConfiguredError` and `JWTManager`) actually correct?**
  _`Settings` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `User` (e.g. with `Base` and `TimestampMixin`) actually correct?**
  _`User` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 24 inferred relationships involving `TaskService` (e.g. with `ServiceRegistry` and `Settings`) actually correct?**
  _`TaskService` has 24 INFERRED edges - model-reasoned connections that need verification._