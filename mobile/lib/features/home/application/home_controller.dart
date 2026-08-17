import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';

final homeTasksProvider =
    AsyncNotifierProvider<HomeTasksController, List<TaskSummary>>(
      HomeTasksController.new,
    );

class HomeTasksController extends AsyncNotifier<List<TaskSummary>> {
  @override
  Future<List<TaskSummary>> build() async {
    final taskRepository = ref.watch(taskRepositoryProvider);
    return taskRepository.listTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final taskRepository = ref.read(taskRepositoryProvider);
      return taskRepository.listTasks();
    });
  }

  /// Re-fetches without the [AsyncLoading] flash `refresh` does — for
  /// silently catching up on status changes (e.g. a task finishing while
  /// the user was elsewhere) when a screen that reads this list reappears,
  /// where swapping the whole list out for a spinner would be jarring.
  Future<void> revalidate() async {
    final taskRepository = ref.read(taskRepositoryProvider);
    try {
      final tasks = await taskRepository.listTasks();
      state = AsyncData(tasks);
    } catch (_) {
      // Keep showing the last known list on a transient failure.
    }
  }

  Future<TaskSummary> createTask(String prompt) async {
    final taskRepository = ref.read(taskRepositoryProvider);
    final context = ref.read(selectedProjectContextProvider).asData?.value;
    final task = await taskRepository.createTask(
      prompt: prompt,
      projectContextId: context?.id,
    );
    await refresh();
    return task;
  }
}
