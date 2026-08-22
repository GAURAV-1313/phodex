import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkAccountRepository implements AccountRepository {
  const NetworkAccountRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<AccountSummary> getAccountSummary() async {
    final json = await _apiClient.getJson('/account/me');
    return AccountSummaryResponseDto.fromJson(json).toDomain();
  }

  @override
  Future<LimitStatus> getLimitStatus() async {
    final json = await _apiClient.getJson('/account/limits');
    return LimitStatusResponseDto.fromJson(json).toDomain();
  }

  @override
  Future<UsageSummary> getUsageSummary() async {
    final json = await _apiClient.getJson('/account/usage');
    return UsageSummaryResponseDto.fromJson(json).toDomain();
  }

  @override
  Future<List<SessionInfo>> listSessions() async {
    final json = await _apiClient.getJson('/account/sessions');
    return SessionsResponseDto.fromJson(json).toDomain();
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _apiClient.postJson('/account/sessions/$sessionId/revoke');
  }

  @override
  Future<int> revokeOtherSessions() async {
    final json = await _apiClient.postJson('/account/sessions/revoke-others');
    return json['revoked_count'] as int;
  }
}
