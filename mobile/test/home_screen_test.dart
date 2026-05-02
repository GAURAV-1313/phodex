import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Home screen renders live composer UI', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Phodex'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Design a database schema'), findsOneWidget);
    expect(find.text('What can I help with?'), findsNothing);
  });
}
