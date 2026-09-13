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
    if (_selectedContext != null) return _selectedContext;
    final json = await _apiClient.getJson('/repos/context/current');
    final projectContextJson = json['project_context'] as Map<String, dynamic>?;
    if (projectContextJson == null) return null;
    _selectedContext = ProjectContextOutDto.fromJson(
      projectContextJson,
    ).toDomain();
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

  @override
  Future<SyncedRepository> connectGithubRepository({
    required String url,
    String? branch,
    String? token,
  }) async {
    final json = await _apiClient.postJson(
      '/repos/github/connect',
      body: {
        'url': url,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
        if (token != null && token.isNotEmpty) 'token': token,
      },
    );
    return SyncedRepositoryOutDto.fromJson(json).toDomain();
  }

  @override
  Future<bool> saveGithubToken(String? token) async {
    final json = await _apiClient.putJson(
      '/repos/github/credentials',
      body: token == null || token.isEmpty ? {'clear': true} : {'token': token},
    );
    return json['has_github_token'] as bool? ?? false;
  }
}
