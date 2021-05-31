import UIKit
import SwrveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SwrveMessageDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let config = SwrveConfig()
        config.resourcesUpdatedCallback = {() -> Void in
            // New campaigns are available
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SwrveUserResourcesUpdated"), object: self)
        }
        
        // The Swrve SDK creates new UIWindows to display content to avoid
        // creating issues for games etc. However, this means that the controllers
        // do not get their callbacks called.
        // We set this class as the delegate to listen to these events and notify any views interested.
        config.inAppMessageConfig.showMessageDelegate = self
        
        //FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
        SwrveSDK.sharedInstance(withAppID: -1, apiKey: "<API_KEY>", config: config)
        return true
    }
    
    func messageWillBeHidden(_ viewController: UIViewController)  {
        // An in-app message or conversation will be hidden.
        // Notify the table view that the state of a campaign might have changed.
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SwrveMessageWillBeHidden"), object: self);
    }
}
