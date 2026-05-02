import 'package:mobile/core/domain/models/models.dart';

abstract class TaskRepository {
  Future<List<TaskSummary>> listTasks();

  Future<TaskSummary> createTask({
    required String prompt,
    String? projectContextId,
  });

  Future<TaskDetail> getTaskDetail(String taskId);

  Future<List<TaskMessage>> listMessages(String taskId);

  Future<List<TaskEventEnvelope>> listEvents(String taskId);

  Future<List<TaskIssue>> listIssues(String taskId);

  Future<TaskMessage> replyToTask({
    required String taskId,
    required String content,
  });

  Future<TaskSummary> cancelTask(String taskId);
}
