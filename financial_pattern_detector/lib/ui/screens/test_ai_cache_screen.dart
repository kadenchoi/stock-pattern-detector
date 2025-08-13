import 'package:financial_pattern_detector/ui/widgets/pattern_card.dart';
import 'package:flutter/material.dart';
import '../../models/pattern_detection.dart';

class TestAiCacheScreen extends StatelessWidget {
  const TestAiCacheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a sample pattern for testing
    final testPattern = PatternMatch(
      id: 'test_pattern_1',
      symbol: 'AAPL',
      patternType: PatternType.triangle,
      direction: PatternDirection.bullish,
      matchScore: 0.85,
      detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
      startTime: DateTime.now().subtract(const Duration(hours: 4)),
      endTime: DateTime.now().subtract(const Duration(hours: 1)),
      priceTarget: 150.75,
      description:
          'Strong bullish triangle pattern detected with high confidence',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Cache Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Response Caching Test',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This screen tests the AI response caching functionality. Click "Analyze" to get an AI strategy, then click "Refresh" to see if it uses cached data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            PatternCard(
              pattern: testPattern,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pattern card tapped!')),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
                '1. Click "Analyze" to get AI strategy (this will make a network call)'),
            const Text('2. Wait for the response to be displayed'),
            const Text(
                '3. Click "Refresh" to see if cached result is used (should be instant)'),
            const Text(
                '4. Look for "Cached result" indicator when using cache'),
          ],
        ),
      ),
    );
  }
}
