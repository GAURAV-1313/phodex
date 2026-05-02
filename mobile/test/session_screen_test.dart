import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Session screen renders live mock session', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final waitingTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.waitingApproval,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: waitingTask.id), store: store),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-timeline')), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Phodex'), findsWidgets);
    expect(find.text('Message'), findsOneWidget);
    expect(find.byKey(const Key('sticky-approval-bar')), findsOneWidget);
  });

  testWidgets('Session screen makes queued tasks visible', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final queuedTask = store.createTask(
      prompt: 'Analyze this repository and prepare a safe execution plan.',
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: queuedTask.id), store: store),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-timeline')), findsOneWidget);
    expect(find.byKey(const Key('worker-state-card')), findsOneWidget);
    expect(find.text('Queued'), findsWidgets);
    expect(
      find.textContaining('Waiting for the laptop Codex worker'),
      findsOneWidget,
    );
    expect(find.textContaining('Analyze this repository'), findsWidgets);
  });

  testWidgets('Session screen shows completed response after work summary', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final completedTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.completed,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: completedTask.id), store: store),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mock task completed successfully.'), findsOneWidget);
    expect(find.textContaining('Worked for'), findsOneWidget);
  });

  testWidgets('Session activity log expands like a dropdown', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final completedTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.completed,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: completedTask.id), store: store),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity-log-dropdown')), findsOneWidget);
    expect(find.textContaining('Prepared patch preview'), findsNothing);

    await tester.tap(find.byKey(const Key('activity-log-dropdown')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Prepared patch preview'), findsOneWidget);
  });

  testWidgets('Session composer stays enabled after completion', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final completedTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.completed,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: completedTask.id), store: store),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('session-reply-field')),
    );
    expect(field.enabled, isTrue);
  });
}
