import Flutter
import workmanager
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier:"task-identifier")
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "br.com.infrasantacruz.app.RefreshPosts", frequency: NSNumber(value: 20*60))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
