import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/features/welcome/presentation/connect_desktop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('A previously paired desktop can be forgotten', (tester) async {
    SharedPreferences.setMockInitialValues({
      serverUrlPrefsKey: 'http://100.64.0.3:8000',
    });
    await tester.pumpWidget(wrapWithTestApp(const ConnectDesktopScreen()));
    await settle(tester);

    expect(find.text('Currently paired'), findsOneWidget);
    expect(find.text('http://100.64.0.3:8000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('connect-desktop-forget')));
    await settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ConnectDesktopScreen)),
    );
    expect(container.read(serverUrlProvider), isNull);
    expect(find.text('Currently paired'), findsNothing);
  });
}
