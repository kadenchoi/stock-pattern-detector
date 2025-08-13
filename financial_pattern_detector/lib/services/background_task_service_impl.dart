// Platform implementation with background_fetch (mobile/desktop)
import 'package:background_fetch/background_fetch.dart';
import 'background_task_service.dart' as bg_service;

Future<void> configurePlatformBackgroundTasks() async {
  // Configure BackgroundFetch
  await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 60, // 1 hour
      stopOnTerminate: false,
      enableHeadless: true,
      requiredNetworkType: NetworkType.ANY,
    ),
    (String taskId) async {
      await bg_service.onBackgroundFetch(taskId);
    },
    (String taskId) {
      bg_service.onBackgroundFetchTimeout(taskId);
    },
  );

  // Start background fetch
  BackgroundFetch.start();
}

void finishBackgroundTask(String taskId) {
  BackgroundFetch.finish(taskId);
}
