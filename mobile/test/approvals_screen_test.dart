import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/approvals/presentation/approvals_screen.dart';

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

    expect(textAnywhere('Pending Approval'), findsOneWidget);
    expect(textAnywhere('Approve file operation'), findsOneWidget);
    expect(
      find.textContaining('git add -A && git commit', skipOffstage: false),
      findsOneWidget,
    );
    expect(textAnywhere('MEDIUM RISK'), findsOneWidget);
    expect(textAnywhere('Approve'), findsOneWidget);
    expect(textAnywhere('Reject'), findsOneWidget);
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

    expect(textAnywhere('Nothing needs your approval'), findsOneWidget);
    expect(textAnywhere('Pending Approval'), findsNothing);
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

    expect(textAnywhere('Nothing needs your approval'), findsOneWidget);
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
    expect(textAnywhere('Pending Approval'), findsOneWidget);

    await tester.tap(rejectButton);
    await settle(tester);
    await tester.enterText(
      find.byType(TextField, skipOffstage: false),
      'Needs a safer approach',
    );
    await tester.tap(find.text('Reject', skipOffstage: false).last);
    await settle(tester);
    await settle(tester);

    expect(textAnywhere('Nothing needs your approval'), findsOneWidget);
    final pending = store.listPendingApprovals();
    expect(pending, isEmpty);
  });
}
