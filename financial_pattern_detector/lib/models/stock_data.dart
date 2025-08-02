import 'package:json_annotation/json_annotation.dart';

part 'stock_data.g.dart';

@JsonSerializable()
class StockData {
  final String symbol;
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  StockData({
    required this.symbol,
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory StockData.fromJson(Map<String, dynamic> json) =>
      _$StockDataFromJson(json);
  Map<String, dynamic> toJson() => _$StockDataToJson(this);

  @override
  String toString() {
    return 'StockData(symbol: $symbol, timestamp: $timestamp, close: $close)';
  }
}

@JsonSerializable()
class StockDataSeries {
  final String symbol;
  final List<StockData> data;
  final DateTime lastUpdated;

  StockDataSeries({
    required this.symbol,
    required this.data,
    required this.lastUpdated,
  });

  factory StockDataSeries.fromJson(Map<String, dynamic> json) =>
      _$StockDataSeriesFromJson(json);
  Map<String, dynamic> toJson() => _$StockDataSeriesToJson(this);
}
