import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockTaskRepository implements TaskRepository {
  const MockTaskRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<TaskSummary> cancelTask(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.cancelTask(taskId);
  }

  @override
  Future<TaskSummary> createTask({
    required String prompt,
    String? projectContextId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return _store.createTask(
      prompt: prompt,
      projectContextId: projectContextId,
    );
  }

  @override
  Future<TaskDetail> getTaskDetail(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _store.getTaskDetail(taskId);
  }

  @override
  Future<List<TaskEventEnvelope>> listEvents(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _store.listEvents(taskId);
  }

  @override
  Future<List<TaskIssue>> listIssues(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _store.listIssues(taskId);
  }

  @override
  Future<List<TaskMessage>> listMessages(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _store.listMessages(taskId);
  }

  @override
  Future<List<TaskSummary>> listTasks() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.listTasks();
  }

  @override
  Future<TaskMessage> replyToTask({
    required String taskId,
    required String content,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.replyToTask(taskId: taskId, content: content);
  }
}
