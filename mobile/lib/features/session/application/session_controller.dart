import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/features/session/application/session_event_reducer.dart';
import 'package:mobile/features/session/application/session_state.dart';

final sessionProvider =
    StateNotifierProvider.family<
      SessionController,
      AsyncValue<SessionUiState>,
      String
    >((ref, taskId) {
      final controller = SessionController(ref, taskId);
      ref.onDispose(controller.disposeController);
      return controller;
    });

class SessionController extends StateNotifier<AsyncValue<SessionUiState>> {
  SessionController(this._ref, this._taskId) : super(const AsyncLoading()) {
    _init();
  }

  final Ref _ref;
  final String _taskId;
  StreamSubscription<TaskEventEnvelope>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;

  /// Backoff ladder for resubscribing after the stream drops: 1s, 2s, 4s …
  /// capped so a long outage never waits more than [_maxReconnectDelay].
  static const _maxReconnectDelay = Duration(seconds: 20);

  Future<void> _init() async {
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    state = await AsyncValue.guard(() async {
      final taskRepository = _ref.read(taskRepositoryProvider);
      final detail = await taskRepository.getTaskDetail(_taskId);
      return SessionUiState(
        task: detail.task,
        messages: detail.messages,
        events: detail.events,
        approvals: detail.approvals,
        issues: detail.issues,
        connection: detail.task.status.isTerminal
            ? SessionConnection.closed
            : SessionConnection.connecting,
      );
    });
    // Subscribe only once the session is in [state]: a stream that drops
    // immediately must find a session to mark as reconnecting. Terminal
    // tasks still subscribe — git operations emit events after completion.
    final session = state.asData?.value;
    if (session != null) {
      _subscribeToEvents(afterSequence: session.latestSequence);
    }
  }

  void _subscribeToEvents({required int afterSequence}) {
    _subscription?.cancel();
    if (_disposed) return;

    final streamRepository = _ref.read(sessionStreamRepositoryProvider);
    _subscription = streamRepository
        .subscribe(taskId: _taskId, afterSequence: afterSequence)
        .listen(
          (event) {
            _reconnectAttempt = 0;
            _setConnection(SessionConnection.live);
            _applyIncomingEvent(event);
          },
          onError: (Object _) => _scheduleReconnect(),
          onDone: _scheduleReconnect,
          cancelOnError: true,
        );
  }

  /// The stream ended or failed. If the task is still live that is a
  /// dropped connection, so back off and resubscribe from the last
  /// sequence we saw; if the task already finished the server simply closed
  /// the stream and there is nothing to reconnect to.
  void _scheduleReconnect() {
    if (_disposed) return;
    final current = state.asData?.value;
    if (current == null) return;
    if (current.task.status.isTerminal) {
      _setConnection(SessionConnection.closed);
      return;
    }
    _setConnection(SessionConnection.reconnecting);
    final seconds = math.min(
      1 << _reconnectAttempt,
      _maxReconnectDelay.inSeconds,
    );
    _reconnectAttempt += 1;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (_disposed) return;
      final latest = state.asData?.value.latestSequence ?? 0;
      _subscribeToEvents(afterSequence: latest);
    });
  }

  void _setConnection(SessionConnection connection) {
    final current = state.asData?.value;
    if (current == null || current.connection == connection) return;
    state = AsyncData(current.copyWith(connection: connection));
  }

  void _applyIncomingEvent(TaskEventEnvelope event) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final next = reduceSessionWithEvent(current, event);
    state = AsyncData(
      next.task.status.isTerminal
          ? next.copyWith(connection: SessionConnection.closed)
          : next,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _init();
  }

  Future<void> sendReply(String content) async {
    final current = state.asData?.value;
    if (current == null || current.task.status.isTerminal) {
      return;
    }

    state = AsyncData(current.copyWith(isSendingReply: true));

    try {
      final taskRepository = _ref.read(taskRepositoryProvider);
      final newMessage = await taskRepository.replyToTask(
        taskId: _taskId,
        content: content,
      );

      final updated = state.asData?.value ?? current;
      state = AsyncData(
        updated.copyWith(
          isSendingReply: false,
          messages: [...updated.messages, newMessage],
        ),
      );
    } catch (_) {
      final updated = state.asData?.value ?? current;
      state = AsyncData(updated.copyWith(isSendingReply: false));
      rethrow;
    }
  }

  Future<TaskSummary?> continueWithNewTask(String prompt) async {
    final current = state.asData?.value;
    if (current == null || !current.task.status.isTerminal) {
      return null;
    }

    state = AsyncData(current.copyWith(isSendingReply: true));

    try {
      final taskRepository = _ref.read(taskRepositoryProvider);
      final task = await taskRepository.createTask(
        prompt: prompt,
        projectContextId: current.task.projectContextId,
      );
      await _ref.read(homeTasksProvider.notifier).refresh();
      return task;
    } finally {
      final updated = state.asData?.value;
      if (updated != null) {
        state = AsyncData(updated.copyWith(isSendingReply: false));
      }
    }
  }

  Future<void> cancelTask() async {
    final taskRepository = _ref.read(taskRepositoryProvider);
    await taskRepository.cancelTask(_taskId);
    await refresh();
    await _ref.read(homeTasksProvider.notifier).refresh();
  }

  Future<void> approve(String approvalId) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(isResolvingApproval: true));

    try {
      final approvalRepository = _ref.read(approvalRepositoryProvider);
      await approvalRepository.approve(approvalId: approvalId);
    } catch (_) {
      final updated = state.asData?.value ?? current;
      state = AsyncData(updated.copyWith(isResolvingApproval: false));
      rethrow;
    }

    await refresh();
    await _ref.read(homeTasksProvider.notifier).refresh();
  }

  Future<void> reject(String approvalId, {String? note}) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(isResolvingApproval: true));

    try {
      final approvalRepository = _ref.read(approvalRepositoryProvider);
      await approvalRepository.reject(approvalId: approvalId, note: note);
    } catch (_) {
      final updated = state.asData?.value ?? current;
      state = AsyncData(updated.copyWith(isResolvingApproval: false));
      rethrow;
    }

    await refresh();
    await _ref.read(homeTasksProvider.notifier).refresh();
  }

  void disposeController() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
  }
}
