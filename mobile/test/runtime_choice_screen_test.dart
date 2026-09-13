import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/features/welcome/application/runtime_choice_controller.dart';
import 'package:mobile/features/welcome/presentation/connect_desktop_screen.dart';
import 'package:mobile/features/welcome/presentation/runtime_choice_screen.dart';
import 'package:mobile/features/welcome/presentation/sign_in_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Offers Phodex Cloud (recommended) and My desktop', (
    tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(const RuntimeChoiceScreen()));
    await settle(tester);

    expect(find.text('Choose a runtime'), findsOneWidget);
    expect(find.text('Phodex Cloud'), findsOneWidget);
    expect(find.text('RECOMMENDED'), findsOneWidget);
    expect(find.text('My desktop'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Phodex Cloud, recommended')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('My desktop')), findsOneWidget);
  });

  testWidgets('Choosing Phodex Cloud points the app at the cloud URL and '
      'continues to sign-in', (tester) async {
    final container = await pumpPhodexApp(tester);
    container.read(appRouterProvider).go('/runtime');
    await settle(tester);

    await tester.tap(find.byKey(const Key('runtime-option-cloud')));
    await settle(tester);

    expect(container.read(serverUrlProvider), testApiConfig.cloudBaseUrl);
    expect(container.read(runtimeChoiceProvider).mode, RuntimeMode.cloud);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Choosing My desktop opens the pairing flow', (tester) async {
    final container = await pumpPhodexApp(tester);
    container.read(appRouterProvider).go('/runtime');
    await settle(tester);

    await tester.tap(find.byKey(const Key('runtime-option-desktop')));
    await settle(tester);

    expect(container.read(runtimeChoiceProvider).mode, RuntimeMode.desktop);
    expect(find.byType(ConnectDesktopScreen), findsOneWidget);
    expect(find.text('Connect desktop'), findsOneWidget);
  });
}
