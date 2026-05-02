import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/home/application/home_controller.dart';

final approvalsProvider =
    AsyncNotifierProvider<ApprovalsController, List<ApprovalRequest>>(
      ApprovalsController.new,
    );

class ApprovalsController extends AsyncNotifier<List<ApprovalRequest>> {
  @override
  Future<List<ApprovalRequest>> build() async {
    final approvalRepository = ref.watch(approvalRepositoryProvider);
    return approvalRepository.listPending();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final approvalRepository = ref.read(approvalRepositoryProvider);
      return approvalRepository.listPending();
    });
  }

  Future<void> approve({required String approvalId, String? note}) async {
    final approvalRepository = ref.read(approvalRepositoryProvider);
    await approvalRepository.approve(approvalId: approvalId, note: note);
    await refresh();
    await ref.read(homeTasksProvider.notifier).refresh();
  }

  Future<void> reject({required String approvalId, String? note}) async {
    final approvalRepository = ref.read(approvalRepositoryProvider);
    await approvalRepository.reject(approvalId: approvalId, note: note);
    await refresh();
    await ref.read(homeTasksProvider.notifier).refresh();
  }
}
