import 'package:json_annotation/json_annotation.dart';

part 'pattern_detection.g.dart';

enum PatternType {
  headAndShoulders,
  cupAndHandle,
  doubleTop,
  doubleBottom,
  ascendingTriangle,
  descendingTriangle,
  triangle,
  flag,
  wedge,
  pennant,
}

enum PatternDirection { bullish, bearish, breakout }

@JsonSerializable()
class PatternMatch {
  final String id;
  final String symbol;
  final PatternType patternType;
  final PatternDirection direction;
  final double matchScore; // 0.0 to 1.0
  final DateTime detectedAt;
  final DateTime startTime;
  final DateTime endTime;
  final double? priceTarget;
  final String description;
  final Map<String, dynamic> metadata;

  PatternMatch({
    required this.id,
    required this.symbol,
    required this.patternType,
    required this.direction,
    required this.matchScore,
    required this.detectedAt,
    required this.startTime,
    required this.endTime,
    this.priceTarget,
    required this.description,
    this.metadata = const {},
  });

  factory PatternMatch.fromJson(Map<String, dynamic> json) =>
      _$PatternMatchFromJson(json);
  Map<String, dynamic> toJson() => _$PatternMatchToJson(this);

  String get directionEmoji {
    switch (direction) {
      case PatternDirection.bullish:
        return '⬆️';
      case PatternDirection.bearish:
        return '⬇️';
      case PatternDirection.breakout:
        return '🔥';
    }
  }

  String get patternName {
    switch (patternType) {
      case PatternType.headAndShoulders:
        return 'Head and Shoulders';
      case PatternType.cupAndHandle:
        return 'Cup and Handle';
      case PatternType.doubleTop:
        return 'Double Top';
      case PatternType.doubleBottom:
        return 'Double Bottom';
      case PatternType.ascendingTriangle:
        return 'Ascending Triangle';
      case PatternType.descendingTriangle:
        return 'Descending Triangle';
      case PatternType.triangle:
        return 'Triangle';
      case PatternType.flag:
        return 'Flag';
      case PatternType.wedge:
        return 'Wedge';
      case PatternType.pennant:
        return 'Pennant';
    }
  }

  double get matchPercentage => matchScore * 100;
}
