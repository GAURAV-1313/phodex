import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/home/presentation/recents_screen.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

import 'test_helpers.dart';

/// PhodexMascot animates continuously by design, so pumpAndSettle() never
/// settles here — pump a bounded, fixed amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Finder textAnywhere(String text) => find.text(text, skipOffstage: false);

void main() {
  testWidgets('Lists every task with its status chip', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const RecentsScreen(), store: store),
    );
    await settle(tester);

    expect(find.text('Activity'), findsOneWidget);
    expect(find.byType(TaskStatusChip, skipOffstage: false), findsNWidgets(3));
    expect(textAnywhere('Completed'), findsWidgets);
    expect(textAnywhere('Needs approval'), findsOneWidget);
    expect(textAnywhere('Queued'), findsOneWidget);
    expect(textAnywhere('3 TASKS'), findsOneWidget);
  });

  testWidgets('Search narrows the list and can be cleared', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const RecentsScreen(), store: store),
    );
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'CI failure');
    await settle(tester);

    expect(
      find.textContaining('Investigate CI failure', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Refactor account screen', skipOffstage: false),
      findsNothing,
    );
    expect(textAnywhere('1 TASK'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nothing like this');
    await settle(tester);

    expect(textAnywhere('No matching tasks'), findsOneWidget);
    final clear = textAnywhere('Clear filters');
    await tester.ensureVisible(clear);
    await settle(tester);
    await tester.tap(clear);
    await settle(tester);

    expect(textAnywhere('3 TASKS'), findsOneWidget);
  });

  testWidgets('Status filter chips narrow the list', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const RecentsScreen(), store: store),
    );
    await settle(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await settle(tester);

    expect(find.byType(TaskStatusChip, skipOffstage: false), findsOneWidget);
    expect(textAnywhere('Needs approval'), findsNothing);
    expect(textAnywhere('1 TASK'), findsOneWidget);
  });

  testWidgets('Empty store shows the first-task call to action', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false)
      ..clearTasks();

    await tester.pumpWidget(
      wrapWithTestApp(const RecentsScreen(), store: store),
    );
    await settle(tester);

    expect(textAnywhere('No tasks yet'), findsOneWidget);
    expect(textAnywhere('Create your first coding task'), findsOneWidget);
    expect(find.byType(TaskStatusChip, skipOffstage: false), findsNothing);
  });
}
