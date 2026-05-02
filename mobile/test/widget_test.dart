import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App boots to home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockBackendStoreProvider.overrideWithValue(
            MockBackendStore(enableDynamicSimulation: false),
          ),
        ],
        child: const PhodexApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets(
    'Template navigation and live task creation move between screens',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockBackendStoreProvider.overrideWithValue(
              MockBackendStore(enableDynamicSimulation: false),
            ),
          ],
          child: const PhodexApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded).first);
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
    },
  );
}
