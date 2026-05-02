import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';

extension TaskDetailResponseMapper on TaskDetailResponseDto {
  TaskDetail toDomainWithIssues(List<TaskIssue> issues) {
    return TaskDetail(
      task: task.toDomain(),
      messages: messages.map((message) => message.toDomain()).toList(),
      events: events.map((event) => event.toDomain()).toList(),
      approvals: approvals.map((approval) => approval.toDomain()).toList(),
      issues: issues,
    );
  }
}
