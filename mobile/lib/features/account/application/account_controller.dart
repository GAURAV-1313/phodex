import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';

class AccountDashboard {
  const AccountDashboard({
    required this.summary,
    required this.usage,
    required this.limits,
  });

  final AccountSummary summary;
  final UsageSummary usage;
  final LimitStatus limits;
}

final accountDashboardProvider =
    AsyncNotifierProvider<AccountDashboardController, AccountDashboard>(
      AccountDashboardController.new,
    );

class AccountDashboardController extends AsyncNotifier<AccountDashboard> {
  @override
  Future<AccountDashboard> build() async {
    final accountRepository = ref.watch(accountRepositoryProvider);
    final summary = await accountRepository.getAccountSummary();
    final usage = await accountRepository.getUsageSummary();
    final limits = await accountRepository.getLimitStatus();

    return AccountDashboard(summary: summary, usage: usage, limits: limits);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
