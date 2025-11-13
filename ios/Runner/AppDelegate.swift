import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // CRITICAL: Set notification center delegate
    // This enables notification tap events to be delivered to Flutter
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      print("✅ [AppDelegate] UNUserNotificationCenter delegate set")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle notification when app is in FOREGROUND
  // This determines how notifications are displayed when app is already open
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("📱 [AppDelegate] Notification received in foreground")
    print("   Notification ID: \(notification.request.identifier)")

    // Show banner, sound, and badge even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // Handle notification TAP (CRITICAL FOR DEEP LINKING)
  // This fires when user taps a notification from:
  // - Notification center
  // - Lock screen
  // - Banner (while app in background/terminated)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("🔔 [AppDelegate] Notification TAPPED")
    print("   Action ID: \(response.actionIdentifier)")
    print("   Notification ID: \(response.notification.request.identifier)")
    print("   User Info: \(response.notification.request.content.userInfo)")

    // Forward to Flutter plugin
    // This triggers _onNotificationTapped in Flutter notification services
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)

    print("   ✅ Forwarded to Flutter notification handler")
  }

  // Handle successful APNs token registration
  // Required for remote push notifications via Firebase Cloud Messaging
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("✅ [AppDelegate] APNs token registered: \(token)")

    // Firebase Messaging will handle this token
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle APNs registration failure
  // This helps diagnose notification permission and entitlement issues
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ [AppDelegate] Failed to register for remote notifications")
    print("   Error: \(error.localizedDescription)")

    // Check if this is an entitlement issue
    if error.localizedDescription.contains("no valid") {
      print("   💡 TIP: Check Runner.entitlements file exists and has aps-environment key")
      print("   💡 TIP: Verify Push Notifications capability is enabled in Xcode")
    }
  }
}
