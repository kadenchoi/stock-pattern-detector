import BackgroundTasks
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Register a background task identifier (optional, iOS 13+ processing mode)
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.kadenchoi.stock-pattern-detector.fetch", using: nil
      ) { task in
        task.setTaskCompleted(success: true)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
