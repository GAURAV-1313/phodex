import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock.dart';
import 'package:mobile/core/repositories/network/network.dart';
import 'package:mobile/core/session/session_event_parser.dart';

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return const ApiConfig(
    useNetwork: bool.fromEnvironment('PHODEX_USE_NETWORK'),
    baseUrl: String.fromEnvironment(
      'PHODEX_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
    googleIdToken: String.fromEnvironment(
      'PHODEX_GOOGLE_ID_TOKEN',
      defaultValue: 'test-token|local-user|gaurav@example.com|Gaurav Local',
    ),
  );
});

final apiClientProvider = Provider<PhodexApiClient>((ref) {
  return PhodexApiClient(ref.watch(apiConfigProvider));
});

final sessionEventParserProvider = Provider<SessionEventParser>((ref) {
  return const JsonSessionEventParser();
});

final mockBackendStoreProvider = Provider<MockBackendStore>((ref) {
  return MockBackendStore();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkAuthRepository(ref.watch(apiClientProvider));
  }
  return MockAuthRepository(ref.watch(mockBackendStoreProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkTaskRepository(ref.watch(apiClientProvider));
  }
  return MockTaskRepository(ref.watch(mockBackendStoreProvider));
});

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkApprovalRepository(ref.watch(apiClientProvider));
  }
  return MockApprovalRepository(ref.watch(mockBackendStoreProvider));
});

final repoRepositoryProvider = Provider<RepoRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkRepoRepository(ref.watch(apiClientProvider));
  }
  return MockRepoRepository(ref.watch(mockBackendStoreProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkAccountRepository(ref.watch(apiClientProvider));
  }
  return MockAccountRepository(ref.watch(mockBackendStoreProvider));
});

final sessionStreamRepositoryProvider = Provider<SessionStreamRepository>((
  ref,
) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkSessionStreamRepository(
      ref.watch(apiClientProvider),
      ref.watch(sessionEventParserProvider),
    );
  }
  return MockSessionStreamRepository(ref.watch(mockBackendStoreProvider));
});
