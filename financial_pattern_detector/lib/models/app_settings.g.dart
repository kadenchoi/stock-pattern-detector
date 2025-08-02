// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
      watchlist: (json['watchlist'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      trackingInterval:
          $enumDecodeNullable(_$DataPeriodEnumMap, json['trackingInterval']) ??
              DataPeriod.fifteenMinutes,
      dataPeriod:
          $enumDecodeNullable(_$DataPeriodEnumMap, json['dataPeriod']) ??
              DataPeriod.oneDay,
      alertMethod:
          $enumDecodeNullable(_$AlertMethodEnumMap, json['alertMethod']) ??
              AlertMethod.notification,
      patternMatchThreshold:
          (json['patternMatchThreshold'] as num?)?.toDouble() ?? 0.7,
      emailAddress: json['emailAddress'] as String?,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableEmailAlerts: json['enableEmailAlerts'] as bool? ?? false,
    );

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'watchlist': instance.watchlist,
      'trackingInterval': _$DataPeriodEnumMap[instance.trackingInterval]!,
      'dataPeriod': _$DataPeriodEnumMap[instance.dataPeriod]!,
      'alertMethod': _$AlertMethodEnumMap[instance.alertMethod]!,
      'patternMatchThreshold': instance.patternMatchThreshold,
      'emailAddress': instance.emailAddress,
      'enableNotifications': instance.enableNotifications,
      'enableEmailAlerts': instance.enableEmailAlerts,
    };

const _$DataPeriodEnumMap = {
  DataPeriod.oneMinute: 'oneMinute',
  DataPeriod.twoMinutes: 'twoMinutes',
  DataPeriod.fiveMinutes: 'fiveMinutes',
  DataPeriod.fifteenMinutes: 'fifteenMinutes',
  DataPeriod.thirtyMinutes: 'thirtyMinutes',
  DataPeriod.sixtyMinutes: 'sixtyMinutes',
  DataPeriod.ninetyMinutes: 'ninetyMinutes',
  DataPeriod.oneHour: 'oneHour',
  DataPeriod.oneDay: 'oneDay',
  DataPeriod.fiveDays: 'fiveDays',
  DataPeriod.oneWeek: 'oneWeek',
  DataPeriod.oneMonth: 'oneMonth',
  DataPeriod.threeMonths: 'threeMonths',
};

const _$AlertMethodEnumMap = {
  AlertMethod.notification: 'notification',
  AlertMethod.email: 'email',
  AlertMethod.both: 'both',
};
