import '../models/pattern_detection.dart';
import '../models/stock_data.dart';

class PatternPredictionService {
  static final PatternPredictionService instance = PatternPredictionService._();
  PatternPredictionService._();

  // Returns a copy of pattern with augmented metadata and priceTarget
  // WARNING: These are theoretical calculations based on traditional technical analysis
  // patterns and should NOT be used as actual trading signals or financial advice
  PatternMatch enrich(PatternMatch pattern, List<StockData> series) {
    final data = series;
    if (data.isEmpty) return pattern;

    // Find prices near start/end
    double priceAt(DateTime t) {
      final idx = _closestIndex(data, t);
      return data[idx].close;
    }

    final startPrice = priceAt(pattern.startTime);
    final endPrice = priceAt(pattern.endTime);
    final lastPrice = data.last.close;

    late double target;
    late double stop;
    int horizonDays = 5; // default horizon

    switch (pattern.patternType) {
      case PatternType.headAndShoulders:
        // Move ≈ head-to-neckline distance downwards
        final headHigh = pattern.metadata['headIndex'] != null
            ? data[(pattern.metadata['headIndex'] as int)
                    .clamp(0, data.length - 1)]
                .high
            : (startPrice > endPrice ? startPrice : endPrice);
        final neckline = (startPrice + endPrice) / 2;
        final height = (headHigh - neckline).abs();
        target = (pattern.direction == PatternDirection.bearish)
            ? lastPrice - height
            : lastPrice + height;
        stop = (pattern.direction == PatternDirection.bearish)
            ? lastPrice + height * 0.5
            : lastPrice - height * 0.5;
        horizonDays = 10;
        break;
      case PatternType.cupAndHandle:
        // Target ≈ depth of cup added to breakout
        final cupBottomIdx = pattern.metadata['cupBottom'] as int?;
        final cupBottom = cupBottomIdx != null &&
                cupBottomIdx >= 0 &&
                cupBottomIdx < data.length
            ? data[cupBottomIdx].low
            : (startPrice < endPrice ? startPrice : endPrice);
        final rim = (startPrice + endPrice) / 2;
        final depth = (rim - cupBottom).abs();
        target = lastPrice + depth;
        stop = lastPrice - depth * 0.5;
        horizonDays = 15;
        break;
      case PatternType.doubleTop:
      case PatternType.doubleBottom:
        // Target ≈ peak/trough distance to neckline
        final height = (endPrice - startPrice).abs();
        target = (pattern.patternType == PatternType.doubleTop)
            ? lastPrice - height
            : lastPrice + height;
        stop = (pattern.patternType == PatternType.doubleTop)
            ? lastPrice + height * 0.5
            : lastPrice - height * 0.5;
        horizonDays = 7;
        break;
      case PatternType.ascendingTriangle:
      case PatternType.descendingTriangle:
      case PatternType.triangle:
        // Target ≈ height of triangle added to breakout
        final height = (endPrice - startPrice).abs();
        final dir = pattern.direction;
        if (dir == PatternDirection.bullish) {
          target = lastPrice + height;
          stop = lastPrice - height * 0.5;
        } else if (dir == PatternDirection.bearish) {
          target = lastPrice - height;
          stop = lastPrice + height * 0.5;
        } else {
          // breakout unknown direction, set band
          target = lastPrice + height;
          stop = lastPrice - height;
        }
        horizonDays = 10;
        break;
      case PatternType.flag:
      case PatternType.wedge:
      case PatternType.pennant:
        // Measured move approx equal to flagpole height
        final height = (endPrice - startPrice).abs();
        final isBull = pattern.direction == PatternDirection.bullish ||
            endPrice >= startPrice;
        target = isBull ? lastPrice + height : lastPrice - height;
        stop = isBull ? lastPrice - height * 0.5 : lastPrice + height * 0.5;
        horizonDays = 5;
        break;
    }

    final enrichedMeta = Map<String, dynamic>.from(pattern.metadata)
      ..addAll({
        'entryPrice': lastPrice,
        'theoreticalTarget':
            target, // Changed from targetPrice to be more explicit
        'theoreticalStop': stop, // Changed from stopPrice to be more explicit
        'estimatedHorizonDays': horizonDays, // Changed to estimated
        'patternMatchScore': pattern
            .matchScore, // Clarified this is pattern matching, not prediction confidence
        'disclaimer':
            'Theoretical values for educational purposes only. Not financial advice.',
      });

    return PatternMatch(
      id: pattern.id,
      symbol: pattern.symbol,
      patternType: pattern.patternType,
      direction: pattern.direction,
      matchScore: pattern.matchScore,
      detectedAt: pattern.detectedAt,
      startTime: pattern.startTime,
      endTime: pattern.endTime,
      priceTarget:
          null, // Removed misleading price target - theoretical only in metadata
      description: '${pattern.description} (Theoretical analysis only)',
      metadata: enrichedMeta,
    );
  }

  int _closestIndex(List<StockData> data, DateTime t) {
    int lo = 0, hi = data.length - 1, best = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final dt = data[mid].timestamp.compareTo(t);
      if (dt == 0) return mid;
      if (dt < 0) {
        best = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return best;
  }
}
