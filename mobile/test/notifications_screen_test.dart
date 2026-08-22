import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/presentation/notifications_screen.dart';

import 'test_helpers.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'Shows an honest "not set up" state when Firebase was never initialized',
    (tester) async {
      // wrapWithTestApp never overrides firebaseAvailableProvider, so it
      // resolves to its real default (false) here — exactly the state a
      // real install has before `flutterfire configure` has ever been run,
      // no Firebase mocking required to exercise this path.
      await tester.pumpWidget(wrapWithTestApp(const NotificationsScreen()));
      await settle(tester);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Not set up on this build yet'), findsOneWidget);
      expect(find.text('Enable notifications'), findsNothing);
    },
  );
}
