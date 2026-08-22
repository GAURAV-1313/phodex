import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ai_engine/presentation/ai_engine_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Saving an AI engine key updates the status pill', (
    tester,
  ) async {
    await tester.pumpWidget(wrapWithTestApp(const AiEngineScreen()));
    await tester.pumpAndSettle();

    expect(find.text('USING DESKTOP LOGIN'), findsNWidgets(2));

    await tester.enterText(
      find.widgetWithText(TextField, 'Anthropic API key'),
      'sk-ant-test-key',
    );
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('KEY SET'), findsOneWidget);
    expect(find.text('USING DESKTOP LOGIN'), findsOneWidget);
  });
}
