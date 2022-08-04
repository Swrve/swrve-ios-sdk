import UIKit
import SwrveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let config = SwrveConfig()
        config.resourcesUpdatedCallback = { () -> Void in
            // New campaigns are available
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SwrveUserResourcesUpdated"), object: self)
        }

        //FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
        SwrveSDK.sharedInstance(withAppID: -1, apiKey: "<API_KEY>", config: config)
        return true
    }
}
