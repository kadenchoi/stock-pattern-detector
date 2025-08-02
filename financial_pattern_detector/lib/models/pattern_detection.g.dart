// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pattern_detection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatternMatch _$PatternMatchFromJson(Map<String, dynamic> json) => PatternMatch(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      patternType: $enumDecode(_$PatternTypeEnumMap, json['patternType']),
      direction: $enumDecode(_$PatternDirectionEnumMap, json['direction']),
      matchScore: (json['matchScore'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      priceTarget: (json['priceTarget'] as num?)?.toDouble(),
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$PatternMatchToJson(PatternMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'patternType': _$PatternTypeEnumMap[instance.patternType]!,
      'direction': _$PatternDirectionEnumMap[instance.direction]!,
      'matchScore': instance.matchScore,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'priceTarget': instance.priceTarget,
      'description': instance.description,
      'metadata': instance.metadata,
    };

const _$PatternTypeEnumMap = {
  PatternType.headAndShoulders: 'headAndShoulders',
  PatternType.cupAndHandle: 'cupAndHandle',
  PatternType.doubleTop: 'doubleTop',
  PatternType.doubleBottom: 'doubleBottom',
  PatternType.ascendingTriangle: 'ascendingTriangle',
  PatternType.descendingTriangle: 'descendingTriangle',
  PatternType.triangle: 'triangle',
  PatternType.flag: 'flag',
  PatternType.wedge: 'wedge',
  PatternType.pennant: 'pennant',
};

const _$PatternDirectionEnumMap = {
  PatternDirection.bullish: 'bullish',
  PatternDirection.bearish: 'bearish',
  PatternDirection.breakout: 'breakout',
};
