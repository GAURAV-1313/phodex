import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/approvals/presentation/approvals_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Approvals screen renders pending approvals', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(const ApprovalsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Review approvals'), findsOneWidget);
    expect(find.text('Approve'), findsWidgets);
    expect(find.text('Reject'), findsWidgets);
  });
}
