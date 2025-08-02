import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/pattern_detection.dart';
import '../models/app_settings.dart';

class AlertManagerWeb {
  static const String _permissionStorageKey = 'notification_permission';

  Future<void> initialize() async {
    if (kIsWeb) {
      await _requestNotificationPermission();
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        html.window.localStorage[_permissionStorageKey] = permission;
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  Future<bool> _hasNotificationPermission() async {
    if (!kIsWeb || !html.Notification.supported) return false;

    final permission = html.window.localStorage[_permissionStorageKey];
    return permission == 'granted';
  }

  Future<void> sendPatternAlert(
    PatternMatch pattern,
    AppSettings settings,
  ) async {
    if (!settings.enableNotifications) return;

    if (kIsWeb) {
      await _sendWebNotification(pattern, settings);
    }

    // For web, we can't send emails directly, so we'll show a more detailed notification
    if (settings.enableEmailAlerts) {
      await _showEmailAlert(pattern, settings);
    }
  }

  Future<void> _sendWebNotification(
    PatternMatch pattern,
    AppSettings settings,
  ) async {
    if (!await _hasNotificationPermission()) return;

    try {
      final title = 'Pattern Detected: ${pattern.symbol}';
      final body =
          '${pattern.patternType.name} - ${pattern.direction.name.toUpperCase()}\n'
          'Confidence: ${(pattern.matchScore * 100).toStringAsFixed(1)}%';

      final notification = html.Notification(
        title,
        body: body,
        icon: '/web/icons/Icon-192.png',
        tag: pattern.id,
      );

      // Auto-close after 10 seconds
      Timer(const Duration(seconds: 10), () {
        notification.close();
      });

      // Handle notification click
      notification.onClick.listen((_) {
        // Focus not available in web, just close notification
        notification.close();
      });
    } catch (e) {
      print('Error sending web notification: $e');
    }
  }

  Future<void> _showEmailAlert(
    PatternMatch pattern,
    AppSettings settings,
  ) async {
    // For web, show a prominent in-app alert since we can't send emails directly
    try {
      final alertDiv = html.DivElement()
        ..style.position = 'fixed'
        ..style.top = '20px'
        ..style.right = '20px'
        ..style.backgroundColor = '#2196F3'
        ..style.color = 'white'
        ..style.padding = '16px'
        ..style.borderRadius = '8px'
        ..style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)'
        ..style.zIndex = '9999'
        ..style.maxWidth = '300px'
        ..style.fontSize = '14px'
        ..style.fontFamily = 'system-ui, -apple-system, sans-serif';

      final content = '''
        <div style="font-weight: bold; margin-bottom: 8px;">
          📧 Email Alert: ${pattern.symbol}
        </div>
        <div style="margin-bottom: 4px;">
          Pattern: ${pattern.patternType.name}
        </div>
        <div style="margin-bottom: 4px;">
          Direction: ${pattern.direction.name.toUpperCase()}
        </div>
        <div style="margin-bottom: 8px;">
          Confidence: ${(pattern.matchScore * 100).toStringAsFixed(1)}%
        </div>
        <div style="font-size: 12px; opacity: 0.9;">
          Note: Configure email settings to receive alerts via email
        </div>
        <button style="margin-top: 8px; padding: 4px 8px; background: rgba(255,255,255,0.2); border: none; color: white; border-radius: 4px; cursor: pointer;">
          Dismiss
        </button>
      ''';

      alertDiv.innerHtml = content;

      final dismissButton = alertDiv.querySelector('button');
      dismissButton?.onClick.listen((_) {
        alertDiv.remove();
      });

      html.document.body?.append(alertDiv);

      // Auto-dismiss after 15 seconds
      Timer(const Duration(seconds: 15), () {
        if (alertDiv.parent != null) {
          alertDiv.remove();
        }
      });
    } catch (e) {
      print('Error showing email alert: $e');
    }
  }

  Future<void> sendTestAlert() async {
    if (kIsWeb) {
      await _sendTestWebNotification();
    }
  }

  Future<void> _sendTestWebNotification() async {
    if (!await _hasNotificationPermission()) {
      await _requestNotificationPermission();
      return;
    }

    try {
      final notification = html.Notification(
        'Stock Pattern Detector',
        body: 'Test notification - alerts are working!',
        icon: '/web/icons/Icon-192.png',
        tag: 'test_notification',
      );

      Timer(const Duration(seconds: 5), () {
        notification.close();
      });

      notification.onClick.listen((_) {
        // Focus not available in web, just close notification
        notification.close();
      });
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  Future<bool> canSendNotifications() async {
    return await _hasNotificationPermission();
  }

  Future<void> openNotificationSettings() async {
    if (kIsWeb) {
      // Show information about enabling notifications
      _showNotificationSettingsInfo();
    }
  }

  void _showNotificationSettingsInfo() {
    try {
      final infoDiv = html.DivElement()
        ..style.position = 'fixed'
        ..style.top = '50%'
        ..style.left = '50%'
        ..style.transform = 'translate(-50%, -50%)'
        ..style.backgroundColor = 'white'
        ..style.color = '#333'
        ..style.padding = '24px'
        ..style.borderRadius = '12px'
        ..style.boxShadow = '0 8px 32px rgba(0,0,0,0.3)'
        ..style.zIndex = '10000'
        ..style.maxWidth = '400px'
        ..style.fontSize = '14px'
        ..style.fontFamily = 'system-ui, -apple-system, sans-serif';

      final content = '''
        <div style="font-weight: bold; font-size: 18px; margin-bottom: 16px; color: #2196F3;">
          🔔 Enable Notifications
        </div>
        <div style="margin-bottom: 12px;">
          To receive pattern detection alerts, please:
        </div>
        <ol style="margin: 16px 0; padding-left: 20px;">
          <li style="margin-bottom: 8px;">Click on the lock/settings icon in your browser's address bar</li>
          <li style="margin-bottom: 8px;">Find "Notifications" in the permissions list</li>
          <li style="margin-bottom: 8px;">Change the setting to "Allow"</li>
          <li style="margin-bottom: 8px;">Refresh this page</li>
        </ol>
        <div style="margin-top: 16px; text-align: center;">
          <button style="padding: 8px 16px; background: #2196F3; color: white; border: none; border-radius: 6px; cursor: pointer; margin-right: 8px;">
            Try Again
          </button>
          <button style="padding: 8px 16px; background: #757575; color: white; border: none; border-radius: 6px; cursor: pointer;">
            Close
          </button>
        </div>
      ''';

      infoDiv.innerHtml = content;

      final tryAgainButton = infoDiv.querySelectorAll('button')[0];
      final closeButton = infoDiv.querySelectorAll('button')[1];

      tryAgainButton.onClick.listen((_) async {
        infoDiv.remove();
        await _requestNotificationPermission();
      });

      closeButton.onClick.listen((_) {
        infoDiv.remove();
      });

      // Add backdrop
      final backdrop = html.DivElement()
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'rgba(0,0,0,0.5)'
        ..style.zIndex = '9999';

      backdrop.onClick.listen((_) {
        backdrop.remove();
        infoDiv.remove();
      });

      html.document.body?.append(backdrop);
      html.document.body?.append(infoDiv);
    } catch (e) {
      print('Error showing notification settings info: $e');
    }
  }
}
