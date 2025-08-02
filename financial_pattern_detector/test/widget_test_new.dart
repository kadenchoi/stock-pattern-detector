// Basic widget test for Financial Pattern Detector
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_pattern_detector/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinancialPatternDetectorApp());

    // Verify that the app title appears
    expect(find.text('Financial Pattern Detector'), findsOneWidget);
  });
}
