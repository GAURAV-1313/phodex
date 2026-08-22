import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/account/presentation/sessions_screen.dart';

import 'test_helpers.dart';

/// PhodexMascot animates continuously by design, so pumpAndSettle() never
/// settles here — pump a bounded, fixed amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Lists the current device and other signed-in sessions', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const SessionsScreen(), store: store),
    );
    await settle(tester);

    expect(find.text('Privacy & security'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('Other device'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Signing out of another device removes it from the list', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const SessionsScreen(), store: store),
    );
    await settle(tester);

    expect(store.listSessions().length, 2);

    await tester.tap(find.text('Sign out'));
    await settle(tester);
    await settle(tester);

    expect(find.text('Other device'), findsNothing);
    expect(find.text('This device'), findsOneWidget);
  });

  testWidgets(
    'Sign out of all other devices clears every non-current session',
    (tester) async {
      final store = MockBackendStore(enableDynamicSimulation: false);

      await tester.pumpWidget(
        wrapWithTestApp(const SessionsScreen(), store: store),
      );
      await settle(tester);

      await tester.tap(find.text('Sign out of all other devices'));
      await settle(tester);
      await settle(tester);

      expect(find.text('Other device'), findsNothing);
      expect(store.listSessions(), hasLength(1));
      expect(store.listSessions().single.isCurrent, isTrue);
    },
  );
}
