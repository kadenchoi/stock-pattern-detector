import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/pattern_detection.dart';
import '../models/app_settings.dart';

class AlertManager {
  static final AlertManager _instance = AlertManager._internal();
  factory AlertManager() => _instance;
  AlertManager._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize macOS and iOS notifications
    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // iOS settings use the same DarwinInitializationSettings
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
      requestProvisionalPermission: false,
    );

    const initSettings = InitializationSettings(
      macOS: macOSSettings,
      iOS: iOSSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  Future<void> sendPatternAlert({
    required PatternMatch pattern,
    required AppSettings settings,
  }) async {
    try {
      switch (settings.alertMethod) {
        case AlertMethod.notification:
          await _sendNotification(pattern);
          break;
        case AlertMethod.email:
          if (settings.emailAddress != null) {
            await _sendEmail(pattern, settings.emailAddress!);
          }
          break;
        case AlertMethod.both:
          await _sendNotification(pattern);
          if (settings.emailAddress != null) {
            await _sendEmail(pattern, settings.emailAddress!);
          }
          break;
      }
    } catch (e) {
      print('Error sending alert for pattern ${pattern.id}: $e');
    }
  }

  Future<void> _sendNotification(PatternMatch pattern) async {
    if (!_isInitialized) await initialize();

    const notificationDetails = NotificationDetails(
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        categoryIdentifier: 'PATTERN_ALERT',
      ),
    );

    final title = '🚨 Pattern Detected: ${pattern.symbol}';
    final body = '${pattern.patternName} ${pattern.directionEmoji} '
        'Confidence: ${pattern.matchPercentage.toStringAsFixed(1)}%';

    await _notifications.show(
      pattern.id.hashCode,
      title,
      body,
      notificationDetails,
      payload: pattern.id,
    );
  }

  Future<void> _sendEmail(PatternMatch pattern, String emailAddress) async {
    try {
      // Create email message
      final message = Message()
        ..from = const Address(
          'alerts@financialpatterns.app',
          'Financial Pattern Detector',
        )
        ..recipients.add(emailAddress)
        ..subject = 'Pattern Alert: ${pattern.symbol} - ${pattern.patternName}'
        ..html = _buildEmailHtml(pattern);

      // Note: In a real app, you'd use a proper SMTP service like SendGrid, Mailgun, etc.
      // For this demo, we'll use a basic SMTP configuration
      final smtpServer = gmail('your-email@gmail.com', 'your-app-password');

      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
      // In a real app, you might want to queue failed emails for retry
    }
  }

  String _buildEmailHtml(PatternMatch pattern) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Pattern Alert</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { background-color: #f0f0f0; padding: 20px; border-radius: 8px; }
            .content { margin: 20px 0; }
            .pattern-info { background-color: #e8f4fd; padding: 15px; border-radius: 6px; }
            .confidence { color: #2196F3; font-weight: bold; }
            .direction { font-size: 1.2em; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🚨 Pattern Detection Alert</h1>
        </div>
        
        <div class="content">
            <div class="pattern-info">
                <h2>${pattern.symbol} - ${pattern.patternName}</h2>
                <p><strong>Direction:</strong> <span class="direction">${pattern.directionEmoji} ${pattern.direction.name.toUpperCase()}</span></p>
                <p><strong>Confidence Score:</strong> <span class="confidence">${pattern.matchPercentage.toStringAsFixed(1)}%</span></p>
                <p><strong>Detected At:</strong> ${_formatDateTime(pattern.detectedAt)}</p>
                <p><strong>Pattern Period:</strong> ${_formatDateTime(pattern.startTime)} to ${_formatDateTime(pattern.endTime)}</p>
                ${pattern.priceTarget != null ? '<p><strong>Price Target:</strong> \$${pattern.priceTarget!.toStringAsFixed(2)}</p>' : ''}
            </div>
            
            <h3>Description</h3>
            <p>${pattern.description}</p>
            
            <hr>
            <p style="color: #666; font-size: 0.9em;">
                This alert was generated by Financial Pattern Detector on ${_formatDateTime(DateTime.now())}.
                <br>
                Please conduct your own research before making any trading decisions.
            </p>
        </div>
    </body>
    </html>
    ''';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to pattern details
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    final macOSImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

    if (macOSImplementation != null) {
      final result = await macOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    return false;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  void dispose() {
    // Clean up resources if needed
  }
}
