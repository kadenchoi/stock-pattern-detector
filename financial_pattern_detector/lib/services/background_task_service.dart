import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../managers/app_manager.dart';
import '../services/pattern_cache_service.dart';

// Conditional import for background_fetch (only for non-web platforms)
import 'background_task_service_stub.dart'
    if (dart.library.io) 'background_task_service_impl.dart' as bg_service;

class BackgroundTaskService {
  static final BackgroundTaskService instance = BackgroundTaskService._();
  BackgroundTaskService._();

  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;

    // Skip background fetch configuration on web platform
    if (kIsWeb) {
      _configured = true;
      return;
    }

    // Delegate to platform-specific implementation
    await bg_service.configurePlatformBackgroundTasks();
    _configured = true;
  }
}

// Shared background task logic
Future<void> onBackgroundFetch(String taskId) async {
  try {
    final app = AppManager();
    await app.runManualAnalysis();

    // Optionally cache the latest stream emission by asking for recent patterns
    final patterns = await app.getHistoricalPatterns(
      startDate: DateTime.now().subtract(const Duration(hours: 24)),
      endDate: DateTime.now(),
    );
    await PatternCacheService.instance.cachePatterns(patterns);
  } catch (e) {
    // Log error
  } finally {
    if (!kIsWeb) {
      bg_service.finishBackgroundTask(taskId);
    }
  }
}

void onBackgroundFetchTimeout(String taskId) {
  if (!kIsWeb) {
    bg_service.finishBackgroundTask(taskId);
  }
}
