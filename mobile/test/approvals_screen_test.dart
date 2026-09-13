import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/approvals/presentation/approvals_screen.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

import 'test_helpers.dart';

/// This screen's content routinely runs past the Viewport's default 250px
/// cacheExtent, which finders treat as "offstage" and skip by default even
/// though the widget genuinely exists and rendered correctly — this is a
/// content-presence check, not a "can a user see this without scrolling"
/// check, so skipOffstage: false is the correct match here, not a workaround.
Finder textAnywhere(String text) => find.text(text, skipOffstage: false);

/// PhodexMascot animates continuously by design, so pumpAndSettle() never
/// settles here — pump a bounded, fixed amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Shows the pending approval with command and risk', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const ApprovalsScreen(), store: store),
    );
    await settle(tester);

    expect(textAnywhere('Approvals'), findsOneWidget);
    expect(find.byKey(const Key('stitch-back-button')), findsOneWidget);
    expect(textAnywhere('1 pending'), findsOneWidget);
    expect(
      textAnywhere(
        'Approvals are gated on your phone — nothing runs until you say so.',
      ),
      findsOneWidget,
    );
    expect(textAnywhere('Approve file operation'), findsOneWidget);
    // The approval is attributed to its task.
    expect(
      find.textContaining('Investigate CI failure', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('git add -A && git commit', skipOffstage: false),
      findsOneWidget,
    );
    expect(textAnywhere('MEDIUM RISK'), findsOneWidget);
    expect(find.byType(TaskStatusChip, skipOffstage: false), findsOneWidget);
    expect(textAnywhere('Needs approval'), findsOneWidget);
    expect(textAnywhere('Approve'), findsOneWidget);
    expect(textAnywhere('Reject'), findsOneWidget);
    expect(textAnywhere('View full execution plan'), findsOneWidget);
  });

  testWidgets('Shows the empty state once nothing is pending', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);
    final pending = store.listPendingApprovals();
    for (final approval in pending) {
      store.reject(approval.id);
    }

    await tester.pumpWidget(
      wrapWithTestApp(const ApprovalsScreen(), store: store),
    );
    await settle(tester);

    expect(textAnywhere('Nothing waiting on you'), findsOneWidget);
    expect(
      textAnywhere('Approval requests from your agent show up here.'),
      findsOneWidget,
    );
    expect(textAnywhere('1 pending'), findsNothing);
  });

  testWidgets('Approving removes the request from the list', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const ApprovalsScreen(), store: store),
    );
    await settle(tester);

    final approveButton = find.text('Approve', skipOffstage: false);
    await tester.ensureVisible(approveButton);
    await settle(tester);
    await tester.tap(approveButton);
    await settle(tester);
    await settle(tester);

    expect(textAnywhere('Nothing waiting on you'), findsOneWidget);
  });

  testWidgets('Rejecting prompts for an optional reason before resolving it', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const ApprovalsScreen(), store: store),
    );
    await settle(tester);

    final rejectButton = find.text('Reject', skipOffstage: false);
    await tester.ensureVisible(rejectButton);
    await settle(tester);
    await tester.tap(rejectButton);
    await settle(tester);

    expect(textAnywhere('Reject this action?'), findsOneWidget);

    // Cancelling the reason dialog must not resolve the approval.
    await tester.tap(textAnywhere('Cancel'));
    await settle(tester);
    expect(textAnywhere('1 pending'), findsOneWidget);

    await tester.tap(rejectButton);
    await settle(tester);
    await tester.enterText(
      find.byType(TextField, skipOffstage: false),
      'Needs a safer approach',
    );
    await tester.tap(find.text('Reject', skipOffstage: false).last);
    await settle(tester);
    await settle(tester);

    expect(textAnywhere('Nothing waiting on you'), findsOneWidget);
    final pending = store.listPendingApprovals();
    expect(pending, isEmpty);
  });
}
