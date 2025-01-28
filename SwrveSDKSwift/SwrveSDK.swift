//swiftlint:disable file_length
import Foundation

#if canImport(SwrveSDK)
    import SwrveSDK
#endif

#if canImport(ActivityKit)
    import ActivityKit
#endif

public enum SwrveSDKError: Error, Equatable {
    case runtimeError(String)
}

@objc public class SwrveSDK: NSObject {

    @objc public internal(set) static var sharedInstance: SwrveProtocol!
    private static var sharedInstanceToken: Int = 0

    private override init() {}

    /**
     Creates and initializes the shared Swrve singleton.

     The default user ID is a random UUID. The userID is cached in the
     default settings of the app and recalled the next time you initialize the
     app. This means the ID for the user will stay consistent for as long as the
     user has your app installed on the device.

     - Parameters:
     - swrveAppID: The App ID for your app supplied by Swrve.
     - swrveAPIKey: The secret token for your app supplied by Swrve.
     */

    @objc public class func sharedInstance(withAppID: Int, apiKey: String) {
        if sharedInstanceToken == 0 {
            if SwrveCommon.supportedOS() {
                sharedInstance = Swrve(appID: Int32(withAppID), apiKey: apiKey, config: SwrveConfig())
            } else {
                sharedInstance = SwrveEmpty(appID: Int32(withAppID), apiKey: apiKey, config: SwrveConfig())
            }
            sharedInstanceToken = 1
        }
    }

    /**
     Creates and initializes the shared Swrve singleton. Takes a SwrveConfig object that can be used to change default settings.

     - Parameters:
     - swrveAppID: The App ID for your app supplied by Swrve.
     - swrveAPIKey: The secret token for your app supplied by Swrve.
     - swrveConfig: The swrve configuration object used to override default settings.
     */

    @objc public class func sharedInstance(withAppID: Int, apiKey: String, config: SwrveConfig) {
        if sharedInstanceToken == 0 {
            if SwrveCommon.supportedOS() {
                sharedInstance = Swrve(appID: Int32(withAppID), apiKey: apiKey, config: config)
            } else {
                sharedInstance = SwrveEmpty(appID: Int32(withAppID), apiKey: apiKey, config: config)
            }
            sharedInstanceToken = 1
        }
    }

    /**
     Configuration for this Swrve object.
     - Returns: Immutable configuration object for Swrve.
     */

    @objc public class func config() -> SwrveConfig {
        SwrveSDK.checkInstance()
        return sharedInstance.config
    }

    /**
     App ID used to initialize this Swrve object.
     - Returns: Long integer representing the app ID.
     */

    @objc public class func appID() -> Int {
        SwrveSDK.checkInstance()
        return sharedInstance.appID
    }
    /**
     Secret token used to initialize this Swrve object.
     - Returns: Secret API key as a string.
     */

    @objc public class func apiKey() -> String {
        SwrveSDK.checkInstance()
        return sharedInstance.apiKey
    }

    /**
     User ID used to initialize this Swrve object.
     - Returns: User ID as a string.
     */

    @objc public class func userID() -> String {
        SwrveSDK.checkInstance()
        return sharedInstance.userID()
    }
    /**
     Unique UUID used to identify this device.
     - Returns: Device ID as a string.
     */

    @objc public class func deviceID() -> String? {
        SwrveSDK.checkInstance()
        return SwrveLocalStorage.deviceUUID()
    }

    @objc public class func checkInstance() {
        if sharedInstance == nil {
            let exception = NSException(
                name: NSExceptionName("SwrveInstanceNotFoundException"),
                reason: "Please call [SwrveSDK init...] first",
                userInfo: nil
            )
            exception.raise()
        }
    }

    /**
     Call this when an in-app item is purchased.
     The currency specified must be one of the currencies known to Swrve that are
     specified on the Swrve dashboard.

     - Parameters:
     - itemName: The UID of the item being purchased.
     - itemCurrency: The name of the currency used to purchase the item.
     - itemCost: The per-item cost of the item being purchased.
     - itemQuantity: The quantity of the item being purchased.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc public class func purchaseItem(_ itemName: String, currency itemCurrency: String, cost itemCost: Int, quantity itemQuantity: Int) -> Int {
        checkInstance()
        return Int(sharedInstance.purchaseItem(itemName, currency: itemCurrency, cost: Int32(itemCost), quantity: Int32(itemQuantity)))
    }

    /**
     Call this when the user has bought something using real currency.
     See the REST API docs for the IAP event for a detailed description of the
     semantics of this call, noting in particular the format specification for
     currency.

     - Parameters:
     - transaction: The SKPaymentTransaction object received from the iTunes Store.
     - product: The SKProduct of the purchased item.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc public class func iap(_ transaction: SKPaymentTransaction, product: SKProduct) -> Int {
        checkInstance()
        return Int(sharedInstance.iap(transaction, product: product))
    }

    /**
     Call this when the user has bought something using real currency.
     Include the virtual item and currency given to the user in rewards.

     See the REST API docs for the IAP event for a detailed description of the
     semantics of this call, noting in particular the format specification for
     currency.

     - Parameters:
     - rewards: The SwrveIAPRewards object containing any additional
     items or in-app currencies that are part of this purchase.
     - product: The SDKProduct of the purchased item.
     - transaction: The SKPaymentTransaction object received from the iTunes Store.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc public class func iap(_ transaction: SKPaymentTransaction, product: SKProduct, rewards: SwrveIAPRewards) -> Int {
        checkInstance()
        return Int(sharedInstance.iap(transaction, product: product, rewards: rewards))
    }
    /**
     Similar to IAP event but does not validate the receipt data server side.

     - Parameters:
     - rewards: The SwrveIAPRewards object containing any additional
     items or in-app currencies that are part of this purchase.
     - localCost: The price (in real money) of the product that was purchased.
     Note: this is not the price of the total transaction, but the per-product price.
     - localCurrency: The name of the currency that the user has spent in real money.
     - productId: The ID of the IAP item being purchased.
     - productIdQuantity: The number of product items being purchased (usually 1).

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc public class func unvalidatedIap(
        _ rewards: SwrveIAPRewards, localCost: Double, localCurrency: String, productId: String, productIdQuantity: Int
    )
        -> Int
    {
        checkInstance()
        return Int(
            sharedInstance.unvalidatedIap(
                rewards, localCost: localCost, localCurrency: localCurrency, productId: productId, productIdQuantity: Int32(productIdQuantity)))
    }

    /**
     Call this to send a named custom event with no payload.

     - Parameter eventName: The name of the event.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc public class func event(_ eventName: String) -> Int {
        checkInstance()
        return Int(sharedInstance.event(eventName))
    }

    /**
     Call this to send a named custom event with payload.

     - Parameters:
     - eventName: The name of the event.
     - eventPayload: The payload to be sent with this event.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc public class func event(_ eventName: String, payload eventPayload: [String: Any]) -> Int {
        checkInstance()
        return Int(sharedInstance.event(eventName, payload: eventPayload))
    }

    /**
     Call this when the user has been gifted in-app currency by the app itself.
     See the REST API docs for the currency_given event for a detailed
     description of the semantics of this call.

     - Parameters:
     - givenCurrency: The name of the in-app currency that the player was rewarded with.
     - givenAmount: The amount of in-app currency that the player was rewarded with.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc(currencyGiven:givenAmount:) public class func currency(given: String, givenAmount: Double) -> Int {
        checkInstance()
        return Int(sharedInstance.currency(given: given, givenAmount: givenAmount))
    }

    /**
     Sends a group of custom user properties to Swrve.
     See the REST API docs for the user event for a detailed description of the
     semantics of this call.

     - Parameter attributes: The attributes to be set for the user.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc public class func userUpdate(_ attributes: [String: Any]) -> Int {
        checkInstance()
        return Int(sharedInstance.userUpdate(attributes))
    }

    /**
     Sends a single Date based custom user property to Swrve

     See the REST API docs for the user event for a detailed description of the
     semantics of this call.

     - Parameters:
     - name: The identifier for the user update.
     - date: The NSDate value associated.

     - Returns: SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
     */

    @objc(userUpdate:withDate:) public class func userUpdate(_ name: String, with: Date) -> Int {
        checkInstance()
        return Int(sharedInstance.userUpdate(name, with: with))

    }

    /**
     If SwrveConfig.autoDownloadCampaignsAndResources is YES (default value) this function is called
     automatically to keep the user resources and campaign data up to date.

     Use the resourceManager to get the latest up-to-date values for the resources.

     If SwrveConfig.autoDownloadCampaignsAndResources is set to NO, please call this function to update
     values. This function issues an asynchronous HTTP request to the Swrve content server
     specified in SwrveConfig. This function will return immediately, and the
     callback will be fired after the Swrve server has sent its response. At this point
     the resourceManager can be used to retrieve the updated resource values.
     */

    @objc public class func refreshCampaignsAndResources() {
        checkInstance()
        sharedInstance.refreshCampaignsAndResources()
    }

    /**
     Use the resource manager to retrieve the most up-to-date attribute
     values at any time.

     - Returns: Resource manager.
     */

    @objc public class func resourceManager() -> SwrveResourceManager? {
        checkInstance()
        return sharedInstance.resourceManager
    }

    /**
     Gets a list of resources for a user including modifications from active
     A/B tests.  Please refer to our online documentation for more details:

     http://dashboard.swrve.com/help/docs/abtest_api#GetUserResources

     This function will return immediately, and the callback will be fired right
     away with the already present AB test data.

     The result of this call is cached in the userResourcesCacheFile specified in
     SwrveConfig. This file is initially seeded with "[]", the empty JSON array.

     - Parameter callbackBlock: A callback block that will be called asynchronously when
     A/B test data is available.
     */

    @objc public class func userResources(_ callbackBlock: @escaping SwrveUserResourcesCallback) {
        checkInstance()
        sharedInstance.userResources(callbackBlock)
    }

    /**
     Gets the user resource differences that should be applied to items for the
     given user based on the A/B test the user is involved in.  Please refer to
     our online documentation for more details:

     https://docs.swrve.com/swrves-apis/api-guides/swrve-ab-test-api-guide/#Get_user_resources_diff

     This function issues an asynchronous HTTP request to the Swrve content server
     specified in #swrve_init. This function will return immediately, and the
     callback may be fired at some unspecified time in the future. The callback
     will be fired after the Swrve server has sent some AB-Test modifications to
     the SDK, or if the HTTP request fails (when the iOS device is offline or has
     limited connectivity.

     - Parameter listener: A listener block that will be called (usually asynchronously) with results.
     */

    @objc(userResourcesDiffWithListener:) public class func userResourcesDiff(_ listener: @escaping SwrveUserResourcesDiffListener) {
        checkInstance()
        sharedInstance.userResourcesDiff(listener: listener)
    }

    /**
     Gets a dictionary of real time user properties
     This function will return immediately, and the callback will be fired right
     away with the already present AB test data.

     - Parameter callbackBlock: A callback block that will be called asynchronously when real time user
     properties become available
     */

    @objc public class func realTimeUserProperties(_ callbackBlock: @escaping SwrveRealTimeUserPropertiesCallback) {
        checkInstance()
        sharedInstance.realTimeUserProperties(callbackBlock)
    }

    /**
     Sends all events that are queued to the Swrve servers.
     If any events cannot be send they will be re-queued and sent again later.
     */
    @objc public class func sendQueuedEvents() {
        checkInstance()
        sharedInstance.sendQueuedEvents()
    }

    /**
     Saves events stored in the in-memory queue to disk.
     After calling this function, the in-memory queue will be empty.
     */

    @objc public class func saveEventsToDisk() {
        checkInstance()
        sharedInstance.saveEventsToDisk()
    }

    /**
     Sets the event queue callback. If set, the callback block will be called each
     time an event is queued with the SDK.

     - Parameter callbackBlock: Block to be executed once per event added to the queue.
     */

    @objc public class func setEventQueuedCallback(_ callbackBlock: @escaping SwrveEventQueuedCallback) {
        checkInstance()
        sharedInstance.setEventQueuedCallback(callbackBlock)
    }
    /**
     Similar to `event(_:payload:)` except the callback block will not be called
     when the event is queued.

     - Parameters:
     - eventName: Name of the event.
     - eventPayload: Dictionary containing event payload.

     - Returns: Returns an integer identifier for the event.
     */
    @objc public class func eventWithNoCallback(_ eventName: String, payload eventPayload: [String: Any]) -> Int {
        checkInstance()
        return Int(sharedInstance.eventWithNoCallback(eventName, payload: eventPayload))
    }

    /**
     Releases all resources used by the Swrve object.
     Typically, this should only be called if you are managing multiple Swrve instances.
     Once called, it is not safe to call any methods on the Swrve object.
     */

    @objc public class func shutdown() {
        checkInstance()
        sharedInstance.shutdown()
    }

    #if os(iOS)
        @objc class func sendDeviceUpdate() {
            checkInstance()
            sharedInstance.sendDeviceUpdate()
        }

        /**
     Call this method when you get a push notification device token from Apple.

     - Parameter deviceToken: Apple device token for your app.
     */

        @objc public class func setDeviceToken(_ deviceToken: Data) {
            checkInstance()
            sharedInstance.setDeviceToken(deviceToken)
        }

        /**
     Obtain the current push notification device token.

     - Returns: Current push notification device token as an optional string.
     */

        @objc public class func deviceToken() -> String? {
            checkInstance()
            return sharedInstance.deviceToken()
        }

        /**
     Process the push notification in the background. The completion handler is called if a silent push notification was received with the
     fetch result and the custom payloads as parameters.

     - Parameters:
     - userInfo: Push information.
     - completionHandler: Completion handler, only called for silent push notifications.

     - Returns: If a Swrve silent push notification was handled by the Swrve SDK.
     */

        @objc public class func didReceiveRemoteNotification(
            _ userInfo: [AnyHashable: Any],
            withBackgroundCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult, [AnyHashable: Any]?) -> Void
        ) -> Bool {
            checkInstance()
            return sharedInstance.didReceiveRemoteNotification(userInfo, withBackgroundCompletionHandler: completionHandler)
        }

        /**
     Called to send the push engaged event to Swrve.
     - Parameter pushId: Push notification identifier.
    */
        @objc public class func sendPushEngagedEvent(_ pushId: String) {
            checkInstance()
            sharedInstance.sendPushNotificationEngagedEvent(pushId, withPayload: nil)
        }

        /**
     Called to send the push engaged event to Swrve.
     - Parameter pushId: The push id for engagement (the _p value from the push payload)
     - Parameter trackingData: Tracking data to be sent with the event (the _td value from the push payload)
     - Parameter platform: Platform of the push notification (the _smp value from the push payload)
     */
        @objc public class func sendPushEngagedEvent(_ pushId: String, _ trackingData: String, _ platform: String) {
            checkInstance()
            var payload: [String: String] = [:]
            if !trackingData.isEmpty {
                payload[SwrveNotificationTrackingDataKey] = trackingData
            }
            if !platform.isEmpty {
                payload[SwrveNotificationPlatformKey] = platform
            }
            sharedInstance.sendPushNotificationEngagedEvent(pushId, withPayload: payload)
        }

        /**
     Should be included to a push response if not using SwrvePushResponseDelegate.

     - Parameter response: UNNotificationResponse received.
     */

        @objc public class func processNotificationResponse(_ response: UNNotificationResponse) {
            checkInstance()
            sharedInstance.processNotificationResponse(response)
        }

    #endif

    /**
     Call this method from application:openURL:option

     - Parameter url: The deeplink URL to process.

     ```
     func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
         SwrveSDK.handleDeeplink(url)
         return true
     }
     ```
     */
    @objc public class func handleDeeplink(_ url: URL) {
        checkInstance()
        sharedInstance.handleDeeplink(url)
    }

    /**
     This method is used to inform SDK that the App had to be installed first and the URL loaded in a deferred manner. Facebook example below.

     - Parameter url: The deeplink URL to process.

     ```
     if launchOptions?[UIApplication.LaunchOptionsKey.url] == nil {
         FBSDKAppLinkUtility.fetchDeferredAppLink { (url, error) in
             if let error = error {
                 print("Received error while fetching deferred app link: \(error)")
             }
             if let url = url {
                 SwrveSDK.handleDeferredDeeplink(url)
             }
         }
     }

     ```
     */
    @objc public class func handleDeferredDeeplink(_ url: URL) {
        checkInstance()
        sharedInstance.handleDeferredDeeplink(url)
    }

    /**
     Used to determine if Ad install. Property set in SwrveDeeplinkManager. Facebook example below.
     Instead of calling handleDeferredDeeplink:url, you can set an installAction and call openURL:url.

     - Parameter url: The deeplink URL to process.

     ```
     if launchOptions?[UIApplication.LaunchOptionsKey.url] == nil {
         FBSDKAppLinkUtility.fetchDeferredAppLink { (url, error) in
             if let error = error {
                 print("Received error while fetching deferred app link: \(error)")
             }
             if let url = url {
                 SwrveSDK.installAction(url)
                 UIApplication.shared.open(url, options: [:], completionHandler: nil)
             }
         }
     }

     ```
     */
    @objc public class func installAction(_ url: URL) {
        checkInstance()
        sharedInstance.installAction(url)
    }
    /**
     Identify users such that they can be tracked and targeted safely across multiple devices, platforms and channels.
     Throws NSException if called in SwrveInitMode.MANAGED mode.

     - Parameters:
     - externalUserId: An ID that uniquely identifies your user. Personal identifiable information should not be used. An error may be returned if such information is submitted
     as the userID eg email, phone number etc.
     - onSuccess: Success callback block.
     - onError: Error callback block.



     ```
     SwrveSDK.identify("12345", onSuccess: { (status, swrveUserId) in
         // Handle success here
     }, onError: { (httpCode, errorMessage) in
         // Please note in the event of an error the tracked userId will not reflect correctly on the backend until this
         // call completes successfully
     })
     ```
     */
    @objc public class func identify(
        _ externalUserId: String, onSuccess: @escaping (String?, String?) -> Void, onError: @escaping (Int, String?) -> Void
    ) {
        checkInstance()
        sharedInstance.identify(externalUserId, onSuccess: onSuccess, onError: onError)
    }
    /**
     An ID that uniquely identifies your user. Personal identifiable information should not be used.
     An error may be returned if such information is submitted as the externalUserId eg email, phone number etc.

     - Returns: The externalUserId for the current user.

     Remark: See the identify API call.
     */

    @objc public class func externalUserId() -> String {
        checkInstance()
        return sharedInstance.externalUserId()
    }

    /**
     Start the SDK if stopped or in SwrveInitMode (Managed) mode.
     Tracking will begin using the last user or an auto generated userId if the first time the SDK is started.
     */

    @objc public class func start() {
        checkInstance()
        sharedInstance.start()
    }

    /**
     Start the SDK when in SwrveInitMode (Managed) mode.
     Tracking will begin using the userId passed in.
     Can be called multiple times to switch the current userId to something else. A new session is started if not already
     started or if is already started with different userId.
     The SDK will remain started until the createInstance is called again.
     Throws NSException if called in SwrveInitMode (Auto) mode.
     - Parameter withUserId: User id to start SDK with.
     */

    @objc(startWithUserId:) public class func start(withUserId: String) {
        checkInstance()
        sharedInstance.start(withUserId: withUserId)
    }
    /**
     Check if the SDK has been started.

     - Returns: True when in SwrveInitMode (Auto) mode. When in SwrveInitMode (Managed) mode it will return true after one of the 'start' APIs has been called.
     */

    @objc public class func started() -> Bool {
        checkInstance()
        return sharedInstance.started()
    }
    /**
     Stop the SDK from tracking. The SDK will remain stopped until a start API is called.
     */
    @objc public class func stopTracking() {
        checkInstance()
        sharedInstance.stopTracking()
    }

    // Messaging
    /**
     Inform that an embedded message has been served and processed. This function should be called
     by your implementation to update the campaign information and send the appropriate data to
     Swrve.

     - Parameter message: Embedded message that has been processed.
     */
    @objc public class func embeddedControlMessageImpressionEvent(_ message: SwrveEmbeddedMessage) {
        checkInstance()
        sharedInstance.embeddedControlMessageImpressionEvent(message)
    }

    @objc(embeddedMessageWasShownToUser:) public class func embeddedMessageWasShown(toUser message: SwrveEmbeddedMessage) {
        checkInstance()
        sharedInstance.embeddedMessageWasShown(toUser: message)
    }

    /**
     Process an embedded message engagement event. This function should be called by your
     implementation to inform Swrve of a button event.

     - Parameters:
     - message: Embedded message that has been processed.
     - button: Button that was pressed.
     */
    @objc public class func embeddedButtonWasPressed(_ message: SwrveEmbeddedMessage, buttonName button: String) {
        checkInstance()
        sharedInstance.embeddedButtonWasPressed(message, buttonName: button)
    }

    /**
     Get the personalized data string from a SwrveEmbeddedMessage campaign with a map of custom
     personalization properties.

     - Parameters:
     - message: Embedded message campaign to personalize.
     - personalizationProperties: Custom properties which are used for personalization.
     Returns: The data string with personalization properties applied. Null is returned if personalization fails with the custom properties passed in.
     */
    @objc public class func personalizeEmbeddedMessageData(
        _ message: SwrveEmbeddedMessage, withPersonalization personalizationProperties: [String: Any]
    )
        -> String?
    {
        checkInstance()
        return sharedInstance.personalizeEmbeddedMessageData(message, withPersonalization: personalizationProperties)
    }

    /**
     Get the personalized data string from a piece of text with a map of custom personalization properties.


     - Parameters:
     - text: String value which will be personalized.
     - personalizationProperties: Custom properties which are used for personalization.
     Returns: The data string with personalization properties applied. Null is returned if personalization fails with the custom properties passed in.

     */
    @objc public class func personalizeText(_ text: String, withPersonalization personalizationProperties: [String: Any]) -> String? {
        checkInstance()
        return sharedInstance.personalizeText(text, withPersonalization: personalizationProperties)
    }

    /**
     Get the list of active Message Center campaigns targeted for this user.
     It will exclude campaigns that have been deleted with the
     removeCampaign method and those that do not support the current orientation.

     To obtain all Message Center campaigns independent of their orientation support
     use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.

     - Returns: List of active Message Center campaigns.
     */

    @objc public class func messageCenterCampaigns() -> [SwrveCampaign] {
        checkInstance()
        return sharedInstance.messageCenterCampaigns()
    }

    /**
     Get the list of active Message Center campaigns targeted for this user and might have personalization that can be resolved.
     It will exclude campaigns that have been deleted with the
     removeCampaign method and those that do not support the current orientation.

     To obtain all Message Center campaigns independent of their orientation support
     use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.

     - Parameter personalization: Personalization properties for in-app messages.
     - Returns: List of active Message Center campaigns.
     */

    @objc public class func messageCenterCampaigns(withPersonalization personalization: [String: Any]) -> [SwrveCampaign] {
        checkInstance()
        return sharedInstance.messageCenterCampaigns(withPersonalization: personalization)
    }

    /**
     Get Message Center campaign targeted for this user and might have personalization that can be resolved.
     It will exclude campaigns that have been deleted with the removeCampaign method and those that do not support
     the current orientation.

     - Parameters:
     - personalization: Personalization properties for in-app messages.
     - campaignID: ID of campaign.
     Returns: The active MessageCenter campaign is returned if campaign ID is valid. Returns null if the campaign ID is invalid or campaign is not active.
     */

    @objc public class func messageCenterCampaign(withID campaignID: UInt, andPersonalization personalization: [String: Any]) -> SwrveCampaign? {
        checkInstance()
        return sharedInstance.messageCenterCampaign(withID: campaignID, andPersonalization: personalization)
    }

    #if os(iOS)
        /**
     Get the list of active Message Center campaigns targeted for this user.
     It will exclude campaigns that have been deleted with the
     removeCampaign method and those that do not support the given orientation.

     - Parameter orientation: Required orientation.
     - Returns: List of active Message Center campaigns that support the given orientation.
     */

        @objc(messageCenterCampaignsThatSupportOrientation:) public class func messageCenterCampaignsThatSupport(
            _ orientation: UIInterfaceOrientation
        ) -> [SwrveCampaign] {
            checkInstance()
            return sharedInstance.messageCenterCampaignsThatSupport(orientation)
        }

        /**
     Get the list of active Message Center campaigns targeted for this user and might have personalization that can be resolved.
     It will exclude campaigns that have been deleted with the
     removeCampaign method and those that do not support the given orientation.

     - Parameters:
     - orientation: Required orientation.
     - personalization: Personalization properties for in-app messages.
     - Returns: List of active Message Center campaigns that support the given orientation.
     */

        @objc(messageCenterCampaignsThatSupportOrientation:withPersonalization:) public class func messageCenterCampaignsThatSupport(
            _ orientation: UIInterfaceOrientation, withPersonalization personalization: [String: Any]
        ) -> [SwrveCampaign] {
            checkInstance()
            return sharedInstance.messageCenterCampaignsThatSupport(orientation, withPersonalization: personalization)
        }

    #endif

    /**
     Display the given campaign without the need to trigger an event and skipping the configured rules.

     - Parameter campaign: Campaign that will be displayed.
     - Returns: If the campaign was shown.

     */

    @objc(showMessageCenterCampaign:) public class func showMessageCenter(_ campaign: SwrveCampaign) -> Bool {
        checkInstance()
        return sharedInstance.showMessageCenter(campaign)
    }

    /**
     Display the given campaign without the need to trigger an event and skipping the configured rules.

     - Parameters:
     - campaign: Campaign that will be displayed.
     - personalization: Dictionary <String, Any> used to personalize the campaign.
     - Returns: If the campaign was shown.
     */

    @objc(showMessageCenterCampaign:withPersonalization:) public class func showMessageCenter(
        _ campaign: SwrveCampaign, withPersonalization personalization: [String: Any]
    ) -> Bool {
        checkInstance()
        return sharedInstance.showMessageCenter(campaign, withPersonalization: personalization)
    }

    /**
     Remove the given campaign. It won't be returned anymore by the method messageCenterCampaigns.
     - Parameter campaign: Campaign that will be removed.
     */

    @objc(removeMessageCenterCampaign:) public class func removeMessageCenter(_ campaign: SwrveCampaign) {
        checkInstance()
        sharedInstance.removeMessageCenter(campaign)
    }

    /**
     Mark the campaign as seen. This is done automatically by Swrve but you can call this if you are rendering the messages on your own.

     - Parameter campaign: Campaign that will be marked as seen.
     */

    @objc(markMessageCenterCampaignAsSeen:) public class func markMessageCenterCampaign(asSeen campaign: SwrveCampaign) {
        checkInstance()
        sharedInstance.markMessageCenterCampaign(asSeen: campaign)
    }

    /**
     Call this method after getting the IDFA string.
     - Parameter idfa: IDFA identifier.
     */

    @objc public class func idfa(_ idfa: String) {
        checkInstance()
        sharedInstance.idfa(idfa)
    }

    /**
     Call this method to programmatically dismiss an in-app message
     */
    @objc public class func dismissMessageWindow() {
        checkInstance()
        sharedInstance.dismissMessageWindow()
    }

}

extension SwrveSDK {
    @objc class func resetSwrveSharedInstance() {
        if sharedInstance != nil {
            sharedInstance.shutdown()
            sharedInstance = nil
        }
        SwrveCommon.addSharedInstance(nil)
        sharedInstanceToken = 0
    }

    @objc class func addSharedInstance(_ instance: Swrve) {
        if sharedInstanceToken == 0 {
            sharedInstance = instance
            sharedInstanceToken = 1
        }
    }
}

extension SwrveSDK {

    /// Get the list of messages in the current user's Push Inbox.
    ///
    /// - Returns: An array of SwrvePushInboxMessage objects.
    @objc public class func pushInboxMessages() -> [SwrvePushInboxMessage] {
        sharedInstance.pushInboxMessages()
    }

    /// Mark the Push Inbox Message as read. This is an asynchronous operation and the listener will be called when the
    /// operation is complete. Check the returned result object for success or failure.
    ///
    /// - Parameters:
    ///   - messageId: The messageId of the SwrvePushInboxMessage to update as read.
    ///   - listener: The listener to trigger after this operation has completed.
    @objc public class func readPushInboxMessage(_ messageId: UInt64, listener: SwrvePushInboxDelegate) {
        sharedInstance.readPushInboxMessage(messageId, listener: listener)
    }

    /// Delete the Push Inbox Message. This is an asynchronous operation and the listener will be called when the
    /// operation is complete. Check the returned result object for success or failure.
    ///
    /// - Parameters:
    ///   - messageId: The messageId of the SwrvePushInboxMessage to delete.
    ///   - listener: The listener to trigger after this operation has completed.
    @objc public class func deletePushInboxMessage(_ messageId: UInt64, listener: SwrvePushInboxDelegate) {
        sharedInstance.deletePushInboxMessage(messageId, listener: listener)
    }

    /// Mark the Push Inbox Message as read and send engagement event. This is an asynchronous operation and the
    /// listener will be called when the operation is complete. Check the returned result object for success or failure.
    ///
    /// - Parameters:
    ///   - messageId: The messageId of the SwrvePushInboxMessage to update as read and engaged.
    ///   - listener: The listener to trigger after this operation has completed.
    @objc public class func engagePushInboxMessage(_ messageId: UInt64, listener: SwrvePushInboxDelegate) {
        sharedInstance.engagePushInboxMessage(messageId, listener: listener)
    }

    /// The pushInboxUpdateListener messagesUpdated() method is invoked when Push Inbox messages
    /// have been initially loaded and each time messages are updated/changed.
    ///
    /// - Parameter listener: Called when the push inbox messages are initially loaded and each time messages are updated/changed.
    @objc public class func pushInboxUpdateListener(_ listener: SwrvePushInboxUpdateDelegate) {
        sharedInstance.pushInboxUpdateListener(listener)
    }

}

#if canImport(ActivityKit)

    extension SwrveSDK {

        /**
     Starts observing an activity with specified attributes. Please note that Live Activity being started with empty actvity id will not be tracked.

     - Parameter attributeType: A attributes type of activity which must conform to SwrveLiveActivityAttributes.
     - Returns: Void.

     - Usages:
         ```
        SwrveSDK.registerLiveActivity(ofType: MyAttributes.self)

         ```
     */

        @available(iOS 16.2, *)
        public class func registerLiveActivity<T: SwrveLiveActivityAttributes>(
            ofType attributesType: T.Type
        ) {
            SwrveLiveActivity.registerActivity(ofType: attributesType)
        }

    }

#endif
