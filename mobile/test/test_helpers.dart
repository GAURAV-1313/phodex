import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testApiConfig = ApiConfig(
  useNetwork: false,
  baseUrl: 'http://test',
  googleIdToken: 'test',
  cloudBaseUrl: 'https://cloud.test',
);

/// `pumpAndSettle()` waits for animation frames to stop being scheduled —
/// but `PhodexMascot` animates continuously by design, so it never
/// "settles" and `pumpAndSettle()` would hang until its timeout. This pumps
/// a bounded, fixed amount of time instead: enough to cover page-transition
/// animations and the mock repositories' simulated network latency (well
/// under 200ms per call with dynamic simulation off). It is split into
/// several frames because one async hop often only starts the next (runtime
/// info → repo list → staggered cards), and each hop needs its own frame.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

List<Override> _testOverrides(MockBackendStore store) => [
  apiConfigProvider.overrideWithValue(testApiConfig),
  mockBackendStoreProvider.overrideWithValue(store),
];

/// A single screen under a plain [MaterialApp] (no router): for screens
/// that don't navigate on their own. [runtimeMode] flips the mock backend
/// between desktop and Phodex Cloud.
Widget wrapWithTestApp(
  Widget child, {
  MockBackendStore? store,
  RuntimeMode? runtimeMode,
  List<Override> overrides = const [],
}) {
  final effectiveStore =
      store ?? MockBackendStore(enableDynamicSimulation: false);
  if (runtimeMode != null) effectiveStore.runtimeMode = runtimeMode;
  return ProviderScope(
    overrides: [..._testOverrides(effectiveStore), ...overrides],
    child: MaterialApp(theme: AppTheme.dark(), home: child),
  );
}

/// The whole app, router and guards included, in mock mode. Returns the
/// container so tests can drive providers (sign in, read the router) the
/// way the real app would. Onboarding flags are seeded into the mocked
/// SharedPreferences before anything reads them.
Future<ProviderContainer> pumpPhodexApp(
  WidgetTester tester, {
  MockBackendStore? store,
  RuntimeMode? runtimeMode,
  bool signedIn = false,
  bool onboardingComplete = false,
  bool repoStepDone = false,
  bool notificationsPrompted = false,
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    if (onboardingComplete) onboardingVersionPrefsKey: onboardingVersion,
    if (onboardingComplete || repoStepDone) onboardingRepoStepPrefsKey: true,
    if (onboardingComplete || notificationsPrompted)
      onboardingNotificationsPrefsKey: true,
    ...prefs,
  });
  final effectiveStore =
      store ?? MockBackendStore(enableDynamicSimulation: false);
  if (runtimeMode != null) effectiveStore.runtimeMode = runtimeMode;

  final container = ProviderContainer(
    overrides: [..._testOverrides(effectiveStore), ...overrides],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PhodexApp()),
  );
  await settle(tester);

  if (signedIn) {
    await container.read(authControllerProvider.notifier).signIn();
    await settle(tester);
  }
  return container;
}
