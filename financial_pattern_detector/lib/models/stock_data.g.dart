// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockData _$StockDataFromJson(Map<String, dynamic> json) => StockData(
      symbol: json['symbol'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toInt(),
    );

Map<String, dynamic> _$StockDataToJson(StockData instance) => <String, dynamic>{
      'symbol': instance.symbol,
      'timestamp': instance.timestamp.toIso8601String(),
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'close': instance.close,
      'volume': instance.volume,
    };

StockDataSeries _$StockDataSeriesFromJson(Map<String, dynamic> json) =>
    StockDataSeries(
      symbol: json['symbol'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => StockData.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$StockDataSeriesToJson(StockDataSeries instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'data': instance.data,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
