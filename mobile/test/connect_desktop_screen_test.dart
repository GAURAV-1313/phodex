import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/welcome/presentation/connect_desktop_screen.dart';

import 'test_helpers.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Manual entry is hidden until requested', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(const ConnectDesktopScreen()));
    await settle(tester);

    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Enter the address manually instead'));
    await settle(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Hide manual entry'), findsOneWidget);
  });

  testWidgets('Submitting empty input shows the validation message', (
    tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(const ConnectDesktopScreen()));
    await settle(tester);

    await tester.tap(find.text('Enter the address manually instead'));
    await settle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await settle(tester);

    expect(find.textContaining('Enter a valid address'), findsOneWidget);
  });
}
