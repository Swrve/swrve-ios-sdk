import SwiftUI
import SwrveSDK

@main
struct IdentitySampleApp: App {

    init() {
        let config = SwrveConfig()
        // config.stack = .eu // To use the EU stack instead, uncomment this line

        // autoStartLastUser == false: nothing is tracked until start() or identify() is called, so
        // this app sends nothing at all until the user identifies. See IdentityView for how the UI
        // waits.
        //
        // autoStartLastUser == true is the default: the SDK tracks anonymously from launch. What
        // happens to that activity on identify() depends on the user — if the ID is new to Swrve
        // the anonymous user becomes the identified one and its activity carries over; if Swrve
        // already knows the ID, the SDK switches to that existing user and the anonymous activity
        // stays behind. Flip this line to try it; the identify flow is unchanged either way.
        config.autoStartLastUser = false

        SwrveSDK.sharedInstance(withAppID: YOUR_APP_ID, apiKey: YOUR_API_KEY, config: config)
    }

    var body: some Scene {
        WindowGroup {
            IdentityView()
        }
    }
}

// Replace with your Swrve app ID and API key, from Swrve dashboard > Settings > Integration settings.
let YOUR_APP_ID = 0
let YOUR_API_KEY = "YOUR_API_KEY"

// Sent either side of identify() so the change in user attribution is visible in Swrve.
let EVENT_BEFORE_IDENTIFY = "sample.before_identify"
let EVENT_AFTER_IDENTIFY = "sample.after_identify"
