import UIKit
import SwrveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let config = SwrveConfig()
        config.pushEnabled = true
        config.prefersIAMStatusBarHidden = true
        
        config.resourcesUpdatedCallback = {(SwrveResourcesUpdatedListener) -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SwrveUserResourcesUpdated"), object: self);
        }
        
        //FIXME: Add wour App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
        Swrve.sharedInstance(withAppID: 1030, apiKey: "SwrveDevApple", config: config)
        
        if let launchOptions = launchOptions {
            let remoteNotification: [AnyHashable: Any]? = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as! [AnyHashable: Any]!
            if (remoteNotification != nil) {
                Swrve.sharedInstance().talk.pushNotificationReceived(remoteNotification)
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        Swrve.sharedInstance().talk.pushNotificationReceived(userInfo)
    }

}
