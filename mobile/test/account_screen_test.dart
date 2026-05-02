import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/presentation/account_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Account screen renders backend dashboard settings UI', (
    tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(const AccountScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.byKey(const Key('account-limits-card')), findsOneWidget);
    expect(find.text('Close settings'), findsOneWidget);
  });
}
