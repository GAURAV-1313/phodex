import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkApprovalRepository implements ApprovalRepository {
  const NetworkApprovalRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<ApprovalRequest> approve({
    required String approvalId,
    String? note,
  }) async {
    final json = await _apiClient.postJson(
      '/approvals/$approvalId/approve',
      body: {'note': note},
    );
    return ApprovalRequestOutDto.fromJson(json).toDomain();
  }

  @override
  Future<List<ApprovalRequest>> listPending() async {
    final json = await _apiClient.getJson('/approvals/pending');
    return PendingApprovalsResponseDto.fromJson(
      json,
    ).items.map((item) => item.toDomain()).toList();
  }

  @override
  Future<ApprovalRequest> reject({
    required String approvalId,
    String? note,
  }) async {
    final json = await _apiClient.postJson(
      '/approvals/$approvalId/reject',
      body: {'note': note},
    );
    return ApprovalRequestOutDto.fromJson(json).toDomain();
  }
}
