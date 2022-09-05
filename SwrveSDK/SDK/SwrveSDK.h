#import "Swrve.h"

NS_ASSUME_NONNULL_BEGIN
/*! Swrve SDK static access class. */
@interface SwrveSDK : NSObject

/*! Accesses a single shared instance of a Swrve object.
 *
 * \returns A singleton instance of a Swrve object.
 *          This will be nil until one of the sharedInstanceWith... methods is called.
 */
+ (nullable Swrve *)sharedInstance;

/*! Creates and initializes the shared Swrve singleton.
 *
 * The default user ID is a random UUID. The userID is cached in the
 * default settings of the app and recalled the next time you initialize the
 * app. This means the ID for the user will stay consistent for as long as the
 * user has your app installed on the device.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 */
+ (void)sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString *)swrveAPIKey;

/*! Creates and initializes the shared Swrve singleton.
 *
 * Takes a SwrveConfig object that can be used to change default settings.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveConfig The swrve configuration object used to override default settings.
 */
+ (void)sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString *)swrveAPIKey config:(SwrveConfig *)swrveConfig;

#pragma mark Events

/*! Call this when an in-app item is purchased.
 * The currency specified must be one of the currencies known to Swrve that are
 * specified on the Swrve dashboard.
 * See the REST API docs for the purchase event for a detailed description of the
 * semantics of this call.
 *
 * \param itemName The UID of the item being purchased.
 * \param itemCurrency The name of the currency used to purchase the item.
 * \param itemCost The per-item cost of the item being purchased.
 * \param itemQuantity The quantity of the item being purchased.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)purchaseItem:(NSString *)itemName currency:(NSString *)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity;

/*! Call this when the user has bought something using real currency.
 *
 * See the REST API docs for the IAP event for a detailed description of the
 * semantics of this call, noting in particular the format specification for
 * currency.
 *
 * \param transaction The SKPaymentTransaction object received from the iTunes Store.
 * \param product The SDKProduct of the purchased item.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)iap:(SKPaymentTransaction *)transaction product:(SKProduct *)product;

/*!
 * Call this when the user has bought something using real currency.
 * Include the virtual item and currency given to the user in rewards.
 *
 * See the REST API docs for the IAP event for a detailed description of the
 * semantics of this call, noting in particular the format specification for
 * currency.
 *
 * \param rewards The SwrveIAPRewards object containing any additional
 *        items or in-app currencies that are part of this purchase.
 * \param product The SDKProduct of the purchased item.
 * \param transaction The SKPaymentTransaction object received from the iTunes Store.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)iap:(SKPaymentTransaction *)transaction product:(SKProduct *)product rewards:(SwrveIAPRewards *)rewards;

/*! Similar to IAP event but does not validate the receipt data server side.
 *
 * \param rewards The SwrveIAPRewards object containing any additional
 *                items or in-app currencies that are part of this purchase.
 * \param localCost The price (in real money) of the product that was purchased.
 *                  Note: this is not the price of the total transaction, but the per-product price.
 * \param localCurrency The name of the currency that the user has spent in real money.
 * \param productId The ID of the IAP item being purchased.
 * \param productIdQuantity The number of product items being purchased (usually 1).
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)unvalidatedIap:(SwrveIAPRewards *)rewards localCost:(double)localCost localCurrency:(NSString *)localCurrency productId:(NSString *)productId productIdQuantity:(int)productIdQuantity;

/*! Call this to send a named custom event with no payload.
 *
 * \param eventName The quantity of the item being purchased.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)event:(NSString *)eventName;

/*! Call this to send a named custom event with no payload.
 *
 * \param eventName The quantity of the item being purchased.
 * \param eventPayload The payload to be sent with this event.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)event:(NSString *)eventName payload:(NSDictionary *)eventPayload;

/*! Call this when the user has been gifted in-app currency by the app itself.
 * See the REST API docs for the currency_given event for a detailed
 * description of the semantics of this call.
 *
 * \param givenCurrency The name of the in-app currency that the player was
 *                      rewarded with.
 * \param givenAmount The amount of in-app currency that the player was
 *                    rewarded with.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)currencyGiven:(NSString *)givenCurrency givenAmount:(double)givenAmount;

/*! Sends a group of custom user properties to Swrve.
 * See the REST API docs for the user event for a detailed description of the
 * semantics of this call.
 *
 * \param attributes The attributes to be set for the user.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)userUpdate:(NSDictionary *)attributes;

/*! Sends a single Date based custom user property to Swrve
 *
 * See the REST API docs for the user event for a detailed description of the
 * semantics of this call.
 *
 * \param name The identifier for the user update
 * \param date The NSDate value associated
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_FAILURE.
 */
+ (int)userUpdate:(NSString *)name withDate:(NSDate *)date;

#pragma mark -
#pragma mark User Resources

/*! If SwrveConfig.autoDownloadCampaignsAndResources is YES (default value) this function is called
 * automatically to keep the user resources and campaign data up to date.
 *
 * Use the resourceManager to get the latest up-to-date values for the resources.
 *
 * If SwrveConfig.autoDownloadCampaignsAndResources is set to NO, please call this function to update
 * values. This function issues an asynchronous HTTP request to the Swrve content server
 * specified in SwrveConfig. This function will return immediately, and the
 * callback will be fired after the Swrve server has sent its response. At this point
 * the resourceManager can be used to retrieve the updated resource values.
 */
+ (void)refreshCampaignsAndResources;

/*! Use the resource manager to retrieve the most up-to-date attribute
 * values at any time.
 *
 * \returns Resource manager.
 */
+ (SwrveResourceManager *)resourceManager;

/*! Gets a list of resources for a user including modifications from active
 * A/B tests.  Please refer to our online documentation for more details:
 *
 * http://dashboard.swrve.com/help/docs/abtest_api#GetUserResources
 *
 * This function will return immediately, and the callback will be fired right
 * away with the already present AB test data.
 *
 * The result of this call is cached in the userResourcesCacheFile specified in
 * SwrveConfig. This file is initially seeded with "[]", the empty JSON array.
 *
 * \param callbackBlock A callback block that will be called asynchronously when
 *                      A/B test data is available.
 */
+ (void)userResources:(SwrveUserResourcesCallback)callbackBlock;

/*! Gets the user resource differences that should be applied to items for the
 * given user based on the A/B test the user is involved in.  Please refer to
 * our online documentation for more details:
 *
 * https://docs.swrve.com/swrves-apis/api-guides/swrve-ab-test-api-guide/#Get_user_resources_diff
 *
 * This function issues an asynchronous HTTP request to the Swrve content server
 * specified in #swrve_init. This function will return immediately, and the
 * callback may be fired at some unspecified time in the future. The callback
 * will be fired after the Swrve server has sent some AB-Test modifications to
 * the SDK, or if the HTTP request fails (when the iOS device is offline or has
 * limited connectivity.
 *
 * \param listener A listener block that will be called (usually asynchronously) with results.
 */
+ (void)userResourcesDiffWithListener:(SwrveUserResourcesDiffListener)listener;

/*! Gets a dictionary of real time user properties
 * This function will return immediately, and the callback will be fired right
 * away with the already present AB test data.
 *
 * \param callbackBlock A callback block that will be called asynchronously when real time user
 * properties become available
 *
*/
+ (void)realTimeUserProperties:(SwrveRealTimeUserPropertiesCallback)callbackBlock;

#pragma mark -
#pragma mark Other

/*! Sends all events that are queued to the Swrve servers.
 * If any events cannot be send they will be re-queued and sent again later.
 */
+ (void)sendQueuedEvents;

/*! Saves events stored in the in-memory queue to disk.
 * After calling this function, the in-memory queue will be empty.
 */
+ (void)saveEventsToDisk;

/*! Sets the event queue callback. If set, the callback block will be called each
 * time an event is queued with the SDK.
 *
 * \param callbackBlock Block to be executed once per event added to the queue.
 */
+ (void)setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock;

/*! Similar to #event:payload: except the callback block will not be called
 * when the event is queued.
 */
+ (int)eventWithNoCallback:(NSString *)eventName payload:(NSDictionary *)eventPayload;

/*! Releases all resources used by the Swrve object.
 * Typically, this should only be called if you are managing multiple Swrve instances.
 * Once called, it is not safe to call any methods on the Swrve object.
 */
+ (void)shutdown;

#pragma mark - push support block
#if TARGET_OS_IOS

/*! Call this method when you get a push notification device token from Apple.
 *
 * \param deviceToken Apple device token for your app.
 */
+ (void)setDeviceToken:(NSData *)deviceToken;

/*! Obtain the current push notification device token. */
+ (nullable NSString *)deviceToken;

/*! Process the push notification in the background. The completion handler is called if a silent push notification was received with the
 *  fetch result and the custom payloads as parameters.
 *
 * \param userInfo Push information.
 * \param completionHandler Completion handler, only called for silent push notifications.
 * \returns If a Swrve silent push notification was handled by the Swrve SDK. In that case the payload and calls to the parent completionHandler will have to be done inside the completionHandler parameter.
 */
+ (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler API_AVAILABLE(ios(7.0));

/*! Called to send the push engaged event to Swrve. */
+ (void)sendPushEngagedEvent:(NSString *)pushId;

/**! Should be included to a push response if not using SwrvePushResponseDelegate **/
+ (void)processNotificationResponse:(UNNotificationResponse *)response __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);

#endif //TARGET_OS_IOS

/*!< Configuration for this Swrve object */
+ (ImmutableSwrveConfig *)config;

/*!< App ID used to initialize this Swrve object. */
+ (long)appID;

/*!< Secret token used to initialize this Swrve object. */
+ (NSString *)apiKey;

/*!< User ID used to initialize this Swrve object. */
+ (NSString *)userID;

/*! Call this method from application:openURL:option
 
 @param url The deeplink url to process.
 
 @code
 - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [SwrveSDK handleDeeplink:url];
    return YES;
 }
 @endcode
*/
+ (void)handleDeeplink:(NSURL *)url;

/*! This method is used to inform SDK that the App had to be installed first and the url loaded in a deferred manner. Facebook example below.
 
 @param url The deeplink url to process.
 
 @code
    if (launchOptions[UIApplicationLaunchOptionsURLKey] == nil) {
        [FBSDKAppLinkUtility fetchDeferredAppLink:^(NSURL *url, NSError *error) {
        if (error) {
            NSLog(@"Received error while fetching deferred app link %@", error);
        }
        if (url) {
            [SwrveSDK handleDeferredDeeplink:url];
        }
        }];
    }
 @endcode
*/
+ (void)handleDeferredDeeplink:(NSURL *)url;

/*! Used to determine if Ad install. Property set in SwrveDeeplinkManager. Facebook example below. Instead of calling handleDeferredDeeplink:url, you can set an installAction and call openURL:url
 
 @param url The deeplink url to process.
 
 @code
    if (launchOptions[UIApplicationLaunchOptionsURLKey] == nil) {
        [FBSDKAppLinkUtility fetchDeferredAppLink:^(NSURL *url, NSError *error) {
        if (error) {
            NSLog(@"Received error while fetching deferred app link %@", error);
        }
        if (url) {
            [SwrveSDK installAction];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
        }];
    }
 @endcode
*/
+ (void)installAction:(NSURL *)url;

/*! Identify users such that they can be tracked and targeted safely across multiple devices, platforms and channels.
 * Throws NSException if called in SwrveInitMode.MANAGED mode.

 @param externalUserId An ID that uniquely identifies your user. Personal identifiable information should not be used. An error may be returned if such information is submitted as the userID eg email, phone number etc.
 @param onSuccess block.
 @param onError block.
 
 @code
 [SwrveSDK identify:@"12345" onSuccess:^(NSString *status, NSString *swrveUserId) {
 
 } onError:^(NSInteger httpCode, NSString *errorMessage) {
    // please note in the event of an error the tracked userId will not reflect correctly on the backend until this
    // call completes successfully
 }];
 @endcode
 */
+ (void)identify:(NSString *)externalUserId
       onSuccess:(nullable void (^)(NSString *status, NSString *swrveUserId))onSuccess
         onError:(nullable void (^)(NSInteger httpCode, NSString *errorMessage))onError;

/*! An ID that uniquely identifies your user. Personal identifiable information should not be used. An error may be returned if such information is submitted as the externalUserId eg email, phone number etc.
 
 @return  The externalUserId for the current user
 
 @remark See the indentify API call
 
 */
+ (NSString *)externalUserId;

/*! Add a custom payload for user input events.
    Selecting a star-rating,
    Selecting a choice on a text questionnaire
    Selecting play on a video
 
 @param payload NSMutableDictionary with custom key pair values.
 @note  If key pair values added is greater than 5 or Keys added conflict with existing swrve internal keys then
 the custom payload will be rejected and not added for the event. A debug log error will be generated.
 @code
 NSMutableDictionary *myPayload =  [[NSMutableDictionary alloc] initWithDictionary:@{
 @"key1":@"value2",
 @"key2": @"value2",
 }];
 
 [SwrveSDK setCustomPayloadForConversationInput:myPayload];
 @endcode
 */
+ (void)setCustomPayloadForConversationInput:(NSMutableDictionary *)payload;

/*! Start the sdk if stopped or in SWRVE_INIT_MODE_MANAGED mode.
 * Tracking will begin using the last user or an auto generated userId if the first time the sdk is started.
 */
+ (void)start;

/*! Start the sdk when in SWRVE_INIT_MODE_MANAGED mode.
 * Tracking will begin using the userId passed in.
 * Can be called multiple times to switch the current userId to something else. A new session is started if not already
 * started or if is already started with different userId.
 * The sdk will remain started until the createInstance is called again.
 * Throws NSException if called in SWRVE_INIT_MODE_AUTO mode.
 * @param userId User id to start sdk with..
 */
+ (void)startWithUserId:(NSString *)userId;

/*! Check if the SDK has been started.
 * @return true when in SWRVE_INIT_MODE_AUTO mode. When in SWRVE_INIT_MODE_MANAGED mode it will return true after one of the 'start' api's has been called.
 */
+ (BOOL)started;

/*!
 * Stop the SDK from tracking. The sdk will remain stopped until a start api is called.
 */
+ (void)stopTracking;

#pragma mark Messaging

/*! Inform that am embedded message has been served and processed. This function should be called
 * by your implementation to update the campaign information and send the appropriate data to
 * Swrve.
 *
 * \param message embedded message that has been processed
 */
+ (void)embeddedMessageWasShownToUser:(SwrveEmbeddedMessage *)message;

/*! Process an embedded message engagement event. This function should be called by your
 * implementation to inform Swrve of a button event.
 *
 * \param message embedded message that has been processed
 * \param button  button that was pressed
 */
+ (void)embeddedButtonWasPressed:(SwrveEmbeddedMessage *)message buttonName:(NSString *)button;

/*! Get the personalized data string from a SwrveEmbeddedMessage campaign with a map of custom
 * personalization properties.
 *
 * \param message Embedded message campaign to personalize
 * \param personalizationProperties  personalizationProperties Custom properties which are used for personalization.
 * \return The data string with personalization properties applied. Null is returned if personalization fails with the custom properties passed in.
 */
+ (NSString *)personalizeEmbeddedMessageData:(SwrveEmbeddedMessage *)message withPersonalization:(NSDictionary *)personalizationProperties;

/*! Get the personalized data string from a piece of text with a map of custom personalization properties.
 *
 * \param text String value which will be personalized
 * \param personalizationProperties  personalizationProperties Custom properties which are used for personalization.
 * \return The data string with personalization properties applied. Null is returned if personalization fails with the custom properties passed in.
 */
+ (NSString *)personalizeText:(NSString *)text withPersonalization:(NSDictionary *)personalizationProperties;

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * To obtain all Message Center campaigns independent of their orientation support
 * use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.
 *
 * \returns List of active Message Center campaigns.
 */
+ (NSArray *)messageCenterCampaigns;

/*! Get the list active Message Center campaigns targeted for this user and might have personalization that can be resolved.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * To obtain all Message Center campaigns independent of their orientation support
 * use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.
 *
 * \param personalization Personalization properties for in-app messages.
 * \returns List of active Message Center campaigns.
 */
+ (NSArray *)messageCenterCampaignsWithPersonalization:(NSDictionary *)personalization;

/*! Get Message Center campaign targeted for this user and might have personalization that can be resolved.
 * It will exclude campaigns that have been deleted with the removeCampaign method and those that do not support
 * the current orientation.
 *
 * \param personalization Personalization properties for in-app messages.
 * \param campaignID  ID of campaign
 * \returns The active MessageCenter campaign is returned if campaign id is valid. Returns null if the campaign id is invalid or campaign is not active.
 */
+ (SwrveCampaign *)messageCenterCampaignWithID:(NSUInteger)campaignID andPersonalization:(NSDictionary *)personalization;

#if TARGET_OS_IOS /** exclude tvOS **/

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \param orientation Required orientation.
 * \returns List of active Message Center campaigns that support the given orientation.
 */
+ (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation;

/*! Get the list active Message Center campaigns targeted for this user and might have personalization that can be resolved.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \param orientation Required orientation.
 * \param personalization Personalization properties for in-app messages.
 * \returns List of active Message Center campaigns that support the given orientation.
*/
+ (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation withPersonalization:(NSDictionary *)personalization;

#endif

/*! Display the given campaign without the need to trigger an event and skipping
 * the configured rules.
 * \param campaign Campaign that will be displayed.
 * \returns if the campaign was shown.
 */
+ (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign;

/*! Display the given campaign without the need to trigger an event and skipping
 * the configured rules.
 * \param campaign Campaign that will be displayed.
 * \param personalization Dictionary <String, String> used to personalise the campaign
 * \returns if the campaign was shown.
 */
+ (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign withPersonalization:(NSDictionary *)personalization;

/*! Remove the given campaign. It won't be returned anymore by the method messageCenterCampaigns.
 *
 * \param campaign Campaign that will be removed.
 */
+ (void)removeMessageCenterCampaign:(SwrveCampaign *)campaign;

/*! Mark the campaign as seen. This is done automatically by Swrve but you can call this if you are rendering the messages on your own.
 *
 * \param campaign Campaign that will be marked as seen.
 */
+ (void)markMessageCenterCampaignAsSeen:(SwrveCampaign *)campaign;

/*! Call this method after getting the idfa string.
 *
 * \param idfa IDFA identifier
 */
+ (void)idfa:(NSString *)idfa;

#pragma mark -

@end

NS_ASSUME_NONNULL_END

