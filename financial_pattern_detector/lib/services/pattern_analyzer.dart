import 'dart:math';
import '../models/stock_data.dart';
import '../models/pattern_detection.dart';

class PatternAnalyzer {
  static const double _defaultMinConfidence = 0.75;

  /// Analyzes stock data series for all supported patterns
  Future<List<PatternMatch>> analyzePatterns(
    StockDataSeries stockSeries, {
    double minConfidence = _defaultMinConfidence,
  }) async {
    final patterns = <PatternMatch>[];

    if (stockSeries.data.length < 10) {
      return patterns; // Need sufficient data points
    }

    // Analyze each pattern type
    patterns.addAll(await _detectHeadAndShoulders(stockSeries, minConfidence));
    patterns.addAll(await _detectCupAndHandle(stockSeries, minConfidence));
    patterns.addAll(await _detectDoubleTopBottom(stockSeries, minConfidence));
    patterns.addAll(await _detectTrianglePatterns(stockSeries, minConfidence));
    patterns.addAll(await _detectFlagPatterns(stockSeries, minConfidence));

    // Remove overlapping patterns of the same type
    final mergedPatterns = _mergeOverlappingPatterns(patterns);

    // Filter out low confidence duplicates
    final highQualityPatterns = _filterLowConfidenceDuplicates(mergedPatterns);

    // Apply volatility and volume refinement to reduce false positives
    final refined =
        _refineByVolatilityAndVolume(stockSeries, highQualityPatterns);

    // Sort by confidence score descending
    refined.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return refined;
  }

  List<PatternMatch> _refineByVolatilityAndVolume(
      StockDataSeries stockSeries, List<PatternMatch> patterns) {
    if (stockSeries.data.isEmpty || patterns.isEmpty) return patterns;
    final data = stockSeries.data;

    double avgTrueRange(int start, int end) {
      start = start.clamp(0, data.length - 1);
      end = end.clamp(0, data.length - 1);
      if (end <= start) return 0;
      double sum = 0;
      for (int i = start + 1; i <= end; i++) {
        final high = data[i].high;
        final low = data[i].low;
        final prevClose = data[i - 1].close;
        final tr = [
          high - low,
          (high - prevClose).abs(),
          (low - prevClose).abs(),
        ].reduce((a, b) => a > b ? a : b);
        sum += tr;
      }
      return sum / (end - start);
    }

    double medianVolume(int start, int end) {
      start = start.clamp(0, data.length - 1);
      end = end.clamp(0, data.length - 1);
      if (end < start) return 0;
      final vols = [
        for (int i = start; i <= end; i++) data[i].volume.toDouble()
      ]..sort();
      final mid = vols.length ~/ 2;
      if (vols.isEmpty) return 0;
      return vols.length.isOdd ? vols[mid] : (vols[mid - 1] + vols[mid]) / 2.0;
    }

    int indexOfTime(DateTime t) {
      // Binary search for closest index
      int lo = 0, hi = data.length - 1, best = 0;
      while (lo <= hi) {
        final mid = (lo + hi) >> 1;
        final cmp = data[mid].timestamp.compareTo(t);
        if (cmp == 0) return mid;
        if (cmp < 0) {
          best = mid;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
      return best;
    }

    final refined = <PatternMatch>[];
    for (final p in patterns) {
      final sIdx = indexOfTime(p.startTime);
      final eIdx = indexOfTime(p.endTime);
      final windowAtr = avgTrueRange(sIdx, eIdx);
      final move = (data[eIdx].close - data[sIdx].close).abs();
      final volMed = medianVolume(sIdx, eIdx);
      final endVol = data[eIdx].volume.toDouble();

      // Basic gates: move should exceed 1.2x ATR over window, and end volume not dry-up
      final passVolatility = windowAtr == 0 ? true : (move / windowAtr) >= 1.2;
      final passVolume = volMed == 0 ? true : (endVol >= 0.8 * volMed);

      if (passVolatility && passVolume) {
        refined.add(p);
      }
    }

    return refined;
  }

  Future<List<PatternMatch>> _detectHeadAndShoulders(
    StockDataSeries stockSeries,
    double minConfidence,
  ) async {
    final patterns = <PatternMatch>[];
    final data = stockSeries.data;

    // Need at least 20 data points for head and shoulders
    if (data.length < 20) return patterns;

    // Use adaptive step sizes to reduce overlapping detections
    for (int i = 5; i < data.length - 10; i += _adaptiveStep(data, i)) {
      final leftShoulder = _findLocalMaximum(data, i - 5, i);
      final head = _findLocalMaximum(data, i, i + 5);
      final rightShoulder = _findLocalMaximum(
        data,
        i + 5,
        min(i + 10, data.length - 1),
      );

      if (leftShoulder == null || head == null || rightShoulder == null)
        continue;

      // Check if it's a valid head and shoulders pattern
      final confidence = _calculateHeadAndShouldersConfidence(
        data[leftShoulder],
        data[head],
        data[rightShoulder],
      );

      if (confidence >= minConfidence) {
        patterns.add(
          PatternMatch(
            id: _generatePatternId(),
            symbol: stockSeries.symbol,
            patternType: PatternType.headAndShoulders,
            direction: PatternDirection.bearish,
            matchScore: confidence,
            detectedAt: DateTime.now(),
            startTime: data[leftShoulder].timestamp,
            endTime: data[rightShoulder].timestamp,
            description:
                'Head and Shoulders pattern detected - bearish reversal signal',
            metadata: {
              'leftShoulderIndex': leftShoulder,
              'headIndex': head,
              'rightShoulderIndex': rightShoulder,
            },
          ),
        );
      }
    }

    return patterns;
  }

  Future<List<PatternMatch>> _detectCupAndHandle(
    StockDataSeries stockSeries,
    double minConfidence,
  ) async {
    final patterns = <PatternMatch>[];
    final data = stockSeries.data;

    if (data.length < 30) return patterns;

    // Use adaptive step sizes to reduce overlapping detections
    for (int i = 10; i < data.length - 15; i += _adaptiveStep(data, i)) {
      final cupStart = i - 10;
      final cupBottom = _findLocalMinimum(data, i - 5, i + 5);
      final cupEnd = i + 10;

      if (cupBottom == null) continue;

      // Look for handle formation after cup
      final handleStart = cupEnd;
      final handleEnd = min(handleStart + 5, data.length - 1);

      if (handleEnd >= data.length) continue;

      final confidence = _calculateCupAndHandleConfidence(
        data,
        cupStart,
        cupBottom,
        cupEnd,
        handleStart,
        handleEnd,
      );

      if (confidence >= minConfidence) {
        patterns.add(
          PatternMatch(
            id: _generatePatternId(),
            symbol: stockSeries.symbol,
            patternType: PatternType.cupAndHandle,
            direction: PatternDirection.bullish,
            matchScore: confidence,
            detectedAt: DateTime.now(),
            startTime: data[cupStart].timestamp,
            endTime: data[handleEnd].timestamp,
            description:
                'Cup and Handle pattern detected - bullish continuation signal',
            metadata: {
              'cupStart': cupStart,
              'cupBottom': cupBottom,
              'cupEnd': cupEnd,
              'handleStart': handleStart,
              'handleEnd': handleEnd,
            },
          ),
        );
      }
    }

    return patterns;
  }

  Future<List<PatternMatch>> _detectDoubleTopBottom(
    StockDataSeries stockSeries,
    double minConfidence,
  ) async {
    final patterns = <PatternMatch>[];
    final data = stockSeries.data;

    if (data.length < 20) return patterns;

    // Detect double tops (bearish) - use adaptive steps
    for (int i = 5; i < data.length - 10; i += _adaptiveStep(data, i)) {
      final firstPeak = _findLocalMaximum(data, i - 5, i);
      final valley = _findLocalMinimum(data, i, i + 5);
      final secondPeak = _findLocalMaximum(
        data,
        i + 5,
        min(i + 10, data.length - 1),
      );

      if (firstPeak == null || valley == null || secondPeak == null) continue;

      final confidence = _calculateDoubleTopConfidence(
        data[firstPeak],
        data[valley],
        data[secondPeak],
      );

      if (confidence >= minConfidence) {
        patterns.add(
          PatternMatch(
            id: _generatePatternId(),
            symbol: stockSeries.symbol,
            patternType: PatternType.doubleTop,
            direction: PatternDirection.bearish,
            matchScore: confidence,
            detectedAt: DateTime.now(),
            startTime: data[firstPeak].timestamp,
            endTime: data[secondPeak].timestamp,
            description:
                'Double Top pattern detected - bearish reversal signal',
          ),
        );
      }
    }

    // Detect double bottoms (bullish) - use adaptive steps
    for (int i = 5; i < data.length - 10; i += _adaptiveStep(data, i)) {
      final firstTrough = _findLocalMinimum(data, i - 5, i);
      final peak = _findLocalMaximum(data, i, i + 5);
      final secondTrough = _findLocalMinimum(
        data,
        i + 5,
        min(i + 10, data.length - 1),
      );

      if (firstTrough == null || peak == null || secondTrough == null) continue;

      final confidence = _calculateDoubleBottomConfidence(
        data[firstTrough],
        data[peak],
        data[secondTrough],
      );

      if (confidence >= minConfidence) {
        patterns.add(
          PatternMatch(
            id: _generatePatternId(),
            symbol: stockSeries.symbol,
            patternType: PatternType.doubleBottom,
            direction: PatternDirection.bullish,
            matchScore: confidence,
            detectedAt: DateTime.now(),
            startTime: data[firstTrough].timestamp,
            endTime: data[secondTrough].timestamp,
            description:
                'Double Bottom pattern detected - bullish reversal signal',
          ),
        );
      }
    }

    return patterns;
  }

  Future<List<PatternMatch>> _detectTrianglePatterns(
    StockDataSeries stockSeries,
    double minConfidence,
  ) async {
    final patterns = <PatternMatch>[];
    final data = stockSeries.data;

    if (data.length < 15) return patterns;

    // Use adaptive step sizes to reduce overlapping detections
    for (int i = 7; i < data.length - 7; i += _adaptiveStep(data, i)) {
      final startIdx = i - 7;
      final endIdx = i + 7;

      final trendLines = _calculateTrendLines(data, startIdx, endIdx);
      if (trendLines == null) continue;

      final confidence = _calculateTriangleConfidence(trendLines);

      if (confidence >= minConfidence) {
        PatternType patternType;
        PatternDirection direction;

        if (trendLines['upperSlope']! > 0 && trendLines['lowerSlope']! > 0) {
          patternType = PatternType.ascendingTriangle;
          direction = PatternDirection.bullish;
        } else if (trendLines['upperSlope']! < 0 &&
            trendLines['lowerSlope']! < 0) {
          patternType = PatternType.descendingTriangle;
          direction = PatternDirection.bearish;
        } else {
          patternType = PatternType.triangle;
          direction = PatternDirection.breakout;
        }

        patterns.add(
          PatternMatch(
            id: _generatePatternId(),
            symbol: stockSeries.symbol,
            patternType: patternType,
            direction: direction,
            matchScore: confidence,
            detectedAt: DateTime.now(),
            startTime: data[startIdx].timestamp,
            endTime: data[endIdx].timestamp,
            description: '${patternType.name} pattern detected',
            metadata: trendLines,
          ),
        );
      }
    }

    return patterns;
  }

  Future<List<PatternMatch>> _detectFlagPatterns(
    StockDataSeries stockSeries,
    double minConfidence,
  ) async {
    final patterns = <PatternMatch>[];
    final data = stockSeries.data;

    if (data.length < 10) return patterns;

    // Use adaptive step sizes to reduce overlapping detections
    for (int i = 5; i < data.length - 5; i += _adaptiveStep(data, i)) {
      final confidence = _calculateFlagConfidence(data, i - 5, i + 5);

      if (confidence >= minConfidence) {
        patterns.add(
          PatternMatch(
            id: _generatePatternId(),
            symbol: stockSeries.symbol,
            patternType: PatternType.flag,
            direction: PatternDirection.breakout,
            matchScore: confidence,
            detectedAt: DateTime.now(),
            startTime: data[i - 5].timestamp,
            endTime: data[i + 5].timestamp,
            description: 'Flag pattern detected - continuation signal',
          ),
        );
      }
    }

    return patterns;
  }

  int? _findLocalMaximum(List<StockData> data, int start, int end) {
    if (start < 0 || end >= data.length || start >= end) return null;

    int maxIdx = start;
    for (int i = start + 1; i <= end; i++) {
      if (data[i].high > data[maxIdx].high) {
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  int? _findLocalMinimum(List<StockData> data, int start, int end) {
    if (start < 0 || end >= data.length || start >= end) return null;

    int minIdx = start;
    for (int i = start + 1; i <= end; i++) {
      if (data[i].low < data[minIdx].low) {
        minIdx = i;
      }
    }
    return minIdx;
  }

  double _calculateHeadAndShouldersConfidence(
    StockData leftShoulder,
    StockData head,
    StockData rightShoulder,
  ) {
    // Head should be higher than both shoulders
    if (head.high <= leftShoulder.high || head.high <= rightShoulder.high) {
      return 0.0;
    }

    final shoulderDiff = (leftShoulder.high - rightShoulder.high).abs();
    final avgShoulderHeight = (leftShoulder.high + rightShoulder.high) / 2;
    final headHeight = head.high - avgShoulderHeight;

    // Head must be distinct enough - at least 5% higher than average shoulder
    if (headHeight < avgShoulderHeight * 0.05) return 0.0;

    final symmetryScore =
        1.0 - (shoulderDiff / avgShoulderHeight).clamp(0.0, 1.0);
    final prominenceScore = (headHeight / avgShoulderHeight).clamp(0.0, 1.0);

    return (symmetryScore * 0.5 + prominenceScore * 0.5).clamp(0.0, 1.0);
  }

  double _calculateCupAndHandleConfidence(
    List<StockData> data,
    int cupStart,
    int cupBottom,
    int cupEnd,
    int handleStart,
    int handleEnd,
  ) {
    if (cupStart >= data.length ||
        cupEnd >= data.length ||
        handleEnd >= data.length ||
        cupBottom >= data.length) {
      return 0.0;
    }

    // Check cup formation (U-shaped)
    final cupStartPrice = data[cupStart].close;
    final cupEndPrice = data[cupEnd].close;
    final cupBottomPrice = data[cupBottom].close;

    // Cup rims should be roughly equal
    final rimDiff = (cupStartPrice - cupEndPrice).abs();
    final cupDepth = max(cupStartPrice, cupEndPrice) - cupBottomPrice;

    if (cupDepth <= 0) return 0.0;

    final cupSymmetry = 1.0 - (rimDiff / cupDepth).clamp(0.0, 1.0);

    // Handle should be smaller consolidation
    final handleDepth = data[handleStart].close - data[handleEnd].close;
    final handleQuality = (handleDepth / cupDepth).clamp(0.0, 0.5) * 2;

    return (cupSymmetry * 0.7 + handleQuality * 0.3).clamp(0.0, 1.0);
  }

  double _calculateDoubleTopConfidence(
    StockData firstPeak,
    StockData valley,
    StockData secondPeak,
  ) {
    // Peaks should be roughly similar heights
    final peakDiff = (firstPeak.high - secondPeak.high).abs();
    final avgPeak = (firstPeak.high + secondPeak.high) / 2;

    if (avgPeak <= valley.low) return 0.0;

    final peakSimilarity = 1.0 - (peakDiff / avgPeak).clamp(0.0, 1.0);

    // Valley should be significantly lower
    final valleyDepth = avgPeak - valley.low;
    final depthRatio = (valleyDepth / avgPeak).clamp(0.0, 1.0);

    return (peakSimilarity * 0.6 + depthRatio * 0.4).clamp(0.0, 1.0);
  }

  double _calculateDoubleBottomConfidence(
    StockData firstTrough,
    StockData peak,
    StockData secondTrough,
  ) {
    // Troughs should be roughly similar depths
    final troughDiff = (firstTrough.low - secondTrough.low).abs();
    final avgTrough = (firstTrough.low + secondTrough.low) / 2;

    if (peak.high <= avgTrough) return 0.0;

    final troughSimilarity = 1.0 - (troughDiff / avgTrough).clamp(0.0, 1.0);

    // Peak should be significantly higher
    final peakHeight = peak.high - avgTrough;
    final heightRatio = (peakHeight / peak.high).clamp(0.0, 1.0);

    return (troughSimilarity * 0.6 + heightRatio * 0.4).clamp(0.0, 1.0);
  }

  Map<String, double>? _calculateTrendLines(
    List<StockData> data,
    int start,
    int end,
  ) {
    if (start >= end || start < 0 || end >= data.length) return null;

    // Simple linear regression for upper and lower trend lines
    final highs = <double>[];
    final lows = <double>[];

    for (int i = start; i <= end; i++) {
      highs.add(data[i].high);
      lows.add(data[i].low);
    }

    final upperSlope = _calculateSlope(highs);
    final lowerSlope = _calculateSlope(lows);

    return {'upperSlope': upperSlope, 'lowerSlope': lowerSlope};
  }

  double _calculateSlope(List<double> values) {
    if (values.length < 2) return 0.0;

    final n = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumXX += i * i;
    }

    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }

  double _calculateTriangleConfidence(Map<String, double> trendLines) {
    final upperSlope = trendLines['upperSlope']!;
    final lowerSlope = trendLines['lowerSlope']!;

    // Lines should be converging
    final convergence = (upperSlope - lowerSlope).abs();
    final convergenceScore = (1.0 - convergence.clamp(0.0, 1.0));

    // Additional validation: slopes should have reasonable magnitude
    final slopeValidation =
        (upperSlope.abs() > 0.001 && lowerSlope.abs() > 0.001) ? 1.0 : 0.5;

    return (convergenceScore * slopeValidation).clamp(0.0, 0.95);
  }

  double _calculateFlagConfidence(List<StockData> data, int start, int end) {
    if (start >= end || start < 0 || end >= data.length) return 0.0;

    // Look for consolidation after strong move
    final preTrendStart = max(0, start - 10);
    final preTrendMove = data[start].close - data[preTrendStart].close;

    // Need significant prior move (at least 3% price movement)
    if (preTrendMove.abs() < data[start].close * 0.03) return 0.0;

    // Flag should be smaller consolidation
    final flagRange = data.sublist(start, end + 1);
    final flagHigh = flagRange.map((d) => d.high).reduce(max);
    final flagLow = flagRange.map((d) => d.low).reduce(min);
    final flagSize = flagHigh - flagLow;

    final consolidationRatio = (flagSize / preTrendMove.abs()).clamp(0.0, 1.0);

    // Flag consolidation should be small relative to the prior move
    final consolidationScore = (1.0 - consolidationRatio);

    // Additional validation: flag duration should be reasonable
    final durationScore = (end - start) >= 3 ? 1.0 : 0.7;

    return (consolidationScore * durationScore).clamp(0.0, 0.9);
  }

  String _generatePatternId() {
    return 'pattern_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Merges overlapping patterns of the same type to avoid duplicate detections
  List<PatternMatch> _mergeOverlappingPatterns(List<PatternMatch> patterns) {
    if (patterns.length <= 1) return patterns;

    // Group patterns by type and symbol
    final groupedPatterns = <String, List<PatternMatch>>{};

    for (final pattern in patterns) {
      final key = '${pattern.symbol}_${pattern.patternType.name}';
      groupedPatterns.putIfAbsent(key, () => []).add(pattern);
    }

    final mergedPatterns = <PatternMatch>[];

    // Process each group separately
    for (final group in groupedPatterns.values) {
      if (group.length == 1) {
        mergedPatterns.addAll(group);
        continue;
      }

      // Sort by start time
      group.sort((a, b) => a.startTime.compareTo(b.startTime));

      final merged = <PatternMatch>[];
      PatternMatch? currentPattern = group.first;

      for (int i = 1; i < group.length; i++) {
        final nextPattern = group[i];

        // Check if patterns overlap significantly (more than 50% overlap)
        if (_patternsOverlap(currentPattern!, nextPattern)) {
          // Merge the patterns - keep the one with higher confidence
          // and extend the time range to cover both patterns
          currentPattern = _mergePatterns(currentPattern, nextPattern);
        } else {
          // No overlap, add current pattern and move to next
          merged.add(currentPattern);
          currentPattern = nextPattern;
        }
      }

      // Add the last pattern
      if (currentPattern != null) {
        merged.add(currentPattern);
      }

      mergedPatterns.addAll(merged);
    }

    return mergedPatterns;
  }

  /// Checks if two patterns overlap significantly in time
  bool _patternsOverlap(PatternMatch pattern1, PatternMatch pattern2) {
    final start1 = pattern1.startTime.millisecondsSinceEpoch;
    final end1 = pattern1.endTime.millisecondsSinceEpoch;
    final start2 = pattern2.startTime.millisecondsSinceEpoch;
    final end2 = pattern2.endTime.millisecondsSinceEpoch;

    // Calculate overlap
    final overlapStart = max(start1, start2);
    final overlapEnd = min(end1, end2);

    if (overlapStart >= overlapEnd) return false; // No overlap

    final overlapDuration = overlapEnd - overlapStart;
    final pattern1Duration = end1 - start1;
    final pattern2Duration = end2 - start2;

    // Check if overlap is more than 50% of either pattern
    final overlapRatio1 = overlapDuration / pattern1Duration;
    final overlapRatio2 = overlapDuration / pattern2Duration;

    return overlapRatio1 > 0.5 || overlapRatio2 > 0.5;
  }

  /// Merges two overlapping patterns into one
  PatternMatch _mergePatterns(PatternMatch pattern1, PatternMatch pattern2) {
    // Keep the pattern with higher confidence
    final basePattern =
        pattern1.matchScore >= pattern2.matchScore ? pattern1 : pattern2;

    // Extend time range to cover both patterns
    final earliestStart = pattern1.startTime.isBefore(pattern2.startTime)
        ? pattern1.startTime
        : pattern2.startTime;
    final latestEnd = pattern1.endTime.isAfter(pattern2.endTime)
        ? pattern1.endTime
        : pattern2.endTime;

    // Take the higher confidence score
    final maxConfidence = max(pattern1.matchScore, pattern2.matchScore);

    return PatternMatch(
      id: basePattern.id,
      symbol: basePattern.symbol,
      patternType: basePattern.patternType,
      direction: basePattern.direction,
      matchScore: maxConfidence,
      detectedAt: basePattern.detectedAt,
      startTime: earliestStart,
      endTime: latestEnd,
      description:
          '${basePattern.patternType.name} pattern detected (merged from overlapping detections)',
      metadata: basePattern.metadata,
    );
  }

  /// Filters out low confidence duplicates and overlapping patterns
  List<PatternMatch> _filterLowConfidenceDuplicates(
    List<PatternMatch> patterns, {
    double threshold = 0.75,
  }) {
    final filtered = <PatternMatch>[];

    patterns.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    for (final p in patterns) {
      if (filtered.any((f) =>
          f.patternType == p.patternType &&
          _patternsOverlap(f, p) &&
          f.matchScore >= p.matchScore)) {
        continue;
      }
      if (p.matchScore >= threshold) filtered.add(p);
    }
    return filtered;
  }

  /// Calculate adaptive step size based on price volatility
  int _adaptiveStep(List<StockData> data, int index) {
    if (index >= data.length) return 3;

    final volatility = (data[index].high - data[index].low) / data[index].close;
    if (volatility > 0.05) return 2; // High volatility = tighter check
    if (volatility > 0.02) return 3;
    return 4; // Low volatility = broader steps
  }
}
