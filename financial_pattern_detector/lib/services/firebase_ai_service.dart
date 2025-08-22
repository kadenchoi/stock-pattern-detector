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
    // Implement technical analysis logic here
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
