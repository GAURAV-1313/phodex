import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';
import 'package:mobile/features/welcome/presentation/first_repo_screen.dart';
import 'package:mobile/features/welcome/presentation/notifications_step_screen.dart';
import 'package:mobile/features/welcome/presentation/runtime_choice_screen.dart';
import 'package:mobile/features/welcome/presentation/sign_in_screen.dart';
import 'package:mobile/features/welcome/presentation/welcome_screen.dart';
import 'package:mobile/main.dart' as app;

/// Run with `--dart-define=PHODEX_USE_NETWORK=false` so sign-in and the
/// backend are the in-app mocks — no Google account or server required.
///
/// `pumpAndSettle` never settles here because the mascot animates
/// continuously by design; pump bounded real time instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

bool _present(Finder finder) => finder.evaluate().isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A user is onboarded, then starts a task from Home', (
    tester,
  ) async {
    app.main();
    await settle(tester);
    await settle(tester);

    // Onboarding progress persists on the device between runs, so each
    // step is taken only if the router actually stopped there.
    if (_present(find.byType(WelcomeScreen))) {
      await tester.tap(find.text('Get started'));
      await settle(tester);
    }
    if (_present(find.byType(RuntimeChoiceScreen))) {
      await tester.tap(find.byKey(const Key('runtime-option-cloud')));
      await settle(tester);
    }
    if (_present(find.byType(SignInScreen))) {
      await tester.tap(find.text('Continue with Google'));
      await settle(tester);
    }
    if (_present(find.byType(FirstRepoScreen))) {
      await tester.ensureVisible(find.byKey(const Key('first-repo-skip')));
      await tester.tap(find.byKey(const Key('first-repo-skip')));
      await settle(tester);
    }
    if (_present(find.byType(NotificationsStepScreen))) {
      await tester.tap(find.text('Not now'));
      await settle(tester);
    }

    expect(find.byKey(const Key('home-screen')), findsOneWidget);

    final composerField = find.byKey(const Key('composer-field'));
    await tester.ensureVisible(composerField);
    await tester.enterText(composerField, 'Create a task');
    await settle(tester);
    await tester.tap(find.byKey(const Key('composer-send')));
    await settle(tester);

    expect(find.byType(SessionScreen), findsOneWidget);
  });
}
