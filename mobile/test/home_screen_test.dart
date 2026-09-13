import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

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

    expect(find.byKey(const Key('home-screen')), findsOneWidget);
    expect(find.textContaining('AI engineer'), findsOneWidget);
    // The seeded project context is already selected, so the context pill
    // shows the bare repo name plus branch rather than the placeholder.
    expect(find.text('phodex · feature/mobile-v1'), findsOneWidget);
    expect(find.text('Pick a repository'), findsNothing);
    expect(
      find.text('Choose a repository before starting a task'),
      findsNothing,
    );

    expect(find.text('SUGGESTED FLOWS'), findsOneWidget);
    expect(find.text('Fix Bug'), findsOneWidget);
    expect(find.text('Review Code'), findsOneWidget);
    expect(find.text('Plan Feature'), findsOneWidget);

    expect(find.text('Describe what you need built…'), findsOneWidget);
    expect(find.byKey(const Key('composer-send')), findsOneWidget);
    // Nothing is wrong, so no runtime banner.
    expect(find.textContaining('Reconnecting'), findsNothing);
    expect(find.textContaining('is offline'), findsNothing);
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
    // Recent tasks render with status chips.
    expect(find.text('RECENT TASKS'), findsOneWidget);
    expect(find.byType(TaskStatusChip), findsWidgets);
  });

  testWidgets('Composer accepts typed input', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(wrapWithTestApp(const HomeScreen(), store: store));
    await settle(tester);

    await tester.enterText(
      find.byKey(const Key('composer-field')),
      'Add dark mode support',
    );
    await tester.pump();

    expect(find.text('Add dark mode support'), findsOneWidget);
  });

  testWidgets('Bell shows a badge while an approval is pending', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(wrapWithTestApp(const HomeScreen(), store: store));
    await settle(tester);

    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
  });

  testWidgets(
    'Without a repository the composer is locked and a banner points to Repos',
    (tester) async {
      final store = MockBackendStore(enableDynamicSimulation: false)
        ..clearRepositories();

      await tester.pumpWidget(
        wrapWithTestApp(const HomeScreen(), store: store),
      );
      await settle(tester);

      expect(
        find.text('Choose a repository before starting a task'),
        findsOneWidget,
      );
      // The banner's action (the dock has its own "Repos" tab label).
      expect(find.widgetWithText(TextButton, 'Repos'), findsOneWidget);
      expect(find.text('Pick a repository'), findsOneWidget);

      final field = tester.widget<TextField>(
        find.byKey(const Key('composer-field')),
      );
      expect(field.enabled, isFalse);

      final chip = tester.widget<ActionChip>(
        find.widgetWithText(ActionChip, 'Fix Bug'),
      );
      expect(chip.onPressed, isNull);
    },
  );

  testWidgets('Empty task list offers an example that fills the composer', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false)
      ..clearTasks();

    await tester.pumpWidget(wrapWithTestApp(const HomeScreen(), store: store));
    await settle(tester);

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('CURRENT TASK'), findsNothing);

    final example = find.text('Try an example');
    await tester.ensureVisible(example);
    await settle(tester);
    await tester.tap(example);
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('composer-field')),
    );
    expect(field.controller?.text, homeSuggestions.first.prompt);
  });
}
