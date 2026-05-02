import 'package:mobile/core/domain/models/models.dart';

class SessionUiState {
  const SessionUiState({
    required this.task,
    required this.messages,
    required this.events,
    required this.approvals,
    required this.issues,
    this.isSendingReply = false,
    this.isResolvingApproval = false,
  });

  final TaskSummary task;
  final List<TaskMessage> messages;
  final List<TaskEventEnvelope> events;
  final List<ApprovalRequest> approvals;
  final List<TaskIssue> issues;
  final bool isSendingReply;
  final bool isResolvingApproval;

  int get latestSequence => events.isEmpty ? 0 : events.last.sequence;

  SessionUiState copyWith({
    TaskSummary? task,
    List<TaskMessage>? messages,
    List<TaskEventEnvelope>? events,
    List<ApprovalRequest>? approvals,
    List<TaskIssue>? issues,
    bool? isSendingReply,
    bool? isResolvingApproval,
  }) {
    return SessionUiState(
      task: task ?? this.task,
      messages: messages ?? this.messages,
      events: events ?? this.events,
      approvals: approvals ?? this.approvals,
      issues: issues ?? this.issues,
      isSendingReply: isSendingReply ?? this.isSendingReply,
      isResolvingApproval: isResolvingApproval ?? this.isResolvingApproval,
    );
  }
}
