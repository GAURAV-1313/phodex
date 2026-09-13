import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/welcome/presentation/runtime_choice_screen.dart';
import 'package:mobile/features/welcome/presentation/welcome_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Welcome pitches the product and offers one way forward', (
    tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(const WelcomeScreen()));
    await settle(tester);

    expect(find.text('Your AI engineer,\nin your pocket.'), findsOneWidget);
    expect(find.text('Start tasks from your phone'), findsOneWidget);
    expect(find.text('Watch live execution as it happens'), findsOneWidget);
    expect(find.text('Approve every change before it lands'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    // Sign-in and pairing each get their own step now — nothing here
    // should claim to be connecting to anything.
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.textContaining('Connecting'), findsNothing);
    expect(find.textContaining('Connect to your desktop'), findsNothing);
  });

  testWidgets('Get started leads to the runtime choice', (tester) async {
    await pumpPhodexApp(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome-get-started')));
    await settle(tester);

    expect(find.byType(RuntimeChoiceScreen), findsOneWidget);
    expect(find.text('Choose a runtime'), findsOneWidget);
  });
}
