import 'package:mobile/core/domain/models/models.dart';

abstract class AccountRepository {
  Future<AccountSummary> getAccountSummary();

  Future<UsageSummary> getUsageSummary();

  Future<LimitStatus> getLimitStatus();
}
