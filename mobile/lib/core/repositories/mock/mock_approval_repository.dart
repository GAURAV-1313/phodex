import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockApprovalRepository implements ApprovalRepository {
  const MockApprovalRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<ApprovalRequest> approve({
    required String approvalId,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return _store.approve(approvalId, note: note);
  }

  @override
  Future<List<ApprovalRequest>> listPending() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.listPendingApprovals();
  }

  @override
  Future<ApprovalRequest> reject({
    required String approvalId,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return _store.reject(approvalId, note: note);
  }
}
