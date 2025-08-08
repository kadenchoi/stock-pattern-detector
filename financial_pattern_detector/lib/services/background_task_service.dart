import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import '../managers/app_manager.dart';
import '../services/pattern_cache_service.dart';

class BackgroundTaskService {
  static final BackgroundTaskService instance = BackgroundTaskService._();
  BackgroundTaskService._();

  bool _configured = false;

  Future<void> configure() async {
    if (_configured) return;

    // Configure background fetch
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15, // minutes (iOS decides actual schedule)
        startOnBoot: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );

    // Register a task id used by iOS
    await BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

    _configured = true;
  }
}

Future<void> _onBackgroundFetch(String taskId) async {
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
    BackgroundFetch.finish(taskId);
  }
}

void _onBackgroundFetchTimeout(String taskId) {
  BackgroundFetch.finish(taskId);
}

// iOS headless task entrypoint
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final String taskId = task.taskId;
  final bool timeout = task.timeout;
  if (timeout) {
    BackgroundFetch.finish(taskId);
    return;
  }
  await _onBackgroundFetch(taskId);
}
