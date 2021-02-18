#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import "SwrveConfig.h"
#import "SwrveIAPRewards.h"
#import "SwrveResourceManager.h"
#import "SwrveMessageController.h"
#import "SwrveDeeplinkManager.h"

#if __has_include(<SwrveSDKCommon/SwrveSignatureProtectedFile.h>)
#import <SwrveSDKCommon/SwrveSignatureProtectedFile.h>
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
#import <UserNotifications/UserNotifications.h>
#endif /*!defined(SWRVE_NO_PUSH) */
#else
#import "SwrveSignatureProtectedFile.h"
#import "SwrveLocalStorage.h"
#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
#import <UserNotifications/UserNotifications.h>
#endif /*!defined(SWRVE_NO_PUSH) */
#endif

/*! The release version of this SDK. */
#define SWRVE_SDK_VERSION "6.8.1"

/*! Defines the block signature for receiving resources after calling
 * Swrve userResources.
 *
 * \param resources         A dictionary containing the resources.
 * \param resourcesAsJSON   A string containing the resources as returned by the Swrve REST API.
 */
typedef void (^SwrveUserResourcesCallback) (NSDictionary* resources,
NSString * resourcesAsJSON);

/*! Defines the block signature for receiving resouces after calling
 * Swrve userResourcesDiff.
 *
 * \param oldResourcesValues    A dictionary containing the old values of changed resources.
 * \param newResourcesValues    A dictionary containing the new values of changed resources.
 * \param resourcesAsJSON       A string containing the resources diff as returned by the Swrve REST API.
 */
typedef void (^SwrveUserResourcesDiffCallback) (NSDictionary * oldResourcesValues,
NSDictionary * newResourcesValues,
NSString * resourcesAsJSON);

/*! Defines the block signature for receiving real time user properties after calling
 *  Swrve realTimeUserProperties
 *
 * \param properties         A dictionary containing the properties.
 */
typedef void (^SwrveRealTimeUserPropertiesCallback) (NSDictionary* properties);

/*! Defines the block signature for notifications when an event is raised.
 * Typically used internally.
 *
 * \param eventPayload          A dictionary containing the event payload.
 * \param eventsPayloadAsJSON   A string containing the event payload encoded as JSON.
 */
typedef void (^SwrveEventQueuedCallback) (NSDictionary * eventPayload,
NSString * eventsPayloadAsJSON);

// Main SDK protocol (implemented by Swrve and SwrveEmpty)
@protocol Swrve <NSObject>

#pragma mark Initialization

/*! Initializes a Swrve object that has already been allocated using [Swrve alloc].
 *
 * The default user ID is a random UUID. The userID is cached in the
 * default settings of the app and recalled the next time you initialize the
 * app. This means the ID for the user will stay consistent for as long as the
 * user has your app installed on the device.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \returns An initialized Swrve object.
 */
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey;

/*! Initializes a Swrve object that has already been allocated using [Swrve alloc].
 *
 * Takes a SwrveConfig object that can be used to change default settings.
 * The userID is used by Swrve to identify unique users. It must be unique for all users
 * of your app. The default user ID is a random UUID.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveConfig The swrve configuration object used to override default settings.
 * \returns An initialized Swrve object.
 */
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig;

#pragma mark -
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
-(int) purchaseItem:(NSString*)itemName currency:(NSString*)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity;

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
-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product;

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
-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product rewards:(SwrveIAPRewards*)rewards;

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
-(int) unvalidatedIap:(SwrveIAPRewards*)rewards localCost:(double)localCost localCurrency:(NSString*)localCurrency productId:(NSString*)productId productIdQuantity:(int)productIdQuantity;

/*! Call this to send a named custom event with no payload.
 *
 * \param eventName The quantity of the item being purchased.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
-(int) event:(NSString*)eventName;

/*! Call this to send a named custom event with no payload.
 *
 * \param eventName The quantity of the item being purchased.
 * \param eventPayload The payload to be sent with this event.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
-(int) event:(NSString*)eventName payload:(NSDictionary*)eventPayload;

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
-(int) currencyGiven:(NSString*)givenCurrency givenAmount:(double)givenAmount;

/*! Sends a group of custom user properties to Swrve.
 * See the REST API docs for the user event for a detailed description of the
 * semantics of this call.
 *
 * \param attributes The attributes to be set for the user.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
-(int) userUpdate:(NSDictionary*)attributes;

/*! Sends a single Date based custom user property to Swrve
 *
 * See the REST API docs for the user event for a detailed description of the
 * semantics of this call.
 *
 * \param name The identifier for the user update
 * \param date The NSDate value associated
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
-(int) userUpdate:(NSString *)name withDate:(NSDate *) date;

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
-(void) refreshCampaignsAndResources;

/*! Use the resource manager to retrieve the most up-to-date attribute
 * values at any time.
 *
 * \returns Resource manager.
 */
-(SwrveResourceManager*) resourceManager;

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
-(void) userResources:(SwrveUserResourcesCallback)callbackBlock;

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
-(void) userResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock;

/*! Gets a dictionary of real time user properties for a user
 *
 *
 * The result of this call is cached in the realTimeUserPropertiesFile specified in
 * SwrveConfig. This file is initially seeded with "[]", the empty JSON Dictionary.
 *
 * \param callbackBlock A callback block that will be called asynchronously when
 *                      A/B test data is available.
 */
-(void) realTimeUserProperties:(SwrveRealTimeUserPropertiesCallback)callbackBlock;

#pragma mark -
#pragma mark Other

/*! Sends all events that are queued to the Swrve servers.
 * If any events cannot be send they will be re-queued and sent again later.
 */
-(void) sendQueuedEvents;

/*! Saves events stored in the in-memory queue to disk.
 * After calling this function, the in-memory queue will be empty.
 */
-(void) saveEventsToDisk;

/*! Sets the event queue callback. If set, the callback block will be called each
 * time an event is queued with the SDK.
 *
 * \param callbackBlock Block to be executed once per event added to the queue.
 */
-(void) setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock;

/*! Similar to #event:payload: except the callback block will not be called
 * when the event is queued.
 */
-(int) eventWithNoCallback:(NSString*)eventName payload:(NSDictionary*)eventPayload;

/*! Releases all resources used by the Swrve object.
 * Typically, this should only be called if you are managing multiple Swrve instances.
 * Once called, it is not safe to call any methods on the Swrve object.
 */
-(void) shutdown;

#pragma mark - push support block
#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS

/*! Call this method when you get a push notification device token from Apple.
 *
 * \param deviceToken Apple device token for your app.
 */
-(void)setDeviceToken:(NSData*)deviceToken;

/*! Obtain the current push notification device token. */
-(NSString*)deviceToken;

/*! Called to send the push engaged event to Swrve. */
-(void) sendPushNotificationEngagedEvent:(NSString*)pushId;

/**! Should be included to a push response if not using SwrvePushResponseDelegate **/
- (void) processNotificationResponse:(UNNotificationResponse *)response __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);

/*! Process the push notification in the background. The completion handler is called if a silent push notification was received with the
 *  fetch result and the custom payloads as parameters.
 *
 * \param userInfo Push information.
 * \param completionHandler Completion handler, only called for silent push notifications.
 * \returns If a Swrve silent push notification was handled by the Swrve SDK. In that case the payload and calls to the parent completionHandler will have to be done inside the completionHandler parameter.
 */
- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler API_AVAILABLE(ios(7.0));

#endif //!defined(SWRVE_NO_PUSH)

/*! Call this method from application:openURL:option

 @param url The deeplink url to process.

 @code
    - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
        [SwrveSDK handleDeeplink:url];
        return YES;
    }
 @endcode
*/
- (void)handleDeeplink:(NSURL *)url;

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
- (void)handleDeferredDeeplink:(NSURL *)url;

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
- (void)installAction:(NSURL *)url;

/*! The userID is used by Swrve to identify unique users. It must be unique for all users of your app. If not specified the SDK will assign a random UUID to this device.

 @return  The userID for the current user

 @remark To set a userID please refer to the identify api call
 */
- (NSString *)userID;

/*! Identify users such that they can be tracked and targeted safely across multiple devices, platforms and channels.

 @param externalUserId An ID that uniquely identifies your user. Personal identifiable information should not be used. An error may be returned if such information is submitted as the externalUserId eg email, phone number etc.
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
- (void)identify:(NSString *)externalUserId onSuccess:(void (^)(NSString *status, NSString *swrveUserId))onSuccess
                                              onError:(void (^)(NSInteger httpCode, NSString *errorMessage))onError;

/*! An ID that uniquely identifies your user. Personal identifiable information should not be used. An error may be returned if such information is submitted as the externalUserId eg email, phone number etc.

 @return  The externalUserId for the current user

  @remark See the indentify API call

 */
- (NSString *)externalUserId;

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
- (void)setCustomPayloadForConversationInput:(NSMutableDictionary *)payload;

/*! Start the sdk when in SWRVE_INIT_MODE_MANAGED mode.
 * Tracking will begin using the last user or an auto generated userId if the first time the sdk is started.
 * Throws NSException if called in SWRVE_INIT_MODE_AUTO mode.
 */
- (void)start;

/*! Start the sdk when in SWRVE_INIT_MODE_MANAGED mode.
 * Tracking will begin using the userId passed in.
 * Can be called multiple times to switch the current userId to something else. A new session is started if not already
 * started or if is already started with different userId.
 * The sdk will remain started until the createInstance is called again.
 * Throws NSException if called in SWRVE_INIT_MODE_AUTO mode.
 * @param userId User id to start sdk with..
 */
- (void)startWithUserId:(NSString *)userId;

/*! Check if the SDK has been started.
 * @return true when in SWRVE_INIT_MODE_AUTO mode. When in SWRVE_INIT_MODE_MANAGED mode it will return true after one of the 'start' api's has been called.
 */
- (BOOL)started;

#pragma mark - Properties

@property (atomic, readonly, strong) ImmutableSwrveConfig * config;           /*!< Configuration for this Swrve object */
@property (atomic, readonly)         long appID;                              /*!< App ID used to initialize this Swrve object. */
@property (atomic, readonly)         NSString * apiKey;                       /*!< Secret token used to initialize this Swrve object. */
@property (atomic, readonly)         SwrveMessageController * messaging;      /*!< In-app message component. */
@property (atomic, readonly)         SwrveResourceManager * resourceManager;  /*!< Can be queried for up-to-date resource attribute values. */
#pragma mark -

@end
