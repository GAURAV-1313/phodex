import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';

import 'test_helpers.dart';

/// PhodexMascot animates continuously by design, so pumpAndSettle() never
/// settles here — pump a bounded, fixed amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Shows the composer prompt, repository, and suggested flows', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(wrapWithTestApp(const HomeScreen(), store: store));
    await settle(tester);

    expect(find.textContaining('AI engineer'), findsOneWidget);
    // The seeded project context is already selected, so the repo bar shows
    // its real name rather than the "Select repository" placeholder.
    expect(find.text('phodex (feature/mobile-v1)'), findsOneWidget);
    expect(find.text('Select repository'), findsNothing);

    expect(find.text('SUGGESTED FLOWS'), findsOneWidget);
    expect(find.text('Fix Bug'), findsOneWidget);
    expect(find.text('Review Code'), findsOneWidget);
    expect(find.text('Plan Feature'), findsOneWidget);

    expect(find.text('Describe what you need built…'), findsOneWidget);
  });

  testWidgets('Shows the current active task card for a non-terminal task', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(wrapWithTestApp(const HomeScreen(), store: store));
    await settle(tester);

    expect(find.text('CURRENT TASK'), findsOneWidget);
    // The active task is whichever non-terminal task was updated most
    // recently — the last-created seeded task, not necessarily the first
    // non-terminal one in creation order.
    expect(find.textContaining('Refactor account screen cards'), findsWidgets);
  });

  testWidgets('Composer accepts typed input', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(wrapWithTestApp(const HomeScreen(), store: store));
    await settle(tester);

    await tester.enterText(
      find.byType(TextField).last,
      'Add dark mode support',
    );
    await tester.pump();

    expect(find.text('Add dark mode support'), findsOneWidget);
  });
}
