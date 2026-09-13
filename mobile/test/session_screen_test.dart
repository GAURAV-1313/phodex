import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';
import 'package:mobile/shared/widgets/trace_card.dart';

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

/// A live-event stream that closes immediately — what a dropped SSE
/// connection looks like to the session controller.
class _DroppingStreamRepository implements SessionStreamRepository {
  const _DroppingStreamRepository();

  @override
  Stream<TaskEventEnvelope> subscribe({
    required String taskId,
    int afterSequence = 0,
  }) => const Stream<TaskEventEnvelope>.empty();
}

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
    // Once as the approval block's title, once as the trace card headline
    // for the approval.requested step.
    expect(textAnywhere('Approve file operation'), findsNWidgets(2));
    expect(textAnywhere('Approve'), findsOneWidget);
    expect(textAnywhere('Reject'), findsOneWidget);
    // Status row: chip + the task's project context.
    expect(textAnywhere('Needs approval'), findsOneWidget);
    expect(textAnywhere('phodex · feature/mobile-v1'), findsOneWidget);
    // Waiting on the user, not executing: the composer offers send, not stop.
    expect(find.byKey(const Key('composer-send')), findsOneWidget);
    expect(find.byKey(const Key('composer-stop')), findsNothing);
  });

  testWidgets('Timeline renders trace cards with semantics labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final store = MockBackendStore(enableDynamicSimulation: false);
    final waitingTask = store.listTasks().firstWhere(
      (task) => task.status == TaskStatus.waitingApproval,
    );

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: waitingTask.id), store: store),
    );
    await settle(tester);
    // StaggerIn fades cards in; a fully transparent subtree is excluded from
    // the semantics tree, so give the entrance animation a chance to tick.
    await settle(tester);

    expect(find.byType(TraceCard, skipOffstage: false), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp(r'^Trace: '), skipOffstage: false),
      findsWidgets,
    );
    // Log lines never land in the trace; milestone events do, each with a
    // "<type> · <time>" line under the headline.
    expect(
      find.textContaining('Task created and queued', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Approval requested · ', skipOffstage: false),
      findsOneWidget,
    );

    // The approval.requested event carries a description, so its card
    // expands to reveal it. (The approval block shows the same title but
    // has no TraceCard ancestor, so this resolves to the card alone.)
    final approvalCard = find.ancestor(
      of: textAnywhere('Approve file operation'),
      matching: find.byType(TraceCard, skipOffstage: false),
    );
    expect(approvalCard, findsOneWidget);
    expect(
      find.descendant(
        of: approvalCard,
        matching: find.textContaining('Worker wants to apply changes'),
      ),
      findsNothing,
    );
    await tester.ensureVisible(approvalCard);
    await settle(tester);
    await tester.tap(approvalCard);
    await settle(tester);
    expect(
      find.descendant(
        of: approvalCard,
        matching: find.textContaining(
          'Worker wants to apply changes',
          skipOffstage: false,
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
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

    final chip = tester.widget<TaskStatusChip>(
      find.byType(TaskStatusChip, skipOffstage: false),
    );
    expect(chip.status, 'queued');
    expect(chip.pulse, isTrue);
    expect(
      find.textContaining('Analyze this repository', skipOffstage: false),
      findsWidgets,
    );
    expect(textAnywhere('Reply to this task…'), findsOneWidget);
    // Executing: the composer's send button becomes a stop button.
    expect(find.byKey(const Key('composer-stop')), findsOneWidget);
    expect(find.byKey(const Key('composer-send')), findsNothing);
    // Nothing is pending yet, so no approval block should render.
    expect(textAnywhere('HUMAN VERIFICATION NEEDED'), findsNothing);
    // The mock stream stays open, so no reconnect banner.
    expect(textAnywhere('Reconnecting to live updates…'), findsNothing);

    // Flushes a trailing zero-duration timer from task creation that would
    // otherwise still be pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Stop asks for confirmation before cancelling', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final queuedTask = store.createTask(prompt: 'Long running job');

    await tester.pumpWidget(
      wrapWithTestApp(SessionScreen(taskId: queuedTask.id), store: store),
    );
    await settle(tester);

    await tester.tap(find.byKey(const Key('composer-stop')));
    await settle(tester);
    expect(find.text('Stop this task?'), findsOneWidget);

    await tester.tap(find.text('Keep running'));
    await settle(tester);
    expect(
      store.listTasks().firstWhere((t) => t.id == queuedTask.id).status,
      TaskStatus.queued,
    );

    await tester.tap(find.byKey(const Key('composer-stop')));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Stop task'));
    await settle(tester);
    await settle(tester);

    expect(
      store.listTasks().firstWhere((t) => t.id == queuedTask.id).status,
      TaskStatus.cancelled,
    );
    expect(textAnywhere('Cancelled'), findsWidgets);
    // Terminal: the composer is gone.
    expect(find.byKey(const Key('composer-field')), findsNothing);
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Shows a reconnecting banner when the live stream drops', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final queuedTask = store.createTask(prompt: 'Needs a live stream');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigProvider.overrideWithValue(
            const ApiConfig(
              useNetwork: false,
              baseUrl: 'http://test',
              googleIdToken: 'test',
            ),
          ),
          mockBackendStoreProvider.overrideWithValue(store),
          sessionStreamRepositoryProvider.overrideWithValue(
            const _DroppingStreamRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: SessionScreen(taskId: queuedTask.id),
        ),
      ),
    );
    await settle(tester);

    expect(textAnywhere('Reconnecting to live updates…'), findsOneWidget);

    // Tearing the tree down disposes the controller and its backoff timer.
    await tester.pumpWidget(const SizedBox());
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
      expect(textAnywhere('Reply to this task…'), findsNothing);
      expect(find.byKey(const Key('composer-field')), findsNothing);
      expect(textAnywhere('Reconnecting to live updates…'), findsNothing);
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
      // ...while the git milestones do show up as trace cards.
      expect(
        find.textContaining(
          'Changes committed and pushed',
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      // ...but must be reachable from the same terminal logs sheet used for
      // agent output, since that's the one place meant to hold it. The
      // header's logs button sits above the scrolling content, so it is
      // always reachable.
      await tester.tap(find.byIcon(Icons.terminal_rounded).first);
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
    // since this harness has no GoRouter ancestor.
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

    // The sheet reuses the ComposerBar (with the task's context) rather
    // than a bespoke form.
    expect(textAnywhere('Describe what you need built next…'), findsOneWidget);
    expect(find.byKey(const Key('composer-field')), findsOneWidget);
    expect(find.byKey(const Key('composer-send')), findsOneWidget);
    expect(textAnywhere('phodex · feature/mobile-v1'), findsWidgets);
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
      // Command executions render as "$ command" plus their output.
      expect(
        find.textContaining(
          r'$ rg "codex|worker|approval"',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      // A live task can still be force-terminated from here.
      expect(textAnywhere('Force terminate'), findsOneWidget);
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

    // With dynamic simulation off the approved task completes at once and
    // the completion card takes over from the approval block.
    expect(textAnywhere('HUMAN VERIFICATION NEEDED'), findsNothing);
    expect(
      textAnywhere('Approved action completed. All checks passed.'),
      findsOneWidget,
    );
  });
}
