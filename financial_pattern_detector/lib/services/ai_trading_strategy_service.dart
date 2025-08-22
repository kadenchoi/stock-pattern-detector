import '../models/stock_data.dart';
import '../models/pattern_detection.dart';
import 'firebase_ai_service.dart';

class AITradingStrategyService {
  static final AITradingStrategyService instance = AITradingStrategyService._();
  AITradingStrategyService._();

  final FirebaseAiService _firebaseAI = FirebaseAiService.instance;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _firebaseAI.initializeModel();
      _isInitialized = true;
    }
  }

  Future<Map<String, dynamic>?> analyzeSymbolStrategy({
    required String symbol,
    required StockDataSeries stockData,
    List<PatternMatch>? patterns,
  }) async {
    try {
      await _ensureInitialized();

      // If we have patterns, use Firebase AI for detailed analysis
      if (patterns != null && patterns.isNotEmpty) {
        return await _analyzePatternWithFirebaseAI(symbol, stockData, patterns);
      } else {
        // Fall back to technical analysis for symbols without patterns
        return _generateTechnicalAnalysis(symbol, stockData, patterns);
      }
    } catch (e) {
      print('Error analyzing symbol strategy: $e');
      // Fall back to technical analysis on AI service error
      return _generateTechnicalAnalysis(symbol, stockData, patterns);
    }
  }

  Future<Map<String, dynamic>?> _analyzePatternWithFirebaseAI(String symbol,
      StockDataSeries stockData, List<PatternMatch> patterns) async {
    try {
      // Use the most significant pattern for AI analysis
      final primaryPattern =
          patterns.reduce((a, b) => a.matchScore > b.matchScore ? a : b);

      // Get trading strategy from Firebase AI
      final strategy = await _firebaseAI.analyzePatternForStrategy(
        pattern: primaryPattern,
        stockHistory: stockData.data,
        currentPrice:
            stockData.data.isNotEmpty ? stockData.data.last.close : null,
      );

      if (strategy == null) {
        return _generateTechnicalAnalysis(symbol, stockData, patterns);
      }

      // Convert TradingStrategy to our expected format
      return _convertStrategyToAnalysis(symbol, stockData, strategy, patterns);
    } catch (e) {
      print('Firebase AI analysis failed: $e');
      return _generateTechnicalAnalysis(symbol, stockData, patterns);
    }
  }

  Map<String, dynamic> _convertStrategyToAnalysis(
      String symbol,
      StockDataSeries stockData,
      TradingStrategy strategy,
      List<PatternMatch> patterns) {
    final currentPrice =
        stockData.data.isNotEmpty ? stockData.data.last.close : 0.0;
    final priceChange = stockData.data.length > 1
        ? stockData.data.last.close -
            stockData.data[stockData.data.length - 2].close
        : 0.0;
    final percentChange = stockData.data.length > 1 &&
            stockData.data[stockData.data.length - 2].close != 0
        ? (priceChange / stockData.data[stockData.data.length - 2].close) * 100
        : 0.0;

    // Determine trend from AI recommendation
    String trendAnalysis;
    String trendStrength;

    switch (strategy.recommendation.toUpperCase()) {
      case 'BUY':
        trendAnalysis = 'Bullish';
        trendStrength = strategy.confidence > 0.7 ? 'Strong' : 'Moderate';
        break;
      case 'SELL':
        trendAnalysis = 'Bearish';
        trendStrength = strategy.confidence > 0.7 ? 'Strong' : 'Moderate';
        break;
      default:
        trendAnalysis = 'Neutral';
        trendStrength = 'Weak';
    }

    final patternInfo = patterns
        .map((p) => '${p.patternType.name} (${p.direction.name})')
        .join(', ');

    return {
      'symbol': symbol,
      'timestamp': DateTime.now().toIso8601String(),
      'currentPrice': currentPrice,
      'priceChange': priceChange,
      'percentChange': percentChange,
      'trendAnalysis': trendAnalysis,
      'trendStrength': trendStrength,
      'confidence': strategy.confidence,
      'aiRecommendation': strategy.recommendation,
      'keyLevels': {
        'entryPoint': strategy.entryPoint,
        'stopLoss': strategy.stopLoss,
        'takeProfit': strategy.takeProfit,
      },
      'riskLevel': strategy.riskLevel,
      'timeHorizon': '${strategy.durationDays} days',
      'reasoning': strategy.reasoning,
      'keyFactors': strategy.keyFactors,
      'patterns': patternInfo,
      'summary': _generateAISummary(symbol, strategy, trendAnalysis),
      'disclaimer':
          'AI-powered educational analysis only - not financial advice',
      'source': 'Firebase AI (Gemini)',
    };
  }

  String _generateAISummary(
      String symbol, TradingStrategy strategy, String trend) {
    return '$symbol AI Analysis: $trend trend with ${(strategy.confidence * 100).toStringAsFixed(0)}% confidence. '
        'AI suggests ${strategy.recommendation} with ${strategy.riskLevel.toLowerCase()} risk over ${strategy.durationDays} days.';
  }

  Map<String, dynamic> _generateTechnicalAnalysis(
      String symbol, StockDataSeries stockData, List<PatternMatch>? patterns) {
    final data = stockData.data;
    if (data.isEmpty) {
      return _createNoDataResponse();
    }

    final latestData = data.last;
    final previousData = data.length > 1 ? data[data.length - 2] : null;

    final priceChange =
        previousData != null ? latestData.close - previousData.close : 0.0;
    final percentChange = previousData != null && previousData.close != 0
        ? (priceChange / previousData.close) * 100
        : 0.0;

    // Calculate technical indicators
    final sma20 = _calculateSMA(data, 20);
    final sma50 = _calculateSMA(data, 50);
    final rsi = _calculateRSI(data, 14);
    final volume = latestData.volume;
    final avgVolume = _calculateAverageVolume(data, 20);

    // Determine trend
    String trendAnalysis;
    String trendStrength;
    double confidence;

    if (latestData.close > sma20 && sma20 > sma50) {
      trendAnalysis = 'Bullish';
      trendStrength = percentChange > 2 ? 'Strong' : 'Moderate';
      confidence = 0.7;
    } else if (latestData.close < sma20 && sma20 < sma50) {
      trendAnalysis = 'Bearish';
      trendStrength = percentChange < -2 ? 'Strong' : 'Moderate';
      confidence = 0.7;
    } else {
      trendAnalysis = 'Neutral';
      trendStrength = 'Weak';
      confidence = 0.4;
    }

    // Adjust confidence based on patterns
    if (patterns?.isNotEmpty == true) {
      final avgPatternConfidence =
          patterns!.fold(0.0, (sum, p) => sum + p.matchScore) / patterns.length;
      confidence = (confidence + avgPatternConfidence) / 2;
    }

    // Calculate support and resistance
    final recentData =
        data.length >= 20 ? data.sublist(data.length - 20) : data;
    final highs = recentData.map((d) => d.high).toList()..sort();
    final lows = recentData.map((d) => d.low).toList()..sort();

    final resistance = highs[highs.length - 3]; // 3rd highest
    final support = lows[2]; // 3rd lowest

    // Pattern information
    final patternInfo = patterns?.isNotEmpty == true
        ? patterns!
            .map((p) => '${p.patternType.name} (${p.direction.name})')
            .join(', ')
        : 'No significant patterns detected';

    return {
      'symbol': symbol,
      'timestamp': DateTime.now().toIso8601String(),
      'currentPrice': latestData.close,
      'priceChange': priceChange,
      'percentChange': percentChange,
      'trendAnalysis': trendAnalysis,
      'trendStrength': trendStrength,
      'keyLevels': {'support': support, 'resistance': resistance},
      'technicalSignals': {
        'movingAverages': latestData.close > sma20
            ? 'Price above SMA20 (bullish signal)'
            : 'Price below SMA20 (bearish signal)',
        'rsi': rsi > 70
            ? 'Overbought territory (RSI: ${rsi.toStringAsFixed(1)})'
            : rsi < 30
                ? 'Oversold territory (RSI: ${rsi.toStringAsFixed(1)})'
                : 'Neutral zone (RSI: ${rsi.toStringAsFixed(1)})',
        'volume': volume > avgVolume * 1.2
            ? 'Above average volume (increased interest)'
            : volume < avgVolume * 0.8
                ? 'Below average volume (low interest)'
                : 'Normal volume levels'
      },
      'educationalStrategy': {
        'shortTerm': _getShortTermOutlook(trendAnalysis, rsi, percentChange),
        'mediumTerm': _getMediumTermOutlook(trendAnalysis, sma20, sma50),
        'riskFactors':
            _getRiskFactors(rsi, volume.toDouble(), avgVolume, patterns)
      },
      'patterns': patternInfo,
      'confidence': confidence,
      'summary':
          _generateSummary(symbol, trendAnalysis, trendStrength, confidence),
      'disclaimer': 'Educational analysis only - not financial advice'
    };
  }

  String _getShortTermOutlook(String trend, double rsi, double percentChange) {
    if (trend == 'Bullish' && rsi < 70) {
      return 'Short-term momentum appears positive. Educational observation: upward movement possible if volume supports.';
    } else if (trend == 'Bearish' && rsi > 30) {
      return 'Short-term pressure to the downside. Educational note: consider support levels for potential bounce.';
    } else {
      return 'Short-term direction unclear. Educational advice: wait for clearer signals before making any decisions.';
    }
  }

  String _getMediumTermOutlook(String trend, double sma20, double sma50) {
    if (sma20 > sma50) {
      return 'Medium-term structure remains constructive with shorter MA above longer MA.';
    } else {
      return 'Medium-term structure shows caution with shorter MA below longer MA.';
    }
  }

  List<String> _getRiskFactors(double rsi, double volume, double avgVolume,
      List<PatternMatch>? patterns) {
    final risks = <String>[];

    if (rsi > 80) risks.add('Extremely overbought conditions');
    if (rsi < 20) risks.add('Extremely oversold conditions');
    if (volume < avgVolume * 0.5)
      risks.add('Very low volume - lack of conviction');
    if (patterns?.isEmpty == true)
      risks.add('No clear technical patterns for guidance');

    risks.addAll([
      'Market volatility',
      'External economic factors',
      'Sector-specific risks'
    ]);

    return risks;
  }

  String _generateSummary(
      String symbol, String trend, String strength, double confidence) {
    return '$symbol shows $trend trend with $strength momentum. Educational confidence: ${(confidence * 100).toStringAsFixed(0)}%. Monitor key levels and volume for confirmation.';
  }

  Map<String, dynamic> _createNoDataResponse() {
    return {
      'error': 'Insufficient data for analysis',
      'summary': 'Cannot perform analysis without historical price data',
      'disclaimer': 'Educational analysis only - not financial advice'
    };
  }

  double _calculateSMA(List<StockData> data, int period) {
    if (data.length < period) return data.last.close;

    final recent = data.sublist(data.length - period);
    final sum = recent.fold(0.0, (sum, item) => sum + item.close);
    return sum / period;
  }

  double _calculateRSI(List<StockData> data, int period) {
    if (data.length < period + 1) return 50.0;

    double avgGain = 0.0;
    double avgLoss = 0.0;

    // Calculate initial average gain and loss
    for (int i = data.length - period; i < data.length; i++) {
      final change = data[i].close - data[i - 1].close;
      if (change > 0) {
        avgGain += change;
      } else {
        avgLoss += change.abs();
      }
    }

    avgGain /= period;
    avgLoss /= period;

    if (avgLoss == 0) return 100.0;

    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  double _calculateAverageVolume(List<StockData> data, int period) {
    if (data.length < period) {
      return data.fold(0.0, (sum, item) => sum + item.volume.toDouble()) /
          data.length;
    }

    final recent = data.sublist(data.length - period);
    final sum = recent.fold(0.0, (sum, item) => sum + item.volume.toDouble());
    return sum / period;
  }
}
