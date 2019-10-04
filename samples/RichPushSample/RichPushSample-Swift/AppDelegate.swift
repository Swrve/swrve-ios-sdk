import UIKit
import SwrveSDK
import SwrveSDKCommon
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let NotificationCategoryIdentifier = "com.swrve.sampleAppButtons"
    let NotificationActionOneIdentifier = "ACTION1"
    let NotificationActionTwoIdentifier = "ACTION2"

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let config = SwrveConfig()
        // Set the response delegate before swrve is intialised
        config.pushResponseDelegate = self
        // Set the app group if you want influence to be tracked
        config.appGroupIdentifier = "group.swrve.RichPushSample";
        config.pushEnabled = true
        config.notificationCategories = produceUNNotificationCategory() as! Set<UNNotificationCategory>

        // FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
        SwrveSDK.sharedInstance(withAppID: -1, apiKey: "<API_KEY>", config: config)

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Set Application badge number to 0
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }

    //MARK: example category generation

    @available(iOS 10.0, *)
    func produceUNNotificationCategory() -> NSSet {

        let fgAction = UNNotificationAction(identifier: NotificationActionOneIdentifier, title: "Foreground", options: [UNNotificationActionOptions.foreground])

        let bgAction = UNNotificationAction(identifier: NotificationActionTwoIdentifier, title: "Background", options: [])

        let exampleCategory = UNNotificationCategory(identifier: NotificationCategoryIdentifier, actions: [fgAction, bgAction], intentIdentifiers: [], options: [])

        return NSSet(array:[exampleCategory])
    }

    //MARK:
    /** other generated func not used in this example **/
    func applicationWillResignActive(_ application: UIApplication) { }
    func applicationDidEnterBackground(_ application: UIApplication) { }
    func applicationDidBecomeActive(_ application: UIApplication) { }
    func applicationWillTerminate(_ application: UIApplication) { }
}

//MARK: SwrvePushResponseDelegate implementation

extension AppDelegate:  SwrvePushResponseDelegate {

    @available(iOS 10.0, *)
    func didReceive(_ response: UNNotificationResponse, withCompletionHandler completionHandler: (() -> Void)) {
        print("Got iOS 10 Notification with Identifier - \(response.actionIdentifier)")
        // Include your own code in here
        completionHandler()
    }

    @available(iOS 10.0, *)
    func willPresent(_ notification: UNNotification, withCompletionHandler completionHandler: ((UNNotificationPresentationOptions) -> Void)) {
        // Include your own code in here
        completionHandler([])
    }
}
