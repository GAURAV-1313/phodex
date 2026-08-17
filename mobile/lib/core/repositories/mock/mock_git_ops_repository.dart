import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockGitOpsRepository implements GitOpsRepository {
  const MockGitOpsRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<GitOperation> prepareCommit({required String taskId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _store.prepareCommit(taskId);
  }

  @override
  Future<GitOperation> confirmCommit({
    required String taskId,
    required String gitOperationId,
    String? commitMessage,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _store.confirmCommit(
      taskId,
      gitOperationId,
      commitMessage: commitMessage,
    );
  }

  @override
  Future<GitOperation> discardCommit({
    required String taskId,
    required String gitOperationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.discardCommit(taskId, gitOperationId);
  }
}
