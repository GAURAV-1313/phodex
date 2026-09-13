import 'package:mobile/core/domain/models/models.dart';

/// Where the live event stream (SSE) for a session currently stands. The
/// screen shows a "Reconnecting…" banner only while [reconnecting].
enum SessionConnection {
  /// Initial subscription in flight; nothing has been received yet.
  connecting,

  /// Events are arriving.
  live,

  /// The stream dropped (network hiccup, server restart) and the controller
  /// is backing off before resubscribing.
  reconnecting,

  /// The task reached a terminal state, so the stream was closed on purpose.
  closed,
}

class SessionUiState {
  const SessionUiState({
    required this.task,
    required this.messages,
    required this.events,
    required this.approvals,
    required this.issues,
    this.isSendingReply = false,
    this.isResolvingApproval = false,
    this.connection = SessionConnection.connecting,
  });

  final TaskSummary task;
  final List<TaskMessage> messages;
  final List<TaskEventEnvelope> events;
  final List<ApprovalRequest> approvals;
  final List<TaskIssue> issues;
  final bool isSendingReply;
  final bool isResolvingApproval;
  final SessionConnection connection;

  int get latestSequence => events.isEmpty ? 0 : events.last.sequence;

  /// The worker is actively executing (as opposed to paused on an approval
  /// or finished) — drives the composer's stop button and the status pulse.
  bool get isExecuting =>
      task.status == TaskStatus.queued ||
      task.status == TaskStatus.starting ||
      task.status == TaskStatus.running;

  bool get isReconnecting => connection == SessionConnection.reconnecting;

  SessionUiState copyWith({
    TaskSummary? task,
    List<TaskMessage>? messages,
    List<TaskEventEnvelope>? events,
    List<ApprovalRequest>? approvals,
    List<TaskIssue>? issues,
    bool? isSendingReply,
    bool? isResolvingApproval,
    SessionConnection? connection,
  }) {
    return SessionUiState(
      task: task ?? this.task,
      messages: messages ?? this.messages,
      events: events ?? this.events,
      approvals: approvals ?? this.approvals,
      issues: issues ?? this.issues,
      isSendingReply: isSendingReply ?? this.isSendingReply,
      isResolvingApproval: isResolvingApproval ?? this.isResolvingApproval,
      connection: connection ?? this.connection,
    );
  }
}
