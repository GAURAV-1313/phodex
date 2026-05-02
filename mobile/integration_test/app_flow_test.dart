import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App flow navigation works with chat-style menu routing', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-screen')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recents-screen')), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('home-composer-field')),
      'Create a task',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded).first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-screen')), findsOneWidget);
  });
}
