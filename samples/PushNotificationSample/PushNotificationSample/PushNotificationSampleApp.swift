import SwiftUI
import SwrveSDK
import UserNotifications

@main
struct PushNotificationSampleApp: App {
    // The SDK is created in the app delegate because pushResponseDelegate has to be set before
    // initialisation, and initialisation has to happen before the app finishes launching.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            PushNotificationView()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let config = SwrveConfig()
        // config.stack = .eu // To use the EU stack instead, uncomment this line

        config.pushEnabled = true

        // Must match all three .entitlements files and the service extension, or rich push and
        // influence tracking stop working with no error.
        config.appGroupIdentifier = APP_GROUP

        // Sending one of these events triggers the OS permission prompt. Without it the SDK
        // never asks, so no push arrives.
        config.pushNotificationPermissionEvents = [EVENT_REQUEST_PUSH_PERMISSION]

        // Interactive buttons on the notification. Optional.
        config.notificationCategories = [notificationCategory()]

        config.pushResponseDelegate = self

        // Debug and Release use separate entitlements files with aps-environment "development" and
        // "production" — different APNS environments, different device tokens. Each configuration
        // therefore needs the credentials of the Swrve app it reports to.
        #if DEBUG
        SwrveSDK.sharedInstance(withAppID: DEBUG_APP_ID, apiKey: DEBUG_API_KEY, config: config)
        #else
        SwrveSDK.sharedInstance(withAppID: PRODUCTION_APP_ID, apiKey: PRODUCTION_API_KEY, config: config)
        #endif
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    private func notificationCategory() -> UNNotificationCategory {
        UNNotificationCategory(
            identifier: "com.swrve.sampleAppButtons",
            actions: [
                UNNotificationAction(identifier: "ACTION1", title: "Foreground", options: [.foreground]),
                UNNotificationAction(identifier: "ACTION2", title: "Background", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
    }
}

/// Called when the user interacts with a notification, with the full response — useful for reading
/// custom key/value pairs set on the campaign.
extension AppDelegate: SwrvePushResponseDelegate {

    func didReceive(_ response: UNNotificationResponse, withCompletionHandler completionHandler: (() -> Void)) {
        print("Notification action: \(response.actionIdentifier)")
        completionHandler()
    }

    func willPresent(
        _ notification: UNNotification,
        withCompletionHandler completionHandler: ((UNNotificationPresentationOptions) -> Void)
    ) {
        // Return options here to show the notification while the app is in the foreground.
        completionHandler([])
    }
}

// Replace with your Swrve app IDs and API keys, from Swrve dashboard > Settings > Integration
// settings. If you use a single Swrve app for both, the same values can go in each pair.
let DEBUG_APP_ID = 0
let DEBUG_API_KEY = "YOUR_API_KEY"
let PRODUCTION_APP_ID = 0
let PRODUCTION_API_KEY = "YOUR_API_KEY"

/// Shared with the service extension, which declares its own copy. Both must match the
/// `com.apple.security.application-groups` entry in all three `.entitlements` files.
let APP_GROUP = "group.swrve.RichPushSample"

let EVENT_REQUEST_PUSH_PERMISSION = "push_permission_request"
