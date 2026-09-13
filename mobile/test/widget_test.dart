import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';
import 'package:mobile/features/welcome/presentation/first_repo_screen.dart';
import 'package:mobile/features/welcome/presentation/notifications_step_screen.dart';
import 'package:mobile/features/welcome/presentation/runtime_choice_screen.dart';
import 'package:mobile/features/welcome/presentation/sign_in_screen.dart';

import 'test_helpers.dart';

/// Walks a brand-new install through the whole front door, the way a real
/// first launch does: Welcome → runtime choice → sign-in → first repo →
/// notifications → Home.
Future<void> completeOnboarding(WidgetTester tester) async {
  expect(find.text('Your AI engineer,\nin your pocket.'), findsOneWidget);
  await tester.tap(find.text('Get started'));
  await settle(tester);

  expect(find.byType(RuntimeChoiceScreen), findsOneWidget);
  await tester.tap(find.byKey(const Key('runtime-option-cloud')));
  await settle(tester);

  expect(find.byType(SignInScreen), findsOneWidget);
  await tester.tap(find.text('Continue with Google'));
  await settle(tester);

  expect(find.byType(FirstRepoScreen), findsOneWidget);
  await tester.ensureVisible(find.byKey(const Key('first-repo-skip')));
  await tester.tap(find.byKey(const Key('first-repo-skip')));
  await settle(tester);

  expect(find.byType(NotificationsStepScreen), findsOneWidget);
  await tester.tap(find.text('Not now'));
  await settle(tester);

  expect(find.byKey(const Key('home-screen')), findsOneWidget);
}

void main() {
  testWidgets('A fresh install is onboarded from Welcome through to Home', (
    tester,
  ) async {
    await pumpPhodexApp(tester);
    await completeOnboarding(tester);
  });

  testWidgets('Home creates a task and opens its live session', (tester) async {
    await pumpPhodexApp(tester);
    await completeOnboarding(tester);

    // The composer is the shared ComposerBar; fall back to the last text
    // field / send icon in case Home is mid-migration.
    final keyedField = find.byKey(const Key('composer-field'));
    final composerField = keyedField.evaluate().isNotEmpty
        ? keyedField
        : find.byType(TextField).last;
    await tester.ensureVisible(composerField);
    await settle(tester);
    await tester.enterText(composerField, 'Create a task');
    await tester.pump();

    final keyedSend = find.byKey(const Key('composer-send'));
    final sendButton = keyedSend.evaluate().isNotEmpty
        ? keyedSend
        : find.byIcon(Icons.arrow_upward_rounded).last;
    await tester.ensureVisible(sendButton);
    await settle(tester);
    await tester.tap(sendButton);
    await settle(tester);
    expect(find.byType(SessionScreen), findsOneWidget);

    // Flushes a trailing zero-duration timer (task-creation follow-up work)
    // that would otherwise still be pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 50));
  });
}
