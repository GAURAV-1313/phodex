import 'package:mobile/core/domain/models/models.dart';

abstract class AccountRepository {
  Future<AccountSummary> getAccountSummary();

  Future<UsageSummary> getUsageSummary();

  Future<LimitStatus> getLimitStatus();

  Future<List<SessionInfo>> listSessions();

  Future<void> revokeSession(String sessionId);

  /// Revokes every session except the current one; returns how many were
  /// revoked.
  Future<int> revokeOtherSessions();
}
