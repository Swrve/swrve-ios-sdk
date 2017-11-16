#import "Swrve.h"

/*! Swrve SDK static access class. */
@interface SwrveSDK : NSObject

/*! Accesses a single shared instance of a Swrve object.
 *
 * \returns A singleton instance of a Swrve object.
 *          This will be nil until one of the sharedInstanceWith... methods is called.
 */
+(Swrve*) sharedInstance;

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
+(void) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey;

/*! Creates and initializes the shared Swrve singleton.
 *
 * Takes a SwrveConfig object that can be used to change default settings.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveConfig The swrve configuration object used to override default settings.
 */
+(void) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig;

/*! Creates and initializes the shared Swrve singleton.
 *
 * The default user ID is a random UUID. The userID is cached in the
 * default settings of the app and recalled the next time you initialize the
 * app. This means the ID for the user will stay consistent for as long as the
 * user has your app installed on the device.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param launchOptions The Application's launchOptions from didFinishLaunchingWithOptions.
 */
+(void) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey launchOptions:(NSDictionary*)launchOptions;

/*! Creates and initializes the shared Swrve singleton.
 *
 * Takes a SwrveConfig object that can be used to change default settings.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveConfig The swrve configuration object used to override default settings.
 * \param launchOptions The Application's launchOptions from didFinishLaunchingWithOptions.
 */
+(void) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig launchOptions:(NSDictionary*)launchOptions;


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
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) purchaseItem:(NSString*)itemName currency:(NSString*)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity;

/*! Call this when the user has bought something using real currency.
 *
 * See the REST API docs for the IAP event for a detailed description of the
 * semantics of this call, noting in particular the format specification for
 * currency.
 *
 * \param transaction The SKPaymentTransaction object received from the iTunes Store.
 * \param product The SDKProduct of the purchased item.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product;

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
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product rewards:(SwrveIAPRewards*)rewards;

/*! Similar to IAP event but does not validate the receipt data server side.
 *
 * \param rewards The SwrveIAPRewards object containing any additional
 *                items or in-app currencies that are part of this purchase.
 * \param localCost The price (in real money) of the product that was purchased.
 *                  Note: this is not the price of the total transaction, but the per-product price.
 * \param localCurrency The name of the currency that the user has spent in real money.
 * \param productId The ID of the IAP item being purchased.
 * \param productIdQuantity The number of product items being purchased (usually 1).
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) unvalidatedIap:(SwrveIAPRewards*)rewards localCost:(double)localCost localCurrency:(NSString*)localCurrency productId:(NSString*)productId productIdQuantity:(int)productIdQuantity;

/*! Call this to send a named custom event with no payload.
 *
 * \param eventName The quantity of the item being purchased.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) event:(NSString*)eventName;

/*! Call this to send a named custom event with no payload.
 *
 * \param eventName The quantity of the item being purchased.
 * \param eventPayload The payload to be sent with this event.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) event:(NSString*)eventName payload:(NSDictionary*)eventPayload;

/*! Call this when the user has been gifted in-app currency by the app itself.
 * See the REST API docs for the currency_given event for a detailed
 * description of the semantics of this call.
 *
 * \param givenCurrency The name of the in-app currency that the player was
 *                      rewarded with.
 * \param givenAmount The amount of in-app currency that the player was
 *                    rewarded with.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) currencyGiven:(NSString*)givenCurrency givenAmount:(double)givenAmount;

/*! Sends a group of custom user properties to Swrve.
 * See the REST API docs for the user event for a detailed description of the
 * semantics of this call.
 *
 * \param attributes The attributes to be set for the user.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) userUpdate:(NSDictionary*)attributes;

/*! Sends a single Date based custom user property to Swrve
 *
 * See the REST API docs for the user event for a detailed description of the
 * semantics of this call.
 *
 * \param name The identifier for the user update
 * \param date The NSDate value associated
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
+(int) userUpdate:(NSString *)name withDate:(NSDate *) date;

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
+(void) refreshCampaignsAndResources;

/*! Use the resource manager to retrieve the most up-to-date attribute
 * values at any time.
 *
 * \returns Resource manager.
 */
+(SwrveResourceManager*) resourceManager;

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
+(void) userResources:(SwrveUserResourcesCallback)callbackBlock;

/*! Gets a list of resource differences that should be applied to items for the
 * given user based on the A/B test the user is involved in.  Please refer to
 * our online documentation for more details:
 *
 * http://dashboard.swrve.com/help/docs/abtest_api#GetUserResourcesDiff
 *
 * This function issues an asynchronous HTTP request to the Swrve content server
 * specified in #swrve_init. This function will return immediately, and the
 * callback will be fired at some unspecified time in the future. The callback
 * will be fired after the Swrve server has sent some AB-Test modifications to
 * the SDK, or if the HTTP request fails (when the iOS device is offline or has
 * limited connectivity.
 *
 * The resulting AB-Test data is cached in the userResourcesDiffCacheFile specified in
 * SwrveConfig. This file is initially seeded with "[]", the empty JSON array.
 *
 * \param callbackBlock A callback block that will be called asynchronously when
 *                      A/B test data is available.
 */
+(void) userResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock;

#pragma mark -
#pragma mark Other

/*! Sends all events that are queued to the Swrve servers.
 * If any events cannot be send they will be re-queued and sent again later.
 */
+(void) sendQueuedEvents;

/*! Saves events stored in the in-memory queue to disk.
 * After calling this function, the in-memory queue will be empty.
 */
+(void) saveEventsToDisk;

/*! Sets the event queue callback. If set, the callback block will be called each
 * time an event is queued with the SDK.
 *
 * \param callbackBlock Block to be executed once per event added to the queue.
 */
+(void) setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock;

/*! Similar to #event:payload: except the callback block will not be called
 * when the event is queued.
 */
+(int) eventWithNoCallback:(NSString*)eventName payload:(NSDictionary*)eventPayload;

/*! Releases all resources used by the Swrve object.
 * Typically, this should only be called if you are managing multiple Swrve instances.
 * Once called, it is not safe to call any methods on the Swrve object.
 */
+(void) shutdown;

#pragma mark - push support block
#if !defined(SWRVE_NO_PUSH)

/*! Call this method when you get a push notification device token from Apple.
 *
 * \param deviceToken Apple device token for your app.
 */
+(void)setDeviceToken:(NSData*)deviceToken;

/*! Obtain the current push notification device token. */
+(NSString*)deviceToken;

/*! Process the given push notification.
 *
 * \param userInfo Push notification information.
 */
+(void)pushNotificationReceived:(NSDictionary*)userInfo;

/*! Process the push notification in the background. The completion handler is called if a silent push notification was received with the
 *  fetch result and the custom payloads as parameters.
 *
 * \param userInfo Push information.
 * \param completionHandler Completion handler, only called for silent push notifications.
 * \returns If a Swrve silent push notification was handled by the Swrve SDK. In that case the payload and calls to the parent completionHandler will have to be done inside the completionHandler parameter.
 */
+ (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler;

/*! Called to send the push engaged event to Swrve. */
+(void) sendPushEngagedEvent:(NSString*)pushId;

/**! Should be included to a push response if not using SwrvePushResponseDelegate **/
+(void) processNotificationResponse:(UNNotificationResponse *)response;

/**! Pre-iOS10 push notification response processing **/
+(void) processNotificationResponseWithIdentifier:(NSString *)identifier andUserInfo:(NSDictionary *)userInfo;

#endif //!defined(SWRVE_NO_PUSH)

/*!< Configuration for this Swrve object */
+(ImmutableSwrveConfig *) config;

/*!< App ID used to initialize this Swrve object. */
+(long) appID;

/*!< Secret token used to initialize this Swrve object. */
+(NSString *) apiKey;

/*!< User ID used to initialize this Swrve object. */
+(NSString *) userID;

/*!< In-app message component. */
+(SwrveMessageController*) messaging;

@end
