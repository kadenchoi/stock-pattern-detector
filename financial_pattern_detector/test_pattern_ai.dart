import 'package:flutter/material.dart';
import 'lib/models/pattern_detection.dart';
import 'lib/ui/screens/pattern_details_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pattern AI Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create a test pattern
    final testPattern = PatternMatch(
      id: 'test-123',
      symbol: 'AAPL',
      patternType: PatternType.cupAndHandle,
      direction: PatternDirection.bullish,
      matchScore: 0.85,
      detectedAt: DateTime.now(),
      startTime: DateTime.now().subtract(Duration(days: 10)),
      endTime: DateTime.now().subtract(Duration(days: 2)),
      priceTarget: 150.25,
      description:
          'Strong cup and handle pattern with bullish breakout potential',
      metadata: {
        'volume': 'High',
        'support_level': 145.0,
        'resistance_level': 152.0,
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Pattern AI Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PatternDetailsScreen(pattern: testPattern),
              ),
            );
          },
          child: Text('Test Pattern Details with AI'),
        ),
      ),
    );
  }
}
