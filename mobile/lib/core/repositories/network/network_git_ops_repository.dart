import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkGitOpsRepository implements GitOpsRepository {
  const NetworkGitOpsRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<GitOperation> prepareCommit({required String taskId}) async {
    final json = await _apiClient.postJson('/tasks/$taskId/git/prepare');
    return GitOperationOutDto.fromJson(json).toDomain();
  }

  @override
  Future<GitOperation> confirmCommit({
    required String taskId,
    required String gitOperationId,
    String? commitMessage,
  }) async {
    final json = await _apiClient.postJson(
      '/tasks/$taskId/git/$gitOperationId/confirm',
      body: {'commit_message': commitMessage},
    );
    return GitOperationOutDto.fromJson(json).toDomain();
  }

  @override
  Future<GitOperation> discardCommit({
    required String taskId,
    required String gitOperationId,
  }) async {
    final json = await _apiClient.postJson(
      '/tasks/$taskId/git/$gitOperationId/discard',
    );
    return GitOperationOutDto.fromJson(json).toDomain();
  }
}
