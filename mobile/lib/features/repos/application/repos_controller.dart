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

/// What the backend says about itself (desktop vs. Phodex Cloud, runner
/// name, whether it is online). Screens read it with `.asData?.value` and
/// never block on it — a slow `/runtime` call must not hold up the UI.
final runtimeInfoProvider = FutureProvider<RuntimeInfo>((ref) {
  return ref.watch(runtimeRepositoryProvider).getRuntimeInfo();
});

/// Human-friendly name + branch for a project context. The backend names a
/// context after its repository and branch ("phodex (feature/x)"), so when
/// the synced repository is known we show the bare repo name and let the
/// [ContextPill] add the branch itself instead of printing it twice.
({String name, String? branch}) describeProjectContext(
  ProjectContext context,
  List<SyncedRepository> repos,
) {
  for (final repo in repos) {
    if (repo.id == context.syncedRepositoryId) {
      return (name: repo.name, branch: context.branch ?? repo.currentBranch);
    }
  }
  final branch = context.branch;
  var name = context.name;
  if (branch != null && name.endsWith(' ($branch)')) {
    name = name.substring(0, name.length - branch.length - 3);
  }
  return (name: name, branch: branch);
}

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

  /// Re-fetches without flashing the loading state — used after connecting
  /// a GitHub repository so the list updates in place.
  Future<void> revalidate() async {
    final repoRepository = ref.read(repoRepositoryProvider);
    state = await AsyncValue.guard(repoRepository.listRepositories);
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

  /// Cloud runtime: clone a GitHub repository on the server, then refresh
  /// the list and make it the active context so the next task targets it.
  Future<SyncedRepository> connectGithubRepository({
    required String url,
    String? branch,
    String? token,
  }) async {
    final repoRepository = ref.read(repoRepositoryProvider);
    final repo = await repoRepository.connectGithubRepository(
      url: url,
      branch: branch,
      token: token,
    );
    await revalidate();
    await selectRepository(repoId: repo.id);
    return repo;
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
