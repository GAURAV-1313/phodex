import 'package:mobile/core/domain/models/models.dart';

abstract class RepoRepository {
  Future<List<SyncedRepository>> listRepositories();

  Future<SyncedRepository> getRepository(String repoId);

  Future<ProjectContext> selectRepository({
    required String repoId,
    String? name,
  });

  Future<ProjectContext?> getSelectedProjectContext();

  /// Cloud runtime: clone (or refresh) a GitHub repository on the server so
  /// it can be selected like any synced repository.
  Future<SyncedRepository> connectGithubRepository({
    required String url,
    String? branch,
    String? token,
  });

  /// Stores (or clears, with null) the user's GitHub token for pushes from
  /// cloud workspaces. Returns whether a token is configured afterwards.
  Future<bool> saveGithubToken(String? token);
}
