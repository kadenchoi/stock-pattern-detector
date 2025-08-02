import 'package:flutter/foundation.dart' show kIsWeb;
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
      return _WebAlertManagerProxy();
    } else {
      return _DesktopAlertManagerProxy();
    }
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

// Proxy for web alert manager that dynamically loads the web implementation
class _WebAlertManagerProxy implements AlertManagerInterface {
  dynamic _webManager;
  bool _isInitialized = false;

  Future<void> _ensureWebManager() async {
    if (_webManager != null || !kIsWeb) return;

    try {
      // Import the web-specific alert manager when on web platform
      final module = await _importWebModule();
      _webManager = module.createWebAlertManager();
    } catch (e) {
      print('Failed to load web alert manager: $e');
      // Fall back to stub implementation
      _webManager = _WebAlertManagerStub();
    }
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _ensureWebManager();

    if (_webManager != null) {
      await _webManager.initialize();
    }

    _isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    await _ensureWebManager();

    if (_webManager != null) {
      return await _webManager.requestPermissions();
    }
    return false;
  }

  @override
  Future<void> sendPatternAlert(
      {required PatternMatch pattern, required AppSettings settings}) async {
    await _ensureWebManager();

    if (_webManager != null) {
      await _webManager.sendPatternAlert(pattern, settings);
    }
  }

  @override
  void dispose() {
    // Web manager doesn't need disposal
  }

  // This will be replaced with actual dynamic import when compiled for web
  Future<dynamic> _importWebModule() async {
    // This is a placeholder - the actual web implementation will be loaded dynamically
    return _MockWebModule();
  }
}

// Mock module for non-web platforms
class _MockWebModule {
  dynamic createWebAlertManager() {
    return _WebAlertManagerStub();
  }
}

// Stub implementation for web alert manager
class _WebAlertManagerStub implements AlertManagerInterface {
  @override
  Future<void> initialize() async {
    print('Web alert manager initialized (stub)');
  }

  @override
  Future<bool> requestPermissions() async {
    print('Web permissions requested (stub)');
    return false;
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
