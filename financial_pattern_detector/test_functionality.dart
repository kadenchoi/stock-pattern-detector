import 'lib/models/app_settings.dart';
import 'lib/services/yahoo_finance_service.dart';
import 'lib/services/pattern_analyzer.dart';
import 'lib/models/stock_data.dart';

void main() async {
  print('Testing Financial Pattern Detector functionality...\n');

  // Test 1: Yahoo Finance API
  print('1. Testing Yahoo Finance API...');
  try {
    final yahooService = YahooFinanceService();
    final stockData = await yahooService.fetchStockData(
        symbol: 'AAPL', period: DataPeriod.oneMonth);

    if (stockData != null) {
      print('✓ Successfully fetched data points for AAPL');
    } else {
      print('✗ No data received for AAPL');
    }
  } catch (e) {
    print('✗ Yahoo Finance API test failed: $e');
  }

  // Test 2: Pattern Analysis
  print('\n2. Testing Pattern Analysis...');
  try {
    final patternAnalyzer = PatternAnalyzer();

    // Create sample data for pattern testing
    final sampleData = _createSampleStockDataSeries();
    print('  Created sample data with ${sampleData.data.length} points');

    final patterns = await patternAnalyzer.analyzePatterns(sampleData);
    print('✓ Pattern analysis completed');
    print('  Found ${patterns.length} potential patterns');

    for (final pattern in patterns.take(3)) {
      print(
          '  - ${pattern.patternType}: ${(pattern.matchScore * 100).toStringAsFixed(2)}% confidence');
    }
  } catch (e) {
    print('✗ Pattern analysis test failed: $e');
  }

  print('\nFunctionality test completed!');
}

StockDataSeries _createSampleStockDataSeries() {
  final now = DateTime.now();
  final data = <StockData>[];

  // Create 30 days of sample data with an upward trend and some volatility
  for (int i = 0; i < 30; i++) {
    final timestamp = now.subtract(Duration(days: 29 - i));
    final basePrice = 150.0 + (i * 2.0); // Upward trend
    final volatility = (i % 3 - 1) * 5.0; // Some volatility

    final open = basePrice + volatility;
    final close = basePrice + volatility + (i % 2 == 0 ? 1.0 : -0.5);
    final high = [open, close].reduce((a, b) => a > b ? a : b) + 2.0;
    final low = [open, close].reduce((a, b) => a < b ? a : b) - 1.5;
    final volume = 1000000 + (i * 50000);

    data.add(StockData(
      symbol: 'TEST',
      timestamp: timestamp,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
    ));
  }

  return StockDataSeries(
    symbol: 'TEST',
    data: data,
    lastUpdated: now,
  );
}
