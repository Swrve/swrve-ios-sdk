import UIKit
import SwrveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let config = SwrveConfig()
        config.pushEnabled = true
        config.prefersIAMStatusBarHidden = true
        //TODO: change that to be generic
        Swrve .sharedInstanceWithAppID(-1, apiKey: "<API_KEY>", config: config)
        
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
