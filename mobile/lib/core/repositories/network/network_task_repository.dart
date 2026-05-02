import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/data/mappers/mappers.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkTaskRepository implements TaskRepository {
  const NetworkTaskRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<TaskSummary> cancelTask(String taskId) async {
    final json = await _apiClient.postJson('/tasks/$taskId/cancel');
    return TaskOutDto.fromJson(json).toDomain();
  }

  @override
  Future<TaskSummary> createTask({
    required String prompt,
    String? projectContextId,
  }) async {
    final json = await _apiClient.postJson(
      '/tasks',
      body: {
        'prompt': prompt,
        if (projectContextId != null) 'project_context_id': projectContextId,
      },
    );
    return TaskOutDto.fromJson(json).toDomain();
  }

  @override
  Future<TaskDetail> getTaskDetail(String taskId) async {
    final json = await _apiClient.getJson('/tasks/$taskId');
    final dto = TaskDetailResponseDto.fromJson(json);
    final issues = await listIssues(taskId);
    return dto.toDomainWithIssues(issues);
  }

  @override
  Future<List<TaskEventEnvelope>> listEvents(String taskId) async {
    final json = await _apiClient.getJson('/tasks/$taskId/events');
    return TaskEventsResponseDto.fromJson(
      json,
    ).items.map((item) => item.toDomain()).toList();
  }

  @override
  Future<List<TaskIssue>> listIssues(String taskId) async {
    final json = await _apiClient.getJson('/tasks/$taskId/issues');
    return TaskIssuesResponseDto.fromJson(
      json,
    ).items.map((item) => item.toDomain()).toList();
  }

  @override
  Future<List<TaskMessage>> listMessages(String taskId) async {
    final json = await _apiClient.getJson('/tasks/$taskId/messages');
    return TaskMessagesResponseDto.fromJson(
      json,
    ).items.map((item) => item.toDomain()).toList();
  }

  @override
  Future<List<TaskSummary>> listTasks() async {
    final json = await _apiClient.getJson('/tasks');
    return TaskListResponseDto.fromJson(
      json,
    ).items.map((item) => item.toDomain()).toList();
  }

  @override
  Future<TaskMessage> replyToTask({
    required String taskId,
    required String content,
  }) async {
    final json = await _apiClient.postJson(
      '/tasks/$taskId/reply',
      body: {'content': content},
    );
    return TaskMessageOutDto.fromJson(json).toDomain();
  }
}
