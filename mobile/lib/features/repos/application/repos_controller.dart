import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';

final repositoriesProvider =
    AsyncNotifierProvider<RepositoriesController, List<SyncedRepository>>(
      RepositoriesController.new,
    );

final selectedProjectContextProvider =
    AsyncNotifierProvider<SelectedProjectContextController, ProjectContext?>(
      SelectedProjectContextController.new,
    );

class RepositoriesController extends AsyncNotifier<List<SyncedRepository>> {
  @override
  Future<List<SyncedRepository>> build() async {
    final repoRepository = ref.watch(repoRepositoryProvider);
    return repoRepository.listRepositories();
  }

  Future<void> refreshList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repoRepository = ref.read(repoRepositoryProvider);
      return repoRepository.listRepositories();
    });
  }

  Future<ProjectContext> selectRepository({
    required String repoId,
    String? name,
  }) async {
    final repoRepository = ref.read(repoRepositoryProvider);
    final context = await repoRepository.selectRepository(
      repoId: repoId,
      name: name,
    );
    ref.read(selectedProjectContextProvider.notifier).setContext(context);
    return context;
  }
}

class SelectedProjectContextController extends AsyncNotifier<ProjectContext?> {
  @override
  Future<ProjectContext?> build() async {
    final repoRepository = ref.watch(repoRepositoryProvider);
    return repoRepository.getSelectedProjectContext();
  }

  void setContext(ProjectContext context) {
    state = AsyncData(context);
  }

  Future<void> refreshContext() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repoRepository = ref.read(repoRepositoryProvider);
      return repoRepository.getSelectedProjectContext();
    });
  }
}
