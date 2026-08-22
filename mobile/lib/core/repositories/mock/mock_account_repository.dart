import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockAccountRepository implements AccountRepository {
  const MockAccountRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<AccountSummary> getAccountSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _store.getAccountSummary();
  }

  @override
  Future<LimitStatus> getLimitStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _store.getLimitStatus();
  }

  @override
  Future<UsageSummary> getUsageSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _store.getUsageSummary();
  }

  @override
  Future<List<SessionInfo>> listSessions() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _store.listSessions();
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _store.revokeSession(sessionId);
  }

  @override
  Future<int> revokeOtherSessions() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _store.revokeOtherSessions();
  }
}
