import SwiftUI
import SwrveSDK
import UserNotifications

@main
struct MultiplePushProvidersSampleApp: App {
    // Initialisation has to happen before the app finishes launching.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            MultiplePushProvidersView()
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

        // The line the rest of this sample follows from: the other provider registers and owns the device token, so Swrve must not collect one itself.
        config.autoCollectDeviceToken = false

        config.appGroupIdentifier = APP_GROUP

        SwrveSDK.sharedInstance(withAppID: YOUR_APP_ID, apiKey: YOUR_API_KEY, config: config)

        // The app owns this because both providers need it — Swrve is told about taps below. Must come after sharedInstance, which assigns Swrve as the delegate; assign first and Swrve overwrites you.
        UNUserNotificationCenter.current().delegate = self

        // Register on every launch — this does not prompt, and it is how the token arrives after the first run.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async { application.registerForRemoteNotifications() }
        }

        return true
    }

    /// Stands in for the other provider's registration. Behind a button because iOS shows the prompt once per install — see the README.
    static func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    // MARK: - Device token

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // RELAY 1 of 3. With autoCollectDeviceToken = false this is the only way Swrve learns the token. Miss it and everything still compiles and runs while push never arrives.
        SwrveSDK.setDeviceToken(deviceToken)

        // Your other provider's equivalent goes here — the same token can go to both.

        // This sample's on-screen status only; not part of the integration.
        PushActivity.shared.tokenRegistered()
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushActivity.shared.record("Token registration failed: \(error.localizedDescription)")
    }

}

// MARK: - Notification centre delegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// RELAY 2 of 3. `processNotificationResponse` is the alternative to `SwrvePushResponseDelegate`, which has Swrve own this callback — impossible when a second provider needs it too.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        SwrveSDK.processNotificationResponse(response)

        // Your other provider's equivalent goes here. Swrve ignores payloads that are not its own, so both can be told unconditionally.

        PushActivity.shared.record("Notification tapped — response offered to Swrve")
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// Replace with your Swrve app ID and API key, from Swrve dashboard > Settings > Integration settings.
let YOUR_APP_ID = 0
let YOUR_API_KEY = "YOUR_API_KEY"

/// Shared with the service extension, which declares its own copy. Both must match the `com.apple.security.application-groups` entry in both `.entitlements` files.
let APP_GROUP = "group.swrve.RichPushSample"
