import 'dart:async';

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

  Future<void> _init() async {
    state = await AsyncValue.guard(() async {
      final taskRepository = _ref.read(taskRepositoryProvider);
      final detail = await taskRepository.getTaskDetail(_taskId);
      final session = SessionUiState(
        task: detail.task,
        messages: detail.messages,
        events: detail.events,
        approvals: detail.approvals,
        issues: detail.issues,
      );
      _subscribeToEvents(afterSequence: session.latestSequence);
      return session;
    });
  }

  void _subscribeToEvents({required int afterSequence}) {
    _subscription?.cancel();

    final streamRepository = _ref.read(sessionStreamRepositoryProvider);
    _subscription = streamRepository
        .subscribe(taskId: _taskId, afterSequence: afterSequence)
        .listen(_applyIncomingEvent);
  }

  void _applyIncomingEvent(TaskEventEnvelope event) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    state = AsyncData(reduceSessionWithEvent(current, event));
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

    final approvalRepository = _ref.read(approvalRepositoryProvider);
    await approvalRepository.approve(approvalId: approvalId);

    await refresh();
    await _ref.read(homeTasksProvider.notifier).refresh();
  }

  Future<void> reject(String approvalId, {String? note}) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(isResolvingApproval: true));

    final approvalRepository = _ref.read(approvalRepositoryProvider);
    await approvalRepository.reject(approvalId: approvalId, note: note);

    await refresh();
    await _ref.read(homeTasksProvider.notifier).refresh();
  }

  void disposeController() {
    _subscription?.cancel();
  }
}
