import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';

/// `pumpAndSettle()` waits for animation frames to stop being scheduled —
/// but `PhodexMascot` (visible on Home and Session) animates continuously
/// by design, so it never "settles" and `pumpAndSettle()` would hang until
/// its timeout. This pumps a bounded, fixed amount of time instead: enough
/// to cover page-transition animations and the mock repositories' simulated
/// network latency (well under 200ms per call with dynamic simulation off),
/// without waiting on an animation that runs forever on purpose.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

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
    await settle(tester);
    expect(find.text('Your AI engineer,\nin your pocket.'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('Home creates a task and opens its live session', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await settle(tester);
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);

    final composerField = find.byType(TextField).last;
    await tester.ensureVisible(composerField);
    await settle(tester);
    await tester.enterText(composerField, 'Create a task');

    final sendButton = find.byIcon(Icons.arrow_upward_rounded).last;
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
