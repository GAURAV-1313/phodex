import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

import 'test_helpers.dart';

/// PhodexMascot animates continuously by design, so pumpAndSettle() never
/// settles on this screen — pump a bounded, fixed amount instead (comfortably
/// covers the mock repositories' simulated network latency, well under
/// 200ms per call with dynamic simulation off).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// This screen's content routinely runs past the Viewport's default 250px
/// cacheExtent, which finders treat as "offstage" and skip by default even
/// though the widget genuinely exists and rendered correctly — this is a
/// content-presence check, not a "can a user see this without scrolling"
/// check, so skipOffstage: false is the correct match here, not a workaround.
Finder textAnywhere(String text) => find.text(text, skipOffstage: false);

void main() {
  testWidgets('Pending approval shows the approval block with actions', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final waitingTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.waitingApproval,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: waitingTask.id), store: store),
    );
    await settle(tester);

    expect(textAnywhere('HUMAN VERIFICATION NEEDED'), findsOneWidget);
    expect(textAnywhere('Approve file operation'), findsOneWidget);
    expect(textAnywhere('Approve'), findsOneWidget);
    expect(textAnywhere('Reject'), findsOneWidget);
  });

  testWidgets('A freshly queued task shows live execution chrome', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final queuedTask = store.createTask(
      prompt: 'Analyze this repository and prepare a safe execution plan.',
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: queuedTask.id), store: store),
    );
    await settle(tester);

    expect(find.text('EXECUTION LIVE'), findsOneWidget);
    expect(
      find.textContaining('Analyze this repository', skipOffstage: false),
      findsWidgets,
    );
    expect(textAnywhere('Message your agent'), findsOneWidget);
    expect(textAnywhere('Cancel task'), findsOneWidget);
    // Nothing is pending yet, so no approval block should render.
    expect(textAnywhere('HUMAN VERIFICATION NEEDED'), findsNothing);

    // Flushes a trailing zero-duration timer from task creation that would
    // otherwise still be pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets(
    'A completed task shows its summary and Done, with no reply composer',
    (tester) async {
      final store = MockBackendStore(enableDynamicSimulation: false);
      final completedTask = store.listTasks().firstWhere(
        (task) => task.status == TaskStatus.completed,
      );

      await tester.pumpWidget(
        wrapWithTestApp(SessionScreen(taskId: completedTask.id), store: store),
      );
      await settle(tester);

      expect(textAnywhere('Mock task completed successfully.'), findsOneWidget);
      expect(textAnywhere('Done'), findsOneWidget);
      expect(textAnywhere('Commit & Push'), findsOneWidget);
      // The reply composer only exists for non-terminal tasks — a completed
      // task replaces it with Done/Commit & Push, it doesn't just disable it.
      expect(textAnywhere('Message your agent'), findsNothing);
    },
  );

  testWidgets(
    'Commit & Push moves git.log lines into the logs sheet, not the main timeline',
    (tester) async {
      final store = MockBackendStore(enableDynamicSimulation: false);
      final completedTask = store.listTasks().firstWhere(
        (task) => task.status == TaskStatus.completed,
      );

      await tester.pumpWidget(
        wrapWithTestApp(SessionScreen(taskId: completedTask.id), store: store),
      );
      await settle(tester);

      final commitPushButton = textAnywhere('Commit & Push');
      await tester.ensureVisible(commitPushButton);
      await settle(tester);
      await tester.tap(commitPushButton);
      await settle(tester);

      expect(textAnywhere('Commit & push to GitHub'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Commit & push', skipOffstage: false),
      );
      await settle(tester);
      await settle(tester);

      expect(textAnywhere('Pushed to GitHub'), findsOneWidget);

      await tester.tap(find.widgetWithText(StitchPrimaryButton, 'Close'));
      await settle(tester);
      await settle(tester);

      // Raw git command output must not flood the milestone timeline...
      expect(
        find.textContaining('Enumerating objects', skipOffstage: false),
        findsNothing,
      );

      // ...but must be reachable from the same terminal logs sheet used for
      // agent output, since that's the one place meant to hold it. The
      // header (with the terminal icon) is now scrolled far enough above
      // the viewport that the ListView's Sliver never built it — a plain
      // ensureVisible can't scroll to an element that doesn't exist yet, so
      // drag back toward the top first.
      await tester.drag(find.byType(ListView).first, const Offset(0, 600));
      await settle(tester);

      final terminalIcon = find
          .byIcon(Icons.terminal_rounded, skipOffstage: false)
          .first;
      await tester.ensureVisible(terminalIcon);
      await settle(tester);
      await tester.tap(terminalIcon);
      await settle(tester);

      expect(textAnywhere('Execution logs'), findsOneWidget);
      expect(
        find.textContaining('Enumerating objects', skipOffstage: false),
        findsWidgets,
      );
    },
  );

  testWidgets('A completed session offers a real follow-up task entry point', (
    tester,
  ) async {
    // The completed view's "Start a follow-up task" button opens a sheet
    // that calls SessionController.continueWithNewTask and then navigates
    // via go_router — this test verifies the button and sheet are real
    // (not a dead affordance), stopping short of the submit+navigate step
    // since this harness has no GoRouter ancestor (same boundary already
    // used for the AI engine / Privacy & security rows in
    // account_screen_test.dart).
    final store = MockBackendStore(enableDynamicSimulation: false);
    final completedTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.completed,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: completedTask.id), store: store),
    );
    await settle(tester);

    final followUpButton = textAnywhere('Start a follow-up task');
    await tester.ensureVisible(followUpButton);
    await settle(tester);
    await tester.tap(followUpButton);
    await settle(tester);

    expect(textAnywhere('Describe what you need built next…'), findsOneWidget);
    expect(
      find.widgetWithText(StitchPrimaryButton, 'Start task'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Terminal logs modal reveals log detail not shown in the main timeline',
    (tester) async {
      final store = MockBackendStore(enableDynamicSimulation: false);
      final waitingTask = store.listTasks().firstWhere(
        (task) => task.status == TaskStatus.waitingApproval,
      );

      await tester.pumpWidget(
        wrapWithTestApp(SessionScreen(taskId: waitingTask.id), store: store),
      );
      await settle(tester);

      // `task.log` events (command output, patch previews) are deliberately
      // filtered out of the main timeline — only visible via the logs modal.
      expect(
        find.textContaining('Prepared patch preview', skipOffstage: false),
        findsNothing,
      );

      await tester.tap(find.byIcon(Icons.terminal_rounded).first);
      await settle(tester);

      expect(textAnywhere('Execution logs'), findsOneWidget);
      expect(
        find.textContaining('Prepared patch preview', skipOffstage: false),
        findsWidgets,
      );
    },
  );

  testWidgets('Approving the pending request shows a resolving state', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final waitingTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.waitingApproval,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: waitingTask.id), store: store),
    );
    await settle(tester);

    final approveButton = find.widgetWithText(
      FilledButton,
      'Approve',
      skipOffstage: false,
    );
    await tester.ensureVisible(approveButton);
    await settle(tester);
    await tester.tap(approveButton);
    await tester.pump();

    expect(textAnywhere('Resolving…'), findsOneWidget);

    // Approving triggers a chain of further async work (resolve, then a
    // full session refresh) — flush it so no timer is still pending when
    // the test tears down.
    await settle(tester);
    await settle(tester);
  });
}
