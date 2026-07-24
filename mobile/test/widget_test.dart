import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';

void main() {
  ProviderScope buildTestApp() => ProviderScope(
    overrides: [
      apiConfigProvider.overrideWithValue(
        const ApiConfig(
          useNetwork: false,
          baseUrl: 'http://test',
          googleIdToken: 'test',
        ),
      ),
      mockBackendStoreProvider.overrideWithValue(
        MockBackendStore(enableDynamicSimulation: false),
      ),
    ],
    child: const PhodexApp(),
  );

  testWidgets('App starts with the Stitch welcome screen', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Your AI engineer,\nin your pocket.'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('Home creates a task and opens its live session', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Create a task');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded).last);
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);
  });
}
