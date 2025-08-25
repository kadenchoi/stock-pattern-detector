import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:json_annotation/json_annotation.dart';
import '../models/pattern_detection.dart';
import '../models/stock_data.dart';
import 'ai_response_cache_service.dart';

@JsonSerializable()
class TradingStrategy {
  final String recommendation; // BUY, SELL, HOLD
  final double confidence; // 0.0 to 1.0
  final double entryPoint;
  final double stopLoss;
  final double takeProfit;
  final int durationDays;
  final String reasoning;
  final String riskLevel; // LOW, MEDIUM, HIGH
  final List<String> keyFactors;

  TradingStrategy({
    required this.recommendation,
    required this.confidence,
    required this.entryPoint,
    required this.stopLoss,
    required this.takeProfit,
    required this.durationDays,
    required this.reasoning,
    required this.riskLevel,
    required this.keyFactors,
  });

  factory TradingStrategy.fromJson(Map<String, dynamic> json) {
    return TradingStrategy(
      recommendation: json['recommendation'] ?? 'HOLD',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      entryPoint: (json['entryPoint'] ?? 0.0).toDouble(),
      stopLoss: (json['stopLoss'] ?? 0.0).toDouble(),
      takeProfit: (json['takeProfit'] ?? 0.0).toDouble(),
      durationDays: json['durationDays'] ?? 7,
      reasoning: json['reasoning'] ?? '',
      riskLevel: json['riskLevel'] ?? 'MEDIUM',
      keyFactors: List<String>.from(json['keyFactors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'recommendation': recommendation,
        'confidence': confidence,
        'entryPoint': entryPoint,
        'stopLoss': stopLoss,
        'takeProfit': takeProfit,
        'durationDays': durationDays,
        'reasoning': reasoning,
        'riskLevel': riskLevel,
        'keyFactors': keyFactors,
      };
}

class FirebaseAiService {
  late GenerativeModel _model;
  FirebaseAiService._();

  static final FirebaseAiService instance = FirebaseAiService._();

  Future initializeModel() async {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  }

  Future askModel(String question) async {
    final prompt = [Content.text(question)];
    final response = await _model.generateContent(prompt);
    return response;
  }

  /// Analyzes a stock by MACD & RSI & fundamental data
  /// Generate trading strategy for short term / mid term / long term
  Future<TradingStrategy?> analyzeTechnicalForStrategy({
    required String symbol,
    required List<StockData> stockHistory,
  }) async {
    try {
      if (stockHistory.isEmpty) return null;

      // Calculate technical indicators
      final technicalData = _calculateTechnicalIndicators(stockHistory);

      // Prepare stock data for AI analysis
      final stockDataJson =
          _prepareStockDataForAI(symbol, stockHistory, technicalData);

      // Generate system message for technical analysis (without embedded JSON)
      final systemMessage =
          _generateTechnicalSystemMessage(symbol, technicalData);

      // Create prompt with inline data and text
      final prompt = [
        Content('user', [
          TextPart(systemMessage),
          InlineDataPart(
            'application/json',
            utf8.encode(stockDataJson),
          )
        ]),
      ];
      final response = await _model.generateContent(prompt);

      if (response.text == null) return null;

      // Parse the AI response
      final currentPrice = stockHistory.last.close;
      final strategy =
          _parseTechnicalStrategyFromResponse(response.text!, currentPrice);

      return strategy;
    } catch (e) {
      print('Error analyzing technical strategy: $e');
      return null;
    }
  }

  Map<String, dynamic> _calculateTechnicalIndicators(
      List<StockData> stockHistory) {
    final data = stockHistory;
    if (data.length < 26) {
      return {
        'macd': {'macd': 0.0, 'signal': 0.0, 'histogram': 0.0},
        'rsi': 50.0,
        'sma20': data.last.close,
        'sma50': data.last.close,
        'volume': data.last.volume,
        'avgVolume': data.last.volume.toDouble(),
        'priceChange': 0.0,
        'percentChange': 0.0,
      };
    }

    // Calculate MACD
    final macdData = _calculateMACD(data);

    // Calculate RSI
    final rsi = _calculateRSI(data, 14);

    // Calculate Moving Averages
    final sma20 = _calculateSMA(data, 20);
    final sma50 = _calculateSMA(data, 50);

    // Calculate Volume metrics
    final avgVolume = _calculateAverageVolume(data, 20);

    // Calculate Price changes
    final priceChange =
        data.length > 1 ? data.last.close - data[data.length - 2].close : 0.0;
    final percentChange = data.length > 1 && data[data.length - 2].close != 0
        ? (priceChange / data[data.length - 2].close) * 100
        : 0.0;

    return {
      'macd': macdData,
      'rsi': rsi,
      'sma20': sma20,
      'sma50': sma50,
      'volume': data.last.volume,
      'avgVolume': avgVolume,
      'priceChange': priceChange,
      'percentChange': percentChange,
      'support': _calculateSupport(data),
      'resistance': _calculateResistance(data),
    };
  }

  Map<String, dynamic> _calculateMACD(List<StockData> data) {
    if (data.length < 26) return {'macd': 0.0, 'signal': 0.0, 'histogram': 0.0};

    // Calculate EMAs
    final ema12 = _calculateEMA(data, 12);
    final ema26 = _calculateEMA(data, 26);
    final macd = ema12 - ema26;

    // For simplification, using SMA for signal line (should be EMA of MACD)
    final signal = macd; // Simplified
    final histogram = macd - signal;

    return {
      'macd': macd,
      'signal': signal,
      'histogram': histogram,
    };
  }

  double _calculateEMA(List<StockData> data, int period) {
    if (data.length < period) return data.last.close;

    final multiplier = 2.0 / (period + 1);
    double ema = data[data.length - period].close;

    for (int i = data.length - period + 1; i < data.length; i++) {
      ema = (data[i].close * multiplier) + (ema * (1 - multiplier));
    }

    return ema;
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

  double _calculateSupport(List<StockData> data) {
    final recentData =
        data.length >= 20 ? data.sublist(data.length - 20) : data;
    final lows = recentData.map((d) => d.low).toList()..sort();
    return lows.length >= 3 ? lows[2] : lows.first; // 3rd lowest
  }

  double _calculateResistance(List<StockData> data) {
    final recentData =
        data.length >= 20 ? data.sublist(data.length - 20) : data;
    final highs = recentData.map((d) => d.high).toList()..sort();
    return highs.length >= 3
        ? highs[highs.length - 3]
        : highs.last; // 3rd highest
  }

  String _prepareStockDataForAI(String symbol, List<StockData> stockHistory,
      Map<String, dynamic> technicalData) {
    // Take last 50 data points for analysis
    final recentData = stockHistory.length > 50
        ? stockHistory.sublist(stockHistory.length - 50)
        : stockHistory;

    final stockDataJson = {
      'symbol': symbol,
      'timeframe': '${recentData.length} periods',
      'currentPrice': stockHistory.last.close,
      'technicalIndicators': technicalData,
      'priceData': recentData
          .map((data) => {
                'date': data.timestamp.toIso8601String(),
                'open': data.open,
                'high': data.high,
                'low': data.low,
                'close': data.close,
                'volume': data.volume,
              })
          .toList(),
    };

    return jsonEncode(stockDataJson);
  }

  String _generateTechnicalSystemMessage(
      String symbol, Map<String, dynamic> technicalData) {
    return '''
You are an expert quantitative analyst and trading strategist specializing in technical analysis. Analyze the attached stock data (provided as JSON) and generate comprehensive trading strategies for different time horizons.

ATTACHED DATA CONTEXT:
The attached JSON file contains complete stock price history and calculated technical indicators for symbol: $symbol

CURRENT TECHNICAL INDICATORS SUMMARY:
- MACD: ${technicalData['macd']['macd']?.toStringAsFixed(4)} (Signal: ${technicalData['macd']['signal']?.toStringAsFixed(4)}, Histogram: ${technicalData['macd']['histogram']?.toStringAsFixed(4)})
- RSI (14): ${technicalData['rsi']?.toStringAsFixed(2)}
- SMA 20: \$${technicalData['sma20']?.toStringAsFixed(2)}
- SMA 50: \$${technicalData['sma50']?.toStringAsFixed(2)}
- Current Volume: ${technicalData['volume']}
- Average Volume (20): ${technicalData['avgVolume']?.toStringAsFixed(0)}
- Price Change: ${technicalData['priceChange']?.toStringAsFixed(2)} (${technicalData['percentChange']?.toStringAsFixed(2)}%)
- Support Level: \$${technicalData['support']?.toStringAsFixed(2)}
- Resistance Level: \$${technicalData['resistance']?.toStringAsFixed(2)}

ANALYSIS REQUIREMENTS:
Based on the attached JSON stock data and technical indicators, generate a trading strategy that covers:

1. PRIMARY RECOMMENDATION: BUY, SELL, or HOLD
2. CONFIDENCE LEVEL: 0.0 to 1.0 based on technical signal strength
3. ENTRY STRATEGY: Optimal price levels for entry
4. RISK MANAGEMENT: Stop loss levels
5. PROFIT TARGETS: Take profit levels
6. TIME HORIZONS: 
   - Short-term (1-7 days)
   - Medium-term (1-4 weeks) 
   - Long-term (1-3 months)
7. RISK ASSESSMENT: LOW, MEDIUM, or HIGH
8. DETAILED REASONING: Technical analysis explanation
9. KEY FACTORS: Critical technical signals driving the strategy

TECHNICAL ANALYSIS FOCUS:
Please analyze the attached JSON data focusing on:
- MACD signals and crossovers from the priceData
- RSI overbought/oversold conditions 
- Moving average trends and crossovers
- Volume analysis and confirmation patterns
- Support and resistance levels from price history
- Price action patterns in the historical data

DATA STRUCTURE REFERENCE:
The attached JSON contains:
- symbol: Stock ticker
- currentPrice: Latest closing price
- technicalIndicators: Calculated MACD, RSI, SMA values
- priceData: Array of historical OHLCV data with timestamps

Please respond in the following JSON format:
{
  "recommendation": "BUY/SELL/HOLD",
  "confidence": 0.0-1.0,
  "entryPoint": price_value,
  "stopLoss": price_value,
  "takeProfit": price_value,
  "durationDays": number_of_days,
  "riskLevel": "LOW/MEDIUM/HIGH",
  "reasoning": "Detailed technical analysis explanation covering MACD, RSI, moving averages, volume, and price action",
  "keyFactors": [
    "MACD signal analysis",
    "RSI condition assessment", 
    "Moving average trend",
    "Volume confirmation",
    "Support/resistance levels"
  ],
  "timeHorizons": {
    "shortTerm": "1-7 day outlook based on technical signals",
    "mediumTerm": "1-4 week outlook based on trend analysis", 
    "longTerm": "1-3 month outlook based on overall technical picture"
  }
}

Consider when analyzing the attached JSON data:
- MACD histogram direction and signal line crossovers from technicalIndicators
- RSI divergences and extreme readings from current RSI values
- Moving average slopes and crossovers using SMA 20/50 data
- Volume spikes and confirmation patterns from priceData volume array
- Break of key support/resistance levels using historical price ranges
- Overall technical momentum and trend strength from price history patterns
- Timestamp progression in priceData for trend validation
''';
  }

  TradingStrategy _parseTechnicalStrategyFromResponse(
      String responseText, double currentPrice) {
    try {
      // Extract JSON from response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        return _generateTechnicalFallbackStrategy(currentPrice);
      }

      final jsonString = responseText.substring(jsonStart, jsonEnd);
      final Map<String, dynamic> json = jsonDecode(jsonString);

      return TradingStrategy.fromJson(json);
    } catch (e) {
      print('Error parsing technical AI response: $e');
      return _generateTechnicalFallbackStrategy(currentPrice);
    }
  }

  TradingStrategy _generateTechnicalFallbackStrategy(double currentPrice) {
    return TradingStrategy(
      recommendation: 'HOLD',
      confidence: 0.5,
      entryPoint: currentPrice,
      stopLoss: currentPrice * 0.95,
      takeProfit: currentPrice * 1.10,
      durationDays: 7,
      reasoning:
          'Fallback technical analysis - insufficient data for detailed AI analysis.',
      riskLevel: 'MEDIUM',
      keyFactors: [
        'Limited technical data available',
        'Default risk management applied',
        'Conservative approach recommended',
      ],
    );
  }

  /// Analyzes a stock pattern and generates trading strategy
  Future<TradingStrategy?> analyzePatternForStrategy({
    required PatternMatch pattern,
    required List<StockData> stockHistory,
    double? currentPrice,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first unless force refresh is requested
      if (!forceRefresh) {
        final cachedStrategy =
            await AiResponseCacheService.instance.getCachedStrategy(pattern.id);
        if (cachedStrategy != null) {
          return cachedStrategy;
        }
      }

      final systemMessage =
          _generateSystemMessage(pattern, stockHistory, currentPrice);
      final prompt = [Content.text(systemMessage)];
      final response = await _model.generateContent(prompt);

      if (response.text == null) return null;

      // Parse the AI response and extract trading strategy
      final fallbackPrice = currentPrice ??
          (stockHistory.isNotEmpty
              ? stockHistory.last.close
              : (pattern.priceTarget ?? 100.0));
      final strategy =
          _parseStrategyFromResponse(response.text!, pattern, fallbackPrice);

      // Cache the successful response
      await AiResponseCacheService.instance.cacheStrategy(pattern.id, strategy);

      return strategy;
    } catch (e) {
      print('Error analyzing pattern: $e');
      return null;
    }
  }

  String _generateSystemMessage(PatternMatch pattern,
      List<StockData> stockHistory, double? currentPrice) {
    // Handle case where we don't have stock history data
    final hasStockData = stockHistory.isNotEmpty;
    final currentPriceValue = currentPrice ??
        (hasStockData
            ? stockHistory.last.close
            : (pattern.priceTarget ?? 100.0));

    String priceDataSection;
    if (hasStockData) {
      final recentPrices = stockHistory.take(20).map((s) => s.close).toList();
      final priceRange =
          '${recentPrices.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} - ${recentPrices.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}';
      priceDataSection = '''
- Current Price: \$${currentPriceValue.toStringAsFixed(2)}
- Recent Price Range (20 periods): \$${priceRange}

RECENT PRICE DATA (Last 20 periods):
${recentPrices.asMap().entries.map((e) => '${e.key + 1}. \$${e.value.toStringAsFixed(2)}').join('\n')}''';
    } else {
      priceDataSection = '''
- Reference Price: \$${currentPriceValue.toStringAsFixed(2)}
- Note: Analysis based on pattern data only, no recent price history available''';
    }

    final priceTargetText = pattern.priceTarget != null
        ? '\$${pattern.priceTarget!.toStringAsFixed(2)}'
        : 'Not specified';
    return '''
You are an expert technical analyst and trading strategist. Analyze the following stock pattern and provide a detailed trading strategy.

STOCK INFORMATION:
- Symbol: ${pattern.symbol}
$priceDataSection

PATTERN ANALYSIS:
- Pattern Type: ${pattern.patternType.toString().split('.').last}
- Direction: ${pattern.direction.toString().split('.').last}
- Confidence Score: ${(pattern.matchScore * 100).toStringAsFixed(1)}%
- Pattern Duration: ${pattern.endTime.difference(pattern.startTime).inDays} days
- Detected: ${pattern.detectedAt.toString()}
- Pattern Start: ${pattern.startTime.toString()}
- Pattern End: ${pattern.endTime.toString()}
- Price Target: $priceTargetText
- Description: ${pattern.description}

ANALYSIS REQUIREMENTS:
Based on this pattern and price data, provide a comprehensive trading strategy with the following components:

1. RECOMMENDATION: BUY, SELL, or HOLD
2. CONFIDENCE: Your confidence level (0.0 to 1.0)
3. ENTRY POINT: Optimal price to enter the trade
4. STOP LOSS: Risk management exit price
5. TAKE PROFIT: Target profit-taking price
6. DURATION: Expected holding period in days
7. RISK LEVEL: LOW, MEDIUM, or HIGH
8. REASONING: Detailed explanation of your analysis
9. KEY FACTORS: List of critical factors influencing this strategy

Please respond in the following JSON format:
{
  "recommendation": "BUY/SELL/HOLD",
  "confidence": 0.0-1.0,
  "entryPoint": price_value,
  "stopLoss": price_value,
  "takeProfit": price_value,
  "durationDays": number_of_days,
  "riskLevel": "LOW/MEDIUM/HIGH",
  "reasoning": "Detailed explanation of analysis and strategy",
  "keyFactors": ["factor1", "factor2", "factor3"]
}

Consider:
- Pattern reliability and historical success rate
- Current market conditions
- Risk-reward ratio (minimum 1:2)
- Volume patterns if available
- Support and resistance levels
- Market volatility
- Position sizing recommendations
''';
  }

  TradingStrategy _parseStrategyFromResponse(
      String responseText, PatternMatch pattern, double currentPrice) {
    try {
      // Extract JSON from response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        return _generateFallbackStrategy(pattern, currentPrice);
      }

      final jsonString = responseText.substring(jsonStart, jsonEnd);
      final Map<String, dynamic> json = jsonDecode(jsonString);

      return TradingStrategy.fromJson(json);
    } catch (e) {
      print('Error parsing AI response: $e');
      return _generateFallbackStrategy(pattern, currentPrice);
    }
  }

  TradingStrategy _generateFallbackStrategy(
      PatternMatch pattern, double currentPrice) {
    // Generate a basic strategy based on pattern type and direction
    String recommendation = 'HOLD';
    double entryPoint = currentPrice;
    double stopLoss = currentPrice * 0.95;
    double takeProfit = currentPrice * 1.10;

    if (pattern.direction == PatternDirection.bullish) {
      recommendation = 'BUY';
      takeProfit = pattern.priceTarget ?? currentPrice * 1.15;
      stopLoss = currentPrice * 0.92;
    } else if (pattern.direction == PatternDirection.bearish) {
      recommendation = 'SELL';
      entryPoint = currentPrice * 0.98;
      takeProfit = currentPrice * 0.85;
      stopLoss = currentPrice * 1.08;
    }

    return TradingStrategy(
      recommendation: recommendation,
      confidence: pattern.matchScore * 0.8, // Reduce confidence for fallback
      entryPoint: entryPoint,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      durationDays: 7,
      reasoning:
          'Automated analysis based on ${pattern.patternType.toString().split('.').last} pattern with ${pattern.direction.toString().split('.').last} direction.',
      riskLevel: pattern.matchScore > 0.8 ? 'MEDIUM' : 'HIGH',
      keyFactors: [
        'Pattern confidence: ${(pattern.matchScore * 100).toStringAsFixed(1)}%',
        'Pattern type: ${pattern.patternType.toString().split('.').last}',
        'Direction: ${pattern.direction.toString().split('.').last}',
      ],
    );
  }
}
