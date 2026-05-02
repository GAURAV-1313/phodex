import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkRepoRepository implements RepoRepository {
  NetworkRepoRepository(this._apiClient);

  final PhodexApiClient _apiClient;
  ProjectContext? _selectedContext;

  @override
  Future<ProjectContext?> getSelectedProjectContext() async {
    return _selectedContext;
  }

  @override
  Future<SyncedRepository> getRepository(String repoId) async {
    final json = await _apiClient.getJson('/repos/$repoId');
    return SyncedRepositoryOutDto.fromJson(json).toDomain();
  }

  @override
  Future<List<SyncedRepository>> listRepositories() async {
    final json = await _apiClient.getJson('/repos');
    return RepoListResponseDto.fromJson(
      json,
    ).items.map((item) => item.toDomain()).toList();
  }

  @override
  Future<ProjectContext> selectRepository({
    required String repoId,
    String? name,
  }) async {
    final json = await _apiClient.postJson(
      '/repos/$repoId/select',
      body: {'name': name},
    );
    final projectContextJson =
        json['project_context'] as Map<String, dynamic>? ?? json;
    final context = ProjectContextOutDto.fromJson(
      projectContextJson,
    ).toDomain();
    _selectedContext = context;
    return context;
  }
}
