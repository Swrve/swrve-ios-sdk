import SwiftUI
import SwrveSDK

@main
struct MessageCenterSampleApp: App {

    init() {
        let config = SwrveConfig()
        // config.stack = .eu // To use the EU stack instead, uncomment this line

        // Held weakly by the SDK, so it has to be something that stays alive — see MessageCenterStore.
        config.inAppMessageConfig.inAppMessageDelegate = MessageCenterStore.shared

        SwrveSDK.sharedInstance(withAppID: YOUR_APP_ID, apiKey: YOUR_API_KEY, config: config)

        // Registered here rather than in a view: the first callback reports that the initial content load finished, and a view registering later would miss it.
        SwrveSDK.campaignsUpdateListener(MessageCenterStore.shared)
    }

    var body: some Scene {
        WindowGroup {
            MessageCenterView()
        }
    }
}

// Replace with your Swrve app ID and API key, from Swrve dashboard > Settings > Integration settings.
let YOUR_APP_ID = 0
let YOUR_API_KEY = "YOUR_API_KEY"
