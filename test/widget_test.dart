import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medication_manager/app.dart';

void main() {
  testWidgets('dashboard renders greeting', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicationManagerApp());

    expect(find.text('Good morning, Sarah'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
  });
}
