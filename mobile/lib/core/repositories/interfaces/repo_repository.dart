import 'package:mobile/core/domain/models/models.dart';

abstract class RepoRepository {
  Future<List<SyncedRepository>> listRepositories();

  Future<SyncedRepository> getRepository(String repoId);

  Future<ProjectContext> selectRepository({
    required String repoId,
    String? name,
  });

  Future<ProjectContext?> getSelectedProjectContext();
}
