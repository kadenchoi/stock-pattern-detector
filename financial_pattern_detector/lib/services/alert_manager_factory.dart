import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/pattern_detection.dart';
import '../models/app_settings.dart';
import '../managers/alert_manager.dart';

// Abstract interface for alert managers
abstract class AlertManagerInterface {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> sendPatternAlert(
      {required PatternMatch pattern, required AppSettings settings});
  void dispose();
}

// Factory to create platform-specific alert managers
class AlertManagerFactory {
  static AlertManagerInterface create() {
    if (kIsWeb) {
      return _WebAlertManagerStub();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return _MobileAlertManagerProxy();
    } else {
      return _DesktopAlertManagerProxy();
    }
  }
}

// Proxy for mobile alert manager (Android/iOS)
class _MobileAlertManagerProxy implements AlertManagerInterface {
  final AlertManager _manager = AlertManager();

  @override
  Future<void> initialize() => _manager.initialize();

  @override
  Future<bool> requestPermissions() => _manager.requestPermissions();

  @override
  Future<void> sendPatternAlert(
          {required PatternMatch pattern, required AppSettings settings}) =>
      _manager.sendPatternAlert(pattern: pattern, settings: settings);

  @override
  void dispose() {
    // AlertManager doesn't have a dispose method, nothing to do
  }
}

// Proxy for desktop alert manager
class _DesktopAlertManagerProxy implements AlertManagerInterface {
  final AlertManager _manager = AlertManager();

  @override
  Future<void> initialize() => _manager.initialize();

  @override
  Future<bool> requestPermissions() => _manager.requestPermissions();

  @override
  Future<void> sendPatternAlert(
          {required PatternMatch pattern, required AppSettings settings}) =>
      _manager.sendPatternAlert(pattern: pattern, settings: settings);

  @override
  void dispose() {
    // AlertManager doesn't have a dispose method, nothing to do
  }
}

// Stub for web alert manager (basic implementation without dart:html)
class _WebAlertManagerStub implements AlertManagerInterface {
  @override
  Future<void> initialize() async {
    print('Web alert manager initialized (stub)');
  }

  @override
  Future<bool> requestPermissions() async {
    print('Web permissions requested (stub)');
    return false; // Stub doesn't support permissions
  }

  @override
  Future<void> sendPatternAlert(
      {required PatternMatch pattern, required AppSettings settings}) async {
    print('Pattern alert: ${pattern.symbol} - ${pattern.patternType.name}');
  }

  @override
  void dispose() {
    // Nothing to dispose
  }
}
