import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  static const String _settingsKey = 'app_settings';

  AppSettings? _cachedSettings;

  Future<AppSettings> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _cachedSettings = AppSettings.fromJson(settingsMap);
        return _cachedSettings!;
      }
    } catch (e) {
      print('Error loading settings: $e');
    }

    // Return default settings if none found or error occurred
    _cachedSettings = AppSettings();
    await saveSettings(_cachedSettings!);
    return _cachedSettings!;
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
      _cachedSettings = settings;
    } catch (e) {
      print('Error saving settings: $e');
      throw Exception('Failed to save settings');
    }
  }

  Future<void> updateWatchlist(List<String> watchlist) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(watchlist: watchlist);
    await saveSettings(updatedSettings);
  }

  Future<void> addToWatchlist(String symbol) async {
    final currentSettings = await getSettings();
    final updatedWatchlist = List<String>.from(currentSettings.watchlist);

    final upperSymbol = symbol.toUpperCase();
    if (!updatedWatchlist.contains(upperSymbol)) {
      updatedWatchlist.add(upperSymbol);
      await updateWatchlist(updatedWatchlist);
    }
  }

  Future<void> removeFromWatchlist(String symbol) async {
    final currentSettings = await getSettings();
    final updatedWatchlist = List<String>.from(currentSettings.watchlist);

    updatedWatchlist.remove(symbol.toUpperCase());
    await updateWatchlist(updatedWatchlist);
  }

  Future<void> updateTrackingInterval(DataPeriod interval) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(
      trackingInterval: interval,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateDataPeriod(DataPeriod period) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(dataPeriod: period);
    await saveSettings(updatedSettings);
  }

  Future<void> updateAlertMethod(AlertMethod method) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(alertMethod: method);
    await saveSettings(updatedSettings);
  }

  Future<void> updatePatternThreshold(double threshold) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(
      patternMatchThreshold: threshold,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateEmailAddress(String? email) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(emailAddress: email);
    await saveSettings(updatedSettings);
  }

  Future<void> updateNotificationSettings({
    bool? enableNotifications,
    bool? enableEmailAlerts,
  }) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(
      enableNotifications: enableNotifications,
      enableEmailAlerts: enableEmailAlerts,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> resetToDefaults() async {
    _cachedSettings = AppSettings();
    await saveSettings(_cachedSettings!);
  }

  Future<void> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      _cachedSettings = null;
    } catch (e) {
      print('Error clearing settings: $e');
    }
  }

  // Utility methods for common settings checks
  Future<bool> isSymbolInWatchlist(String symbol) async {
    final settings = await getSettings();
    return settings.watchlist.contains(symbol.toUpperCase());
  }

  Future<List<String>> getWatchlist() async {
    final settings = await getSettings();
    return settings.watchlist;
  }

  Future<double> getPatternThreshold() async {
    final settings = await getSettings();
    return settings.patternMatchThreshold;
  }

  Future<DataPeriod> getTrackingInterval() async {
    final settings = await getSettings();
    return settings.trackingInterval;
  }

  Future<DataPeriod> getDataPeriod() async {
    final settings = await getSettings();
    return settings.dataPeriod;
  }

  Future<AlertMethod> getAlertMethod() async {
    final settings = await getSettings();
    return settings.alertMethod;
  }

  void dispose() {
    _cachedSettings = null;
  }
}
