import 'package:mobile/core/data/dto/approval_dto.dart';
import 'package:mobile/core/data/dto/common_dto.dart';
import 'package:mobile/core/domain/models/models.dart';

class TaskOutDto {
  const TaskOutDto({
    required this.id,
    required this.userId,
    required this.projectContextId,
    required this.title,
    required this.prompt,
    required this.status,
    required this.currentPhase,
    required this.createdAt,
    required this.updatedAt,
    required this.startedAt,
    required this.finishedAt,
    required this.errorMessage,
    required this.finalSummary,
    required this.cancelledAt,
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

  factory TaskOutDto.fromJson(Map<String, dynamic> json) {
    return TaskOutDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectContextId: json['project_context_id'] as String?,
      title: json['title'] as String?,
      prompt: json['prompt'] as String,
      status: TaskStatusX.fromValue(json['status'] as String),
      currentPhase: json['current_phase'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      startedAt: parseNullableDateTime(json['started_at']),
      finishedAt: parseNullableDateTime(json['finished_at']),
      errorMessage: json['error_message'] as String?,
      finalSummary: json['final_summary'] as String?,
      cancelledAt: parseNullableDateTime(json['cancelled_at']),
    );
  }

  TaskSummary toDomain() {
    return TaskSummary(
      id: id,
      userId: userId,
      projectContextId: projectContextId,
      title: title,
      prompt: prompt,
      status: status,
      currentPhase: currentPhase,
      createdAt: createdAt,
      updatedAt: updatedAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
      errorMessage: errorMessage,
      finalSummary: finalSummary,
      cancelledAt: cancelledAt,
    );
  }
}

class TaskMessageOutDto {
  const TaskMessageOutDto({
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

  factory TaskMessageOutDto.fromJson(Map<String, dynamic> json) {
    return TaskMessageOutDto(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      role: TaskMessageRoleX.fromValue(json['role'] as String),
      content: json['content'] as String,
      createdAt: parseDateTime(json['created_at']),
    );
  }

  TaskMessage toDomain() {
    return TaskMessage(
      id: id,
      taskId: taskId,
      role: role,
      content: content,
      createdAt: createdAt,
    );
  }
}

class TaskEventEnvelopeDto {
  const TaskEventEnvelopeDto({
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

  factory TaskEventEnvelopeDto.fromJson(Map<String, dynamic> json) {
    return TaskEventEnvelopeDto(
      eventId: json['event_id'] as String,
      taskId: json['task_id'] as String,
      sequence: json['sequence'] as int,
      type: json['type'] as String,
      timestamp: parseDateTime(json['timestamp']),
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  TaskEventEnvelope toDomain() {
    return TaskEventEnvelope(
      eventId: eventId,
      taskId: taskId,
      sequence: sequence,
      type: type,
      timestamp: timestamp,
      data: data,
    );
  }
}

class TaskIssueOutDto {
  const TaskIssueOutDto({
    required this.sequence,
    required this.type,
    required this.timestamp,
    required this.code,
    required this.message,
    required this.data,
  });

  final int sequence;
  final String type;
  final DateTime timestamp;
  final String? code;
  final String message;
  final Map<String, dynamic> data;

  factory TaskIssueOutDto.fromJson(Map<String, dynamic> json) {
    return TaskIssueOutDto(
      sequence: json['sequence'] as int,
      type: json['type'] as String,
      timestamp: parseDateTime(json['timestamp']),
      code: json['code'] as String?,
      message: json['message'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  TaskIssue toDomain() {
    return TaskIssue(
      sequence: sequence,
      type: type,
      timestamp: timestamp,
      code: code,
      message: message,
      data: data,
    );
  }
}

class TaskDetailResponseDto {
  const TaskDetailResponseDto({
    required this.task,
    required this.messages,
    required this.events,
    required this.approvals,
  });

  final TaskOutDto task;
  final List<TaskMessageOutDto> messages;
  final List<TaskEventEnvelopeDto> events;
  final List<ApprovalRequestOutDto> approvals;

  factory TaskDetailResponseDto.fromJson(Map<String, dynamic> json) {
    final messageList = (json['messages'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    final eventList = (json['events'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    final approvalList = (json['approvals'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return TaskDetailResponseDto(
      task: TaskOutDto.fromJson(json['task'] as Map<String, dynamic>),
      messages: messageList.map(TaskMessageOutDto.fromJson).toList(),
      events: eventList.map(TaskEventEnvelopeDto.fromJson).toList(),
      approvals: approvalList.map(ApprovalRequestOutDto.fromJson).toList(),
    );
  }
}

class TaskListResponseDto {
  const TaskListResponseDto({required this.items});

  final List<TaskOutDto> items;

  factory TaskListResponseDto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return TaskListResponseDto(items: items.map(TaskOutDto.fromJson).toList());
  }
}

class TaskMessagesResponseDto {
  const TaskMessagesResponseDto({required this.items});

  final List<TaskMessageOutDto> items;

  factory TaskMessagesResponseDto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return TaskMessagesResponseDto(
      items: items.map(TaskMessageOutDto.fromJson).toList(),
    );
  }
}

class TaskEventsResponseDto {
  const TaskEventsResponseDto({required this.items});

  final List<TaskEventEnvelopeDto> items;

  factory TaskEventsResponseDto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return TaskEventsResponseDto(
      items: items.map(TaskEventEnvelopeDto.fromJson).toList(),
    );
  }
}

class TaskIssuesResponseDto {
  const TaskIssuesResponseDto({required this.items});

  final List<TaskIssueOutDto> items;

  factory TaskIssuesResponseDto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return TaskIssuesResponseDto(
      items: items.map(TaskIssueOutDto.fromJson).toList(),
    );
  }
}
