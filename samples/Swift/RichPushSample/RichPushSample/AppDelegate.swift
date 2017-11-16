import UIKit
import SwrveSDK
import SwrveSDKCommon
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SwrvePushResponseDelegate {

    let NotificationCategoryIdentifier = "com.swrve.sampleAppButtons"
    let NotificationActionOneIdentifier = "ACTION1"
    let NotificationActionTwoIdentifier = "ACTION2"

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let config = SwrveConfig()
        // Set the response delegate before swrve is intialised
        config.pushResponseDelegate = self
        // Set the app group if you want influence to be tracked
        config.appGroupIdentifier = "group.swrve.RichPushSample";
        config.pushEnabled = true

        // If running below iOS 10 as well, it is best to include a conditional around category generation as it doesn't need both
        if #available(iOS 10.0, *) {
            config.notificationCategories = produceUNNotificationCategory() as! Set<UNNotificationCategory>;
        }else{
            config.pushCategories = produceUIUserNotificationCategory() as! Set<UIUserNotificationCategory>;
        }

        // FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
        SwrveSDK.sharedInstance(withAppID: -1, apiKey: "<API_KEY>", config: config, launchOptions: launchOptions)

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Set Application badge number to 0
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }

//MARK: notification response handling

    /** SwrvePushResponseDelegate Functions **/
    @available(iOS 10.0, *)
    func didReceive(_ response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
        print("Got iOS 10 Notification with Identifier - \(response.actionIdentifier)")
        // Include your own code in here
        completionHandler()
    }

    @available(iOS 10.0, *)
    func willPresent(_ notification: UNNotification!, withCompletionHandler completionHandler: ((UNNotificationPresentationOptions) -> Void)!) {
        // Include your own code in here
        completionHandler([])
    }

    /** Pre-iOS 10 Category Handling **/
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        print("Got Pre-iOS 10 Notification with Identifier - \(identifier!)")

        // Include this method to ensure that you still log it to Swrve
        SwrveSDK.processNotificationResponse(withIdentifier: identifier, andUserInfo: notification.userInfo)

        // Include your own code in here
        completionHandler()
    }

//MARK: example category generation

    @available(iOS 10.0, *)
    func produceUNNotificationCategory() -> NSSet {

        let fgAction = UNNotificationAction(identifier: NotificationActionOneIdentifier, title: "Foreground", options: [UNNotificationActionOptions.foreground])

        let bgAction = UNNotificationAction(identifier: NotificationActionTwoIdentifier, title: "Background", options: [])

        let exampleCategory = UNNotificationCategory(identifier: NotificationCategoryIdentifier, actions: [fgAction, bgAction], intentIdentifiers: [], options: [])

        return NSSet(array:[exampleCategory])
    }

    func produceUIUserNotificationCategory() -> NSSet {

        let fgAction :UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        fgAction.identifier = NotificationActionOneIdentifier
        fgAction.title = "Foreground"
        fgAction.isDestructive = false
        fgAction.isAuthenticationRequired = false
        fgAction.activationMode = UIUserNotificationActivationMode.foreground

        let bgAction :UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        bgAction.identifier = NotificationActionTwoIdentifier
        bgAction.title = "Background"
        bgAction.isDestructive = true
        bgAction.isAuthenticationRequired = false
        bgAction.activationMode = UIUserNotificationActivationMode.background

        let exampleCategory:UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
        exampleCategory.identifier = NotificationCategoryIdentifier
        exampleCategory.setActions([fgAction,bgAction], for: UIUserNotificationActionContext.default)
        exampleCategory.setActions([fgAction,bgAction], for: UIUserNotificationActionContext.minimal)

        return NSSet(array:[exampleCategory])
    }

//MARK:
    /** other generated func not used in this example **/
    func applicationWillResignActive(_ application: UIApplication) { }
    func applicationDidEnterBackground(_ application: UIApplication) { }
    func applicationDidBecomeActive(_ application: UIApplication) { }
    func applicationWillTerminate(_ application: UIApplication) { }
}
