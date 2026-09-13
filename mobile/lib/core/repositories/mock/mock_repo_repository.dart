import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockRepoRepository implements RepoRepository {
  const MockRepoRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<ProjectContext?> getSelectedProjectContext() async {
    await Future<void>.delayed(const Duration(milliseconds: 90));
    return _store.getSelectedProjectContext();
  }

  @override
  Future<SyncedRepository> getRepository(String repoId) async {
    await Future<void>.delayed(const Duration(milliseconds: 90));
    return _store.getRepository(repoId);
  }

  @override
  Future<List<SyncedRepository>> listRepositories() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.listRepositories();
  }

  @override
  Future<ProjectContext> selectRepository({
    required String repoId,
    String? name,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return _store.selectRepository(repoId: repoId, name: name);
  }

  @override
  Future<SyncedRepository> connectGithubRepository({
    required String url,
    String? branch,
    String? token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (token != null && token.isNotEmpty) _store.setGithubToken(true);
    return _store.addGithubRepository(url: url, branch: branch);
  }

  @override
  Future<bool> saveGithubToken(String? token) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    _store.setGithubToken(token != null && token.isNotEmpty);
    return _store.hasGithubToken;
  }
}
