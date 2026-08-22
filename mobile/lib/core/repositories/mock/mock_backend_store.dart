import 'dart:async';
import 'dart:math';

import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/session/session_event_ordering.dart';

class MockBackendStore {
  MockBackendStore({bool enableDynamicSimulation = true})
    : _enableDynamicSimulation = enableDynamicSimulation {
    _seed();
  }

  final _random = Random();
  final Map<String, TaskSummary> _tasks = <String, TaskSummary>{};
  final Map<String, List<TaskMessage>> _messagesByTask =
      <String, List<TaskMessage>>{};
  final Map<String, List<TaskEventEnvelope>> _eventsByTask =
      <String, List<TaskEventEnvelope>>{};
  final Map<String, List<TaskIssue>> _issuesByTask =
      <String, List<TaskIssue>>{};
  final Map<String, ApprovalRequest> _approvalsById =
      <String, ApprovalRequest>{};
  final Map<String, GitOperation> _gitOperationsById = <String, GitOperation>{};
  AiSettingsStatus _aiSettings = const AiSettingsStatus(
    hasAnthropicKey: false,
    hasOpenaiKey: false,
  );
  final Map<String, StreamController<TaskEventEnvelope>> _eventControllers =
      <String, StreamController<TaskEventEnvelope>>{};

  final bool _enableDynamicSimulation;

  final List<SyncedRepository> _repositories = <SyncedRepository>[];

  ProjectContext? _selectedContext;

  int _idCounter = 40;

  final List<SessionInfo> _sessions = [
    SessionInfo(
      id: 'session_current',
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 6)),
      isCurrent: true,
    ),
    SessionInfo(
      id: 'session_ipad',
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 4)),
      isCurrent: false,
    ),
  ];

  final UserProfile _user = UserProfile(
    id: 'usr_001',
    googleSub: 'google-sub-001',
    email: 'gaurav@example.com',
    name: 'Gaurav Singh',
    avatarUrl: null,
    createdAt: DateTime.parse('2026-04-21T12:00:00Z'),
    updatedAt: DateTime.parse('2026-04-22T12:00:00Z'),
  );

  UserProfile get user => _user;

  List<TaskSummary> listTasks() {
    final values = _tasks.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  TaskDetail getTaskDetail(String taskId) {
    final task = _tasks[taskId];
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }
    return TaskDetail(
      task: task,
      messages: List<TaskMessage>.unmodifiable(
        _messagesByTask[taskId] ?? <TaskMessage>[],
      ),
      events: List<TaskEventEnvelope>.unmodifiable(
        _eventsByTask[taskId] ?? <TaskEventEnvelope>[],
      ),
      approvals:
          _approvalsById.values
              .where((approval) => approval.taskId == taskId)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      issues: List<TaskIssue>.unmodifiable(
        _issuesByTask[taskId] ?? <TaskIssue>[],
      ),
    );
  }

  List<TaskMessage> listMessages(String taskId) {
    return List<TaskMessage>.unmodifiable(
      _messagesByTask[taskId] ?? <TaskMessage>[],
    );
  }

  List<TaskEventEnvelope> listEvents(String taskId) {
    return List<TaskEventEnvelope>.unmodifiable(
      _eventsByTask[taskId] ?? <TaskEventEnvelope>[],
    );
  }

  List<TaskIssue> listIssues(String taskId) {
    return List<TaskIssue>.unmodifiable(_issuesByTask[taskId] ?? <TaskIssue>[]);
  }

  TaskSummary createTask({required String prompt, String? projectContextId}) {
    final now = DateTime.now().toUtc();
    final taskId = _nextId('task');
    final title = prompt.length > 42 ? '${prompt.substring(0, 42)}...' : prompt;

    final task = TaskSummary(
      id: taskId,
      userId: _user.id,
      projectContextId: projectContextId,
      title: title,
      prompt: prompt,
      status: TaskStatus.queued,
      currentPhase: 'queued',
      createdAt: now,
      updatedAt: now,
      startedAt: null,
      finishedAt: null,
      errorMessage: null,
      finalSummary: null,
      cancelledAt: null,
    );

    _tasks[taskId] = task;
    _messagesByTask[taskId] = <TaskMessage>[
      TaskMessage(
        id: _nextId('msg'),
        taskId: taskId,
        role: TaskMessageRole.user,
        content: prompt,
        createdAt: now,
      ),
    ];
    _eventsByTask[taskId] = <TaskEventEnvelope>[];
    _issuesByTask[taskId] = <TaskIssue>[];

    _emitEvent(
      taskId: taskId,
      type: 'task.created',
      data: {'message': 'Task created and queued'},
    );
    if (_enableDynamicSimulation) {
      _simulateTaskFlow(taskId);
    }

    return _tasks[taskId]!;
  }

  TaskSummary cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null) {
      throw StateError('Task not found');
    }

    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.failed) {
      return task;
    }
    if (task.status == TaskStatus.cancelled) {
      return task;
    }

    final now = DateTime.now().toUtc();
    final updated = task.copyWith(
      status: TaskStatus.cancelled,
      currentPhase: 'cancelled',
      cancelledAt: now,
      finishedAt: now,
      updatedAt: now,
      errorMessage: 'Task cancelled by user',
    );
    _tasks[taskId] = updated;

    _addIssue(
      taskId,
      type: 'task.cancelled',
      code: 'TASK_CANCELLED',
      message: 'Task was cancelled by user',
      data: {'is_retryable': true},
    );

    _emitEvent(
      taskId: taskId,
      type: 'task.cancelled',
      data: {'message': 'Task cancelled by user'},
    );
    return updated;
  }

  TaskMessage replyToTask({required String taskId, required String content}) {
    final task = _tasks[taskId];
    if (task == null) {
      throw StateError('Task not found');
    }

    final message = TaskMessage(
      id: _nextId('msg'),
      taskId: taskId,
      role: TaskMessageRole.user,
      content: content,
      createdAt: DateTime.now().toUtc(),
    );

    _messagesByTask[taskId] = <TaskMessage>[
      ...?_messagesByTask[taskId],
      message,
    ];
    _emitEvent(
      taskId: taskId,
      type: 'task.log',
      data: {'message': 'User follow-up received', 'content': content},
    );

    return message;
  }

  List<ApprovalRequest> listPendingApprovals() {
    return _approvalsById.values
        .where((approval) => approval.status == ApprovalStatus.pending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  ApprovalRequest approve(String approvalId, {String? note}) {
    final approval = _approvalsById[approvalId];
    if (approval == null) {
      throw StateError('Approval not found');
    }

    final resolved = approval.copyWith(
      status: ApprovalStatus.approved,
      resolvedAt: DateTime.now().toUtc(),
      payload: <String, dynamic>{
        ...approval.payload,
        if (note != null) 'resolution_note': note,
      },
    );

    _approvalsById[approvalId] = resolved;
    _emitEvent(
      taskId: approval.taskId,
      type: 'approval.approved',
      data: {'approval_id': approval.id, 'note': note},
    );

    _resumeAfterApproval(approval.taskId, approved: true);
    return resolved;
  }

  ApprovalRequest reject(String approvalId, {String? note}) {
    final approval = _approvalsById[approvalId];
    if (approval == null) {
      throw StateError('Approval not found');
    }

    final resolved = approval.copyWith(
      status: ApprovalStatus.rejected,
      resolvedAt: DateTime.now().toUtc(),
      payload: <String, dynamic>{
        ...approval.payload,
        if (note != null) 'resolution_note': note,
      },
    );

    _approvalsById[approvalId] = resolved;
    _emitEvent(
      taskId: approval.taskId,
      type: 'approval.rejected',
      data: {'approval_id': approval.id, 'note': note},
    );

    _resumeAfterApproval(approval.taskId, approved: false);
    return resolved;
  }

  GitOperation prepareCommit(String taskId) {
    final task = _tasks[taskId];
    if (task == null) {
      throw StateError('Task not found');
    }
    final operation = GitOperation(
      id: _nextId('git_op'),
      taskId: taskId,
      repoPath: '/mock/repo',
      commitMessage: 'Phodex: ${task.title ?? task.prompt}',
      status: GitOperationStatus.pendingReview,
      statusOutput: ' M lib/example.dart\n?? lib/new_file.dart',
      diffStatOutput:
          ' lib/example.dart | 4 ++--\n 1 file changed, 2 insertions(+), 2 deletions(-)',
    );
    _gitOperationsById[operation.id] = operation;
    return operation;
  }

  GitOperation confirmCommit(
    String taskId,
    String gitOperationId, {
    String? commitMessage,
  }) {
    final operation = _gitOperationsById[gitOperationId];
    if (operation == null || operation.taskId != taskId) {
      throw StateError('Git operation not found');
    }
    if (operation.status != GitOperationStatus.pendingReview) {
      throw StateError('Git operation already resolved');
    }
    final effectiveMessage =
        (commitMessage != null && commitMessage.trim().isNotEmpty)
        ? commitMessage
        : operation.commitMessage;
    final resolved = operation.copyWith(
      commitMessage: effectiveMessage,
      status: GitOperationStatus.completed,
    );
    _gitOperationsById[gitOperationId] = resolved;
    _emitEvent(
      taskId: taskId,
      type: 'git.started',
      data: {'message': 'Committing and pushing changes…'},
    );
    for (final line in [
      "add 'lib/example.dart'",
      "add 'lib/new_file.dart'",
      '[main abc1234] $effectiveMessage',
      ' 2 files changed, 6 insertions(+), 2 deletions(-)',
      'Enumerating objects: 5, done.',
      'Writing objects: 100% (3/3), done.',
      'To github.com:example/repo.git',
      '   9f8e7d6..abc1234  main -> main',
    ]) {
      _emitEvent(taskId: taskId, type: 'git.log', data: {'message': line});
    }
    _emitEvent(
      taskId: taskId,
      type: 'git.completed',
      data: {'message': 'Changes committed and pushed successfully.'},
    );
    return resolved;
  }

  GitOperation discardCommit(String taskId, String gitOperationId) {
    final operation = _gitOperationsById[gitOperationId];
    if (operation == null || operation.taskId != taskId) {
      throw StateError('Git operation not found');
    }
    final resolved = operation.copyWith(status: GitOperationStatus.rejected);
    _gitOperationsById[gitOperationId] = resolved;
    _emitEvent(
      taskId: taskId,
      type: 'git.discarded',
      data: {'message': 'Commit & push discarded by user'},
    );
    return resolved;
  }

  AiSettingsStatus getAiSettingsStatus() => _aiSettings;

  AiSettingsStatus updateAiSettings({
    String? anthropicApiKey,
    String? openaiApiKey,
    bool clearAnthropicKey = false,
    bool clearOpenaiKey = false,
    String? preferredClaudeModel,
    String? preferredCodexModel,
  }) {
    _aiSettings = AiSettingsStatus(
      hasAnthropicKey: clearAnthropicKey
          ? false
          : (anthropicApiKey?.isNotEmpty ?? _aiSettings.hasAnthropicKey),
      hasOpenaiKey: clearOpenaiKey
          ? false
          : (openaiApiKey?.isNotEmpty ?? _aiSettings.hasOpenaiKey),
      preferredClaudeModel:
          preferredClaudeModel ?? _aiSettings.preferredClaudeModel,
      preferredCodexModel:
          preferredCodexModel ?? _aiSettings.preferredCodexModel,
    );
    return _aiSettings;
  }

  List<SyncedRepository> listRepositories() {
    return List<SyncedRepository>.unmodifiable(_repositories);
  }

  SyncedRepository getRepository(String repoId) {
    return _repositories.firstWhere((repo) => repo.id == repoId);
  }

  ProjectContext selectRepository({required String repoId, String? name}) {
    final repo = getRepository(repoId);
    final now = DateTime.now().toUtc();
    _selectedContext = ProjectContext(
      id: _nextId('ctx'),
      userId: _user.id,
      sourceType: ProjectContextSourceType.localSynced,
      syncedRepositoryId: repo.id,
      name: name ?? '${repo.name} (${repo.currentBranch ?? 'main'})',
      repoUrl: null,
      branch: repo.currentBranch,
      metadata: {
        'local_path': repo.localPath,
        'git_root': repo.gitRoot,
        'device_id': repo.deviceId,
      },
      createdAt: now,
      updatedAt: now,
    );
    return _selectedContext!;
  }

  ProjectContext? getSelectedProjectContext() => _selectedContext;

  AccountSummary getAccountSummary() {
    return AccountSummary(
      user: _user,
      activeSessions: 1,
      deviceOnline: true,
      deviceLastSeenAt: DateTime.now().toUtc(),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  UsageSummary getUsageSummary() {
    final tasks = _tasks.values.toList();
    final totalEvents = _eventsByTask.values.fold<int>(
      0,
      (sum, events) => sum + events.length,
    );

    int countByStatus(TaskStatus status) {
      return tasks.where((task) => task.status == status).length;
    }

    return UsageSummary(
      userId: _user.id,
      generatedAt: DateTime.now().toUtc(),
      totalTasks: tasks.length,
      queuedTasks: countByStatus(TaskStatus.queued),
      runningTasks: countByStatus(TaskStatus.running),
      waitingApprovalTasks: countByStatus(TaskStatus.waitingApproval),
      completedTasks: countByStatus(TaskStatus.completed),
      failedTasks: countByStatus(TaskStatus.failed),
      cancelledTasks: countByStatus(TaskStatus.cancelled),
      pendingApprovals: listPendingApprovals().length,
      totalEvents: totalEvents,
      activeSessions: 1,
    );
  }

  List<SessionInfo> listSessions() => List.unmodifiable(_sessions);

  void revokeSession(String sessionId) {
    _sessions.removeWhere(
      (session) => session.id == sessionId && !session.isCurrent,
    );
  }

  int revokeOtherSessions() {
    final removed = _sessions.where((session) => !session.isCurrent).length;
    _sessions.removeWhere((session) => !session.isCurrent);
    return removed;
  }

  LimitStatus getLimitStatus() {
    final usage = getUsageSummary();
    const maxConcurrent = 3;
    const maxSessions = 2;

    final currentConcurrent =
        usage.queuedTasks + usage.runningTasks + usage.waitingApprovalTasks;

    return LimitStatus(
      generatedAt: DateTime.now().toUtc(),
      maxActiveSessions: maxSessions,
      activeSessions: usage.activeSessions,
      remainingActiveSessions: max(maxSessions - usage.activeSessions, 0),
      maxConcurrentTasks: maxConcurrent,
      currentConcurrentTasks: currentConcurrent,
      remainingConcurrentTasks: max(maxConcurrent - currentConcurrent, 0),
    );
  }

  Stream<TaskEventEnvelope> subscribeToEvents({
    required String taskId,
    int afterSequence = 0,
  }) {
    final backlog =
        (_eventsByTask[taskId] ?? <TaskEventEnvelope>[])
            .where((event) => event.sequence > afterSequence)
            .toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final controller = _eventControllers.putIfAbsent(
      taskId,
      () => StreamController<TaskEventEnvelope>.broadcast(),
    );

    return (() async* {
      for (final event in backlog) {
        yield event;
      }
      yield* controller.stream;
    })();
  }

  void _seed() {
    final now = DateTime.now().toUtc();

    _repositories.addAll([
      SyncedRepository(
        id: 'repo_001',
        userId: _user.id,
        deviceId: 'dev_mac_001',
        deviceName: "Gaurav's Mac",
        name: 'AFTR-backend',
        localPath: '/Users/gaurav/Documents/aftr/AFTR-backend',
        gitRoot: '/Users/gaurav/Documents/aftr/AFTR-backend',
        currentBranch: 'main',
        defaultBranch: 'main',
        isActive: true,
        lastScannedAt: now.subtract(const Duration(minutes: 6)),
        lastOpenedAt: now.subtract(const Duration(minutes: 35)),
        metadata: {'language': 'python', 'stars': 0},
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(minutes: 6)),
      ),
      SyncedRepository(
        id: 'repo_002',
        userId: _user.id,
        deviceId: 'dev_mac_001',
        deviceName: "Gaurav's Mac",
        name: 'phodex',
        localPath: '/Users/gaurav/phodex',
        gitRoot: '/Users/gaurav/phodex',
        currentBranch: 'feature/mobile-v1',
        defaultBranch: 'main',
        isActive: true,
        lastScannedAt: now.subtract(const Duration(minutes: 3)),
        lastOpenedAt: now.subtract(const Duration(minutes: 4)),
        metadata: {'language': 'dart', 'platform': 'flutter'},
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(minutes: 3)),
      ),
      SyncedRepository(
        id: 'repo_003',
        userId: _user.id,
        deviceId: 'dev_mac_001',
        deviceName: "Gaurav's Mac",
        name: 'legacy-tools',
        localPath: '/Users/gaurav/work/legacy-tools',
        gitRoot: '/Users/gaurav/work/legacy-tools',
        currentBranch: 'stable',
        defaultBranch: 'stable',
        isActive: false,
        lastScannedAt: now.subtract(const Duration(days: 1)),
        lastOpenedAt: now.subtract(const Duration(days: 2)),
        metadata: {'language': 'go'},
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    _selectedContext = ProjectContext(
      id: 'ctx_001',
      userId: _user.id,
      sourceType: ProjectContextSourceType.localSynced,
      syncedRepositoryId: 'repo_002',
      name: 'phodex (feature/mobile-v1)',
      repoUrl: null,
      branch: 'feature/mobile-v1',
      metadata: {
        'local_path': '/Users/gaurav/phodex',
        'git_root': '/Users/gaurav/phodex',
        'device_id': 'dev_mac_001',
      },
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    );

    final firstTask = createTask(
      prompt: 'Build Flutter mobile app shell with home and session routes',
      projectContextId: _selectedContext?.id,
    );
    _forceCompleteTask(firstTask.id);

    final secondTask = createTask(
      prompt:
          'Investigate CI failure in backend tests and summarize root cause',
      projectContextId: _selectedContext?.id,
    );
    _forceWaitingApproval(secondTask.id);

    createTask(
      prompt: 'Refactor account screen cards to follow new spacing tokens',
      projectContextId: _selectedContext?.id,
    );
  }

  void _forceCompleteTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    _tasks[taskId] = task.copyWith(
      status: TaskStatus.completed,
      currentPhase: 'done',
      startedAt: task.startedAt ?? now.subtract(const Duration(minutes: 2)),
      finishedAt: now,
      finalSummary: 'Mock task completed successfully.',
      updatedAt: now,
    );
    _emitEvent(
      taskId: taskId,
      type: 'task.log',
      data: {
        'message': 'Prepared patch preview for review',
        'file_changes': [
          {
            'action': 'deleted',
            'path': 'index.html',
            'added': 0,
            'removed': 255,
          },
          {
            'action': 'created',
            'path': 'index.html',
            'added': 326,
            'removed': 0,
          },
        ],
      },
    );
    _emitEvent(
      taskId: taskId,
      type: 'task.completed',
      data: {'message': 'Task completed'},
    );
  }

  void _forceWaitingApproval(String taskId) {
    final task = _tasks[taskId];
    if (task == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    _tasks[taskId] = task.copyWith(
      status: TaskStatus.waitingApproval,
      currentPhase: 'awaiting_user_approval',
      startedAt: task.startedAt ?? now.subtract(const Duration(minutes: 4)),
      updatedAt: now,
    );

    _emitEvent(
      taskId: taskId,
      type: 'task.progress',
      data: {
        'message':
            'I\'ll inspect the failing backend test path and compare it with the worker setup.',
      },
    );
    _emitEvent(
      taskId: taskId,
      type: 'task.log',
      data: {
        'item': {
          'type': 'command_execution',
          'command': 'rg "codex|worker|approval" backend/app backend/tests',
          'status': 'completed',
          'aggregated_output':
              'backend/app/workers/codex_worker.py\nbackend/tests/test_codex_worker_integration.py',
        },
      },
    );
    _emitEvent(
      taskId: taskId,
      type: 'task.log',
      data: {
        'item': {
          'type': 'command_execution',
          'command': 'sed -n "1,220p" backend/app/workers/codex_worker.py',
          'status': 'completed',
          'aggregated_output': 'Codex worker startup and approval gate loaded',
        },
      },
    );
    _emitEvent(
      taskId: taskId,
      type: 'task.progress',
      data: {
        'message':
            'Small wrinkle: the worker is reaching approval state correctly; I\'m pausing before applying file changes.',
      },
    );
    _emitEvent(
      taskId: taskId,
      type: 'task.log',
      data: {
        'message': 'Prepared patch preview',
        'file_changes': [
          {
            'action': 'modified',
            'path': 'backend/app/workers/codex_worker.py',
            'added': 42,
            'removed': 11,
          },
          {
            'action': 'modified',
            'path': 'backend/tests/test_codex_worker_integration.py',
            'added': 18,
            'removed': 4,
          },
        ],
      },
    );

    final approval = ApprovalRequest(
      id: _nextId('apr'),
      taskId: taskId,
      kind: 'command_execution',
      title: 'Approve file operation',
      description: 'Worker wants to apply changes to tracked files.',
      payload: {'command': 'git add -A && git commit', 'risk_level': 'medium'},
      status: ApprovalStatus.pending,
      createdAt: now,
      resolvedAt: null,
    );
    _approvalsById[approval.id] = approval;
    _emitEvent(
      taskId: taskId,
      type: 'approval.requested',
      data: {
        'approval_id': approval.id,
        'title': approval.title,
        'description': approval.description,
      },
    );
  }

  void _simulateTaskFlow(String taskId) {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      final task = _tasks[taskId];
      if (task == null || task.status.isTerminal) {
        return;
      }
      final now = DateTime.now().toUtc();
      _tasks[taskId] = task.copyWith(
        status: TaskStatus.starting,
        currentPhase: 'booting_worker',
        startedAt: now,
        updatedAt: now,
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.starting',
        data: {'message': 'Starting worker'},
      );
    });

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      final task = _tasks[taskId];
      if (task == null || task.status.isTerminal) {
        return;
      }
      final now = DateTime.now().toUtc();
      _tasks[taskId] = task.copyWith(
        status: TaskStatus.running,
        currentPhase: 'analyzing_context',
        startedAt: task.startedAt ?? now,
        updatedAt: now,
      );
      _messagesByTask[taskId] = <TaskMessage>[
        ...?_messagesByTask[taskId],
        TaskMessage(
          id: _nextId('msg'),
          taskId: taskId,
          role: TaskMessageRole.assistant,
          content: 'I\'ll analyze the repo and prepare a safe execution plan.',
          createdAt: now,
        ),
      ];
      _emitEvent(
        taskId: taskId,
        type: 'task.running',
        data: {'message': 'Task is running'},
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.progress',
        data: {'message': 'Reading repository structure'},
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.log',
        data: {
          'item': {
            'type': 'command_execution',
            'command': 'rg --files lib test',
            'status': 'completed',
            'aggregated_output':
                'lib/features/home/presentation/home_screen.dart\nlib/features/session/presentation/session_screen.dart',
          },
        },
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.log',
        data: {
          'item': {
            'type': 'command_execution',
            'command': 'ls lib/features',
            'status': 'completed',
            'aggregated_output': 'account approvals home repos session',
          },
        },
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.log',
        data: {'message': 'Found 147 files across 12 modules'},
      );
    });

    Future<void>.delayed(const Duration(milliseconds: 2100), () {
      final task = _tasks[taskId];
      if (task == null || task.status.isTerminal) {
        return;
      }
      final now = DateTime.now().toUtc();
      final approval = ApprovalRequest(
        id: _nextId('apr'),
        taskId: taskId,
        kind: 'command_execution',
        title: 'Approve potentially risky action',
        description: 'Worker wants approval before running a risky command.',
        payload: {
          'command': 'git clean -xdf',
          'risk_level': 'high',
          'dry_run': false,
        },
        status: ApprovalStatus.pending,
        createdAt: now,
        resolvedAt: null,
      );
      _approvalsById[approval.id] = approval;

      _tasks[taskId] = task.copyWith(
        status: TaskStatus.waitingApproval,
        currentPhase: 'awaiting_user_approval',
        updatedAt: now,
      );

      _emitEvent(
        taskId: taskId,
        type: 'approval.requested',
        data: {
          'approval_id': approval.id,
          'title': approval.title,
          'description': approval.description,
          'risk_level': 'high',
        },
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.progress',
        data: {'message': 'Waiting for user approval'},
      );
    });
  }

  void _resumeAfterApproval(String taskId, {required bool approved}) {
    final task = _tasks[taskId];
    if (task == null || task.status.isTerminal) {
      return;
    }

    if (!approved) {
      final now = DateTime.now().toUtc();
      _tasks[taskId] = task.copyWith(
        status: TaskStatus.failed,
        currentPhase: 'approval_rejected',
        errorMessage: 'Approval rejected',
        finishedAt: now,
        updatedAt: now,
      );

      _addIssue(
        taskId,
        type: 'task.failed',
        code: 'APPROVAL_REJECTED',
        message: 'Task failed because approval was rejected.',
        data: {'is_retryable': false},
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.failed',
        data: {
          'message': 'Task failed because approval was rejected',
          'error_code': 'APPROVAL_REJECTED',
          'is_retryable': false,
        },
      );
      return;
    }

    final now = DateTime.now().toUtc();
    _tasks[taskId] = task.copyWith(
      status: TaskStatus.running,
      currentPhase: 'post_approval_execution',
      updatedAt: now,
    );
    _emitEvent(
      taskId: taskId,
      type: 'task.running',
      data: {'message': 'Resuming after approval'},
    );

    void completeTask() {
      final currentTask = _tasks[taskId];
      if (currentTask == null || currentTask.status.isTerminal) {
        return;
      }

      final completedAt = DateTime.now().toUtc();
      _tasks[taskId] = currentTask.copyWith(
        status: TaskStatus.completed,
        currentPhase: 'done',
        finalSummary: 'Approved action completed. All checks passed.',
        finishedAt: completedAt,
        updatedAt: completedAt,
      );

      _messagesByTask[taskId] = <TaskMessage>[
        ...?_messagesByTask[taskId],
        TaskMessage(
          id: _nextId('msg'),
          taskId: taskId,
          role: TaskMessageRole.assistant,
          content:
              'Done. I completed the task after approval and prepared final output.',
          createdAt: completedAt,
        ),
      ];

      _emitEvent(
        taskId: taskId,
        type: 'task.progress',
        data: {'message': 'Applying approved action'},
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.log',
        data: {
          'message': 'Applied code edits',
          'file_changes': [
            {
              'action': 'modified',
              'path': 'lib/features/home/presentation/home_screen.dart',
              'added': 62,
              'removed': 18,
            },
            {
              'action': 'created',
              'path': 'lib/features/home/presentation/recents_screen.dart',
              'added': 124,
              'removed': 0,
            },
          ],
        },
      );
      _emitEvent(
        taskId: taskId,
        type: 'task.completed',
        data: {
          'message': 'Task completed',
          'summary': 'Approved action completed. All checks passed.',
        },
      );
    }

    if (_enableDynamicSimulation) {
      Future<void>.delayed(const Duration(milliseconds: 900), completeTask);
    } else {
      completeTask();
    }
  }

  void _emitEvent({
    required String taskId,
    required String type,
    required Map<String, dynamic> data,
  }) {
    final now = DateTime.now().toUtc();
    final currentEvents = _eventsByTask[taskId] ?? <TaskEventEnvelope>[];

    final event = TaskEventEnvelope(
      eventId: _nextId('evt'),
      taskId: taskId,
      sequence: currentEvents.length + 1,
      type: type,
      timestamp: now,
      data: data,
    );

    final merged = mergeOrderedEvents(currentEvents, <TaskEventEnvelope>[
      event,
    ]);
    _eventsByTask[taskId] = merged;

    final task = _tasks[taskId];
    if (task != null) {
      _tasks[taskId] = task.copyWith(updatedAt: now);
    }

    final controller = _eventControllers.putIfAbsent(
      taskId,
      () => StreamController<TaskEventEnvelope>.broadcast(),
    );
    controller.add(event);
  }

  void _addIssue(
    String taskId, {
    required String type,
    required String code,
    required String message,
    required Map<String, dynamic> data,
  }) {
    final events = _eventsByTask[taskId] ?? <TaskEventEnvelope>[];
    final sequence = events.isEmpty ? 1 : events.last.sequence + 1;
    final issue = TaskIssue(
      sequence: sequence,
      type: type,
      timestamp: DateTime.now().toUtc(),
      code: code,
      message: message,
      data: data,
    );

    _issuesByTask[taskId] = <TaskIssue>[...?_issuesByTask[taskId], issue];
  }

  String _nextId(String prefix) {
    _idCounter += 1;
    final salt = _random.nextInt(8999) + 1000;
    return '${prefix}_${_idCounter}_$salt';
  }
}
