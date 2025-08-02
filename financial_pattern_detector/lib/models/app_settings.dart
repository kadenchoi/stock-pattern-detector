import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

enum DataPeriod {
  oneMinute('1m'),
  twoMinutes('2m'),
  fiveMinutes('5m'),
  fifteenMinutes('15m'),
  thirtyMinutes('30m'),
  sixtyMinutes('60m'),
  ninetyMinutes('90m'),
  oneHour('1h'),
  oneDay('1d'),
  fiveDays('5d'),
  oneWeek('1wk'),
  oneMonth('1mo'),
  threeMonths('3mo');

  const DataPeriod(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case DataPeriod.oneMinute:
        return '1 Minute';
      case DataPeriod.twoMinutes:
        return '2 Minutes';
      case DataPeriod.fiveMinutes:
        return '5 Minutes';
      case DataPeriod.fifteenMinutes:
        return '15 Minutes';
      case DataPeriod.thirtyMinutes:
        return '30 Minutes';
      case DataPeriod.sixtyMinutes:
        return '60 Minutes';
      case DataPeriod.ninetyMinutes:
        return '90 Minutes';
      case DataPeriod.oneHour:
        return '1 Hour';
      case DataPeriod.oneDay:
        return '1 Day';
      case DataPeriod.fiveDays:
        return '5 Days';
      case DataPeriod.oneWeek:
        return '1 Week';
      case DataPeriod.oneMonth:
        return '1 Month';
      case DataPeriod.threeMonths:
        return '3 Months';
    }
  }
}

enum AlertMethod { notification, email, both }

@JsonSerializable()
class AppSettings {
  final List<String> watchlist;
  final DataPeriod trackingInterval;
  final DataPeriod dataPeriod;
  final AlertMethod alertMethod;
  final double patternMatchThreshold; // 0.0 to 1.0
  final String? emailAddress;
  final bool enableNotifications;
  final bool enableEmailAlerts;

  AppSettings({
    this.watchlist = const [],
    this.trackingInterval = DataPeriod.fifteenMinutes,
    this.dataPeriod = DataPeriod.oneDay,
    this.alertMethod = AlertMethod.notification,
    this.patternMatchThreshold = 0.7,
    this.emailAddress,
    this.enableNotifications = true,
    this.enableEmailAlerts = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    List<String>? watchlist,
    DataPeriod? trackingInterval,
    DataPeriod? dataPeriod,
    AlertMethod? alertMethod,
    double? patternMatchThreshold,
    String? emailAddress,
    bool? enableNotifications,
    bool? enableEmailAlerts,
  }) {
    return AppSettings(
      watchlist: watchlist ?? this.watchlist,
      trackingInterval: trackingInterval ?? this.trackingInterval,
      dataPeriod: dataPeriod ?? this.dataPeriod,
      alertMethod: alertMethod ?? this.alertMethod,
      patternMatchThreshold:
          patternMatchThreshold ?? this.patternMatchThreshold,
      emailAddress: emailAddress ?? this.emailAddress,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableEmailAlerts: enableEmailAlerts ?? this.enableEmailAlerts,
    );
  }
}
