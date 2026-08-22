import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock.dart';
import 'package:mobile/core/repositories/network/network.dart';
import 'package:mobile/core/session/session_event_parser.dart';

/// Overridden in `main.dart` (before the widget tree even builds) with a
/// server address the user previously paired with, so `apiConfigProvider`
/// resolves to the right backend from the very first read — no async
/// restore race against the first network call.
final persistedServerUrlOverrideProvider = Provider<String?>((ref) => null);

/// Overridden in `main.dart` with whether Firebase actually initialized
/// (false until a real project is wired up via `flutterfire configure`) —
/// the Notifications screen and push controller both read this to know
/// whether attempting any FCM call makes sense at all.
final firebaseAvailableProvider = Provider<bool>((ref) => false);

// bool.fromEnvironment/String.fromEnvironment are compile-time-only const
// constructors — calling them outside a `const` expression throws at
// runtime ("can only be used as a const constructor"), so each is pulled
// out as its own top-level const here rather than inlined in the
// necessarily-non-const ApiConfig(...) call below (it depends on the
// runtime-read persistedServerUrlOverrideProvider).
const _useNetworkFromEnv = bool.fromEnvironment(
  'PHODEX_USE_NETWORK',
  defaultValue: true,
);
const _baseUrlFromEnv = String.fromEnvironment(
  'PHODEX_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
const _googleIdTokenFromEnv = String.fromEnvironment('PHODEX_GOOGLE_ID_TOKEN');
const _googleServerClientIdFromEnv = String.fromEnvironment(
  'PHODEX_GOOGLE_SERVER_CLIENT_ID',
);
const _googleIosClientIdFromEnv = String.fromEnvironment(
  'PHODEX_GOOGLE_IOS_CLIENT_ID',
);

final apiConfigProvider = Provider<ApiConfig>((ref) {
  final persisted = ref.watch(persistedServerUrlOverrideProvider);
  return ApiConfig(
    useNetwork: _useNetworkFromEnv,
    baseUrl: persisted ?? _baseUrlFromEnv,
    googleIdToken: _googleIdTokenFromEnv,
    googleServerClientId: _googleServerClientIdFromEnv,
    googleIosClientId: _googleIosClientIdFromEnv,
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

final gitOpsRepositoryProvider = Provider<GitOpsRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkGitOpsRepository(ref.watch(apiClientProvider));
  }
  return MockGitOpsRepository(ref.watch(mockBackendStoreProvider));
});

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkAiSettingsRepository(ref.watch(apiClientProvider));
  }
  return MockAiSettingsRepository(ref.watch(mockBackendStoreProvider));
});

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  if (ref.watch(apiConfigProvider).useNetwork) {
    return NetworkPushRepository(ref.watch(apiClientProvider));
  }
  return const MockPushRepository();
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
