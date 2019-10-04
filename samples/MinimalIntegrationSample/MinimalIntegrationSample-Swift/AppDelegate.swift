import UIKit
import SwrveSDK //Remember to import SwrveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let config = SwrveConfig()
        // To use the EU stack, include this in your config.
        // config.stack = SWRVE_STACK_EU
        
        //FIXME: Replace <app_id> and <api_key> with your app ID and API key.
#if DEBUG
        SwrveSDK.sharedInstance(withAppID: -1, apiKey: "sandbox_api_key", config: config)
#else
        SwrveSDK.sharedInstance(withAppID: -1, apiKey: "production_api_key", config: config)
#endif
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { }

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) { }
    
}

