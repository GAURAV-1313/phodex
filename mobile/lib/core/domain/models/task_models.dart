import 'approval_models.dart';

enum TaskStatus {
  queued,
  starting,
  running,
  waitingApproval,
  completed,
  failed,
  cancelled,
}

extension TaskStatusX on TaskStatus {
  String get value => switch (this) {
    TaskStatus.queued => 'queued',
    TaskStatus.starting => 'starting',
    TaskStatus.running => 'running',
    TaskStatus.waitingApproval => 'waiting_approval',
    TaskStatus.completed => 'completed',
    TaskStatus.failed => 'failed',
    TaskStatus.cancelled => 'cancelled',
  };

  bool get isTerminal =>
      this == TaskStatus.completed ||
      this == TaskStatus.failed ||
      this == TaskStatus.cancelled;

  static TaskStatus fromValue(String value) {
    return switch (value) {
      'queued' => TaskStatus.queued,
      'starting' => TaskStatus.starting,
      'running' => TaskStatus.running,
      'waiting_approval' => TaskStatus.waitingApproval,
      'completed' => TaskStatus.completed,
      'failed' => TaskStatus.failed,
      'cancelled' => TaskStatus.cancelled,
      _ => TaskStatus.queued,
    };
  }
}

enum TaskMessageRole { user, assistant, system }

extension TaskMessageRoleX on TaskMessageRole {
  String get value => switch (this) {
    TaskMessageRole.user => 'user',
    TaskMessageRole.assistant => 'assistant',
    TaskMessageRole.system => 'system',
  };

  static TaskMessageRole fromValue(String value) {
    return switch (value) {
      'assistant' => TaskMessageRole.assistant,
      'system' => TaskMessageRole.system,
      _ => TaskMessageRole.user,
    };
  }
}

class TaskSummary {
  const TaskSummary({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.projectContextId,
    this.title,
    this.currentPhase,
    this.startedAt,
    this.finishedAt,
    this.errorMessage,
    this.finalSummary,
    this.cancelledAt,
  });

  final String id;
  final String userId;
  final String? projectContextId;
  final String? title;
  final String prompt;
  final TaskStatus status;
  final String? currentPhase;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? errorMessage;
  final String? finalSummary;
  final DateTime? cancelledAt;

  TaskSummary copyWith({
    String? id,
    String? userId,
    String? projectContextId,
    String? title,
    String? prompt,
    TaskStatus? status,
    String? currentPhase,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? errorMessage,
    String? finalSummary,
    DateTime? cancelledAt,
  }) {
    return TaskSummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectContextId: projectContextId ?? this.projectContextId,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      finalSummary: finalSummary ?? this.finalSummary,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

class TaskMessage {
  const TaskMessage({
    required this.id,
    required this.taskId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final TaskMessageRole role;
  final String content;
  final DateTime createdAt;
}

class TaskEventEnvelope {
  const TaskEventEnvelope({
    required this.eventId,
    required this.taskId,
    required this.sequence,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  final String eventId;
  final String taskId;
  final int sequence;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
}

class TaskIssue {
  const TaskIssue({
    required this.sequence,
    required this.type,
    required this.timestamp,
    required this.message,
    required this.data,
    this.code,
  });

  final int sequence;
  final String type;
  final DateTime timestamp;
  final String? code;
  final String message;
  final Map<String, dynamic> data;
}

class TaskDetail {
  const TaskDetail({
    required this.task,
    required this.messages,
    required this.events,
    required this.approvals,
    required this.issues,
  });

  final TaskSummary task;
  final List<TaskMessage> messages;
  final List<TaskEventEnvelope> events;
  final List<ApprovalRequest> approvals;
  final List<TaskIssue> issues;
}
