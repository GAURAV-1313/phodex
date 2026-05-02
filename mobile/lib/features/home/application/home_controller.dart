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
