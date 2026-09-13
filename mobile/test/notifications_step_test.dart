import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/features/welcome/presentation/notifications_step_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Not now completes onboarding and lands on Home', (tester) async {
    final container = await pumpPhodexApp(
      tester,
      signedIn: true,
      repoStepDone: true,
    );
    expect(find.byType(NotificationsStepScreen), findsOneWidget);
    expect(find.text("Know when you're needed"), findsOneWidget);

    await tester.tap(find.byKey(const Key('notifications-step-skip')));
    await settle(tester);

    final onboarding = container.read(onboardingControllerProvider);
    expect(onboarding.notificationsPrompted, isTrue);
    expect(onboarding.isComplete, isTrue);
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('Enable notifications without Firebase still completes '
      'onboarding', (tester) async {
    // firebaseAvailableProvider is never overridden here, so it resolves to
    // its real default (false): the prompt is skipped, the step still ends.
    final container = await pumpPhodexApp(
      tester,
      signedIn: true,
      repoStepDone: true,
    );

    await tester.tap(find.byKey(const Key('notifications-step-enable')));
    await settle(tester);

    expect(container.read(onboardingControllerProvider).isComplete, isTrue);
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });
}
