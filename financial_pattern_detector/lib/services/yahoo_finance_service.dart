// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_data.dart';
import '../models/app_settings.dart';

class YahooFinanceService {
  static const String _baseUrl =
      'https://query1.finance.yahoo.com/v8/finance/chart';

  final http.Client _httpClient;

  YahooFinanceService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Fetches stock data for a given symbol and period
  Future<StockDataSeries?> fetchStockData({
    required String symbol,
    required DataPeriod period,
    String range = '1mo',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$symbol');
      final queryParams = {
        'interval': period.value,
        'range': range,
        'includeAdjustedClose': 'true',
      };

      final uri = url.replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseYahooResponse(symbol, data);
      } else {
        print('Failed to fetch data for $symbol: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching data for $symbol: $e');
      return null;
    }
  }

  /// Fetches data for multiple symbols
  Future<Map<String, StockDataSeries?>> fetchMultipleStocks({
    required List<String> symbols,
    required DataPeriod period,
    String range = '1mo',
  }) async {
    final results = <String, StockDataSeries?>{};

    // Process symbols in batches to avoid overwhelming the API
    const batchSize = 5;
    for (int i = 0; i < symbols.length; i += batchSize) {
      final batch = symbols.skip(i).take(batchSize).toList();
      final futures = batch.map(
        (symbol) =>
            fetchStockData(symbol: symbol, period: period, range: range),
      );

      final batchResults = await Future.wait(futures);

      for (int j = 0; j < batch.length; j++) {
        results[batch[j]] = batchResults[j];
      }

      // Add delay between batches to be respectful to the API
      if (i + batchSize < symbols.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }

  StockDataSeries? _parseYahooResponse(
    String symbol,
    Map<String, dynamic> data,
  ) {
    try {
      final chart = data['chart'];
      if (chart == null || chart['result'] == null || chart['result'].isEmpty) {
        return null;
      }

      final result = chart['result'][0];
      final timestamps = List<int>.from(result['timestamp'] ?? []);
      final indicators = result['indicators'];
      final quote = indicators['quote'][0];

      final opens = List<double?>.from(quote['open'] ?? []);
      final highs = List<double?>.from(quote['high'] ?? []);
      final lows = List<double?>.from(quote['low'] ?? []);
      final closes = List<double?>.from(quote['close'] ?? []);
      final volumes = List<int?>.from(quote['volume'] ?? []);

      final stockDataList = <StockData>[];

      for (int i = 0; i < timestamps.length; i++) {
        // Skip entries with null values
        if (opens[i] == null ||
            highs[i] == null ||
            lows[i] == null ||
            closes[i] == null ||
            volumes[i] == null) {
          continue;
        }

        stockDataList.add(
          StockData(
            symbol: symbol,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              timestamps[i] * 1000,
            ),
            open: opens[i]!,
            high: highs[i]!,
            low: lows[i]!,
            close: closes[i]!,
            volume: volumes[i]!,
          ),
        );
      }

      return StockDataSeries(
        symbol: symbol,
        data: stockDataList,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Yahoo Finance response for $symbol: $e');
      return null;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
