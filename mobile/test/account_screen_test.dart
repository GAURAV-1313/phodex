import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/account/presentation/account_screen.dart';

import 'test_helpers.dart';

/// PhodexMascot animates continuously by design, so pumpAndSettle() never
/// settles here — pump a bounded, fixed amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// A ListView's Sliver machinery never builds Elements for children far
/// enough beyond the viewport + cacheExtent at all — `skipOffstage: false`
/// only reveals elements that exist but are marked offstage, it can't
/// materialize ones that were never built. An actual scroll is what makes
/// the rest of a long screen (System settings, Sign out) real to find.
Future<void> scrollDown(WidgetTester tester, double offset) async {
  await tester.drag(find.byType(ListView).first, Offset(0, -offset));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Renders the real backend dashboard: profile, usage, runtime', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const AccountScreen(), store: store),
    );
    await settle(tester);

    // Title, matching the Header -> Title -> Content pattern every other
    // top-level tab screen uses. "Account" also labels the bottom dock's
    // own tab, so there are legitimately two matches, not one.
    expect(find.text('Account'), findsWidgets);

    // Real profile data from the backend, not placeholder copy.
    expect(find.text(store.user.name), findsOneWidget);
    expect(find.text(store.user.email), findsOneWidget);

    expect(find.text('USAGE THIS MONTH'), findsOneWidget);
    expect(find.text('Automated tasks'), findsOneWidget);

    // The Desktop runtime card sits right at the edge of what a ListView's
    // Sliver builds without scrolling — a modest scroll makes finding it
    // reliable instead of dependent on an unscrolled boundary condition.
    await scrollDown(tester, 300);

    // The seeded device is online — the runtime card should say so.
    // _SectionLabel renders its text uppercased.
    expect(find.text('DESKTOP RUNTIME'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('System settings rows are real, tappable actions', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const AccountScreen(), store: store),
    );
    await settle(tester);
    await scrollDown(tester, 600);
    await scrollDown(tester, 600);

    expect(find.text('AI engine'), findsOneWidget);
    expect(find.text('Desktop connection'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Privacy & security'), findsOneWidget);
    expect(find.text('Support center'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Every row here now does something real (navigates via go_router, or —
    // for Appearance — opens a picker directly). Rows that navigate can't be
    // tapped from this harness (no GoRouter ancestor, same boundary as the
    // AI engine / Privacy & security rows) — Appearance is covered by its
    // own dedicated test below instead.
  });

  testWidgets('Appearance opens a real System/Light/Dark picker', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(const AccountScreen(), store: store),
    );
    await settle(tester);
    await scrollDown(tester, 600);
    await scrollDown(tester, 600);

    await tester.tap(find.text('Appearance'));
    await settle(tester);

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.textContaining('coming in a future update'), findsNothing);

    await tester.tap(find.text('Dark'));
    await settle(tester);

    // The sheet closes after picking an option.
    expect(find.text('System'), findsNothing);
  });
}
