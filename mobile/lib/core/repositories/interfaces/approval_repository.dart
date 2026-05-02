import 'package:mobile/core/domain/models/models.dart';

abstract class ApprovalRepository {
  Future<List<ApprovalRequest>> listPending();

  Future<ApprovalRequest> approve({required String approvalId, String? note});

  Future<ApprovalRequest> reject({required String approvalId, String? note});
}
