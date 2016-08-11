import UIKit
import SwrveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let config = SwrveConfig()
        config.pushEnabled = true
        config.prefersIAMStatusBarHidden = true
        Swrve .sharedInstanceWithAppID(YOUR_APP_ID, apiKey: "YOUR_API_KEY", config: config)
        
        if let launchOptions = launchOptions {
            let remoteNotification: [NSObject : AnyObject]? = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] as! [NSObject : AnyObject]!
            if (remoteNotification != nil) {
                Swrve.sharedInstance().talk.pushNotificationReceived(remoteNotification)
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        Swrve.sharedInstance().talk.pushNotificationReceived(userInfo)
    }

}
