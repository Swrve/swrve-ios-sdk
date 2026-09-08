import SwiftUI
import SwrveSDK

/// The inbox needs no push setup — creating the SDK is the whole integration.
///
/// Inbox messages arrive in the same content response as campaigns, not in the notification, so the list populates whether or not this app can receive push.
/// That is why there is no push capability, no notification permission and no service extension here. See PushNotificationSample for those.
@main
struct PushInboxSampleApp: App {

    init() {
        let config = SwrveConfig()
        // config.stack = .eu // To use the EU stack instead, uncomment this line

        SwrveSDK.sharedInstance(withAppID: YOUR_APP_ID, apiKey: YOUR_API_KEY, config: config)

        // Fires when the inbox is first loaded and whenever it changes, including when a content refresh brings new messages in while the app is open.
        // Registered here, with the store it writes to, because the inbox is app state rather than something a screen owns.
        SwrveSDK.pushInboxUpdateListener(InboxStore.shared)
    }

    var body: some Scene {
        WindowGroup {
            PushInboxView()
        }
    }
}

// Replace with your Swrve app ID and API key, from Swrve dashboard > Settings > Integration settings.
let YOUR_APP_ID = 0
let YOUR_API_KEY = "YOUR_API_KEY"
