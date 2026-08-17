import 'package:mobile/core/domain/models/models.dart';

abstract class GitOpsRepository {
  Future<GitOperation> prepareCommit({required String taskId});

  Future<GitOperation> confirmCommit({
    required String taskId,
    required String gitOperationId,
    String? commitMessage,
  });

  Future<GitOperation> discardCommit({
    required String taskId,
    required String gitOperationId,
  });
}
