import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtrade/widgets/shared.dart';

void main() {
  testWidgets('VerticalAccentLine widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerticalAccentLine(),
        ),
      ),
    );

    // Verify that the VerticalAccentLine widget is built and exists in the widget tree.
    expect(find.byType(VerticalAccentLine), findsOneWidget);
  });
}
