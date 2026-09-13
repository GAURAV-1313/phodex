import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/features/welcome/presentation/first_repo_screen.dart';
import 'package:mobile/features/welcome/presentation/notifications_step_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Cloud runtime: connecting a GitHub repo selects it and '
      'continues', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final container = await pumpPhodexApp(
      tester,
      store: store,
      runtimeMode: RuntimeMode.cloud,
      signedIn: true,
    );
    expect(find.byType(FirstRepoScreen), findsOneWidget);
    expect(find.text('Your first repo'), findsOneWidget);
    expect(find.text('GitHub repository URL'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('first-repo-url')),
      'https://github.com/acme/widgets',
    );
    await tester.enterText(
      find.byKey(const Key('first-repo-token')),
      'github_pat_secret',
    );
    await tester.tap(find.byKey(const Key('first-repo-connect')));
    await settle(tester);

    expect(store.getSelectedProjectContext()?.name, 'widgets (main)');
    expect(store.hasGithubToken, isTrue);
    expect(container.read(onboardingControllerProvider).repoStepDone, isTrue);
    expect(find.byType(NotificationsStepScreen), findsOneWidget);
  });

  testWidgets('Cloud runtime: a non-GitHub URL is rejected before any call', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    await pumpPhodexApp(
      tester,
      store: store,
      runtimeMode: RuntimeMode.cloud,
      signedIn: true,
    );

    await tester.enterText(
      find.byKey(const Key('first-repo-url')),
      'not a url',
    );
    await tester.tap(find.byKey(const Key('first-repo-connect')));
    await settle(tester);

    expect(
      find.textContaining('Enter a GitHub repository URL'),
      findsOneWidget,
    );
    expect(find.byType(FirstRepoScreen), findsOneWidget);
    expect(store.listRepositories().where((r) => r.isCloud), isEmpty);
  });

  testWidgets('Desktop runtime: tapping a synced repo selects it and '
      'continues', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final container = await pumpPhodexApp(tester, store: store, signedIn: true);
    expect(find.byType(FirstRepoScreen), findsOneWidget);
    expect(find.text('AFTR-backend'), findsOneWidget);
    expect(find.text('phodex'), findsOneWidget);

    await tester.tap(find.text('AFTR-backend'));
    await settle(tester);

    expect(store.getSelectedProjectContext()?.syncedRepositoryId, 'repo_001');
    expect(container.read(onboardingControllerProvider).repoStepDone, isTrue);
    expect(find.byType(NotificationsStepScreen), findsOneWidget);
  });

  testWidgets('Skip for now marks the step done without selecting', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final before = store.getSelectedProjectContext()?.id;
    final container = await pumpPhodexApp(tester, store: store, signedIn: true);

    await tester.ensureVisible(find.byKey(const Key('first-repo-skip')));
    await tester.tap(find.byKey(const Key('first-repo-skip')));
    await settle(tester);

    expect(store.getSelectedProjectContext()?.id, before);
    expect(container.read(onboardingControllerProvider).repoStepDone, isTrue);
    expect(find.byType(NotificationsStepScreen), findsOneWidget);
  });
}
