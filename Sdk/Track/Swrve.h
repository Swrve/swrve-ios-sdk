#import "SwrveMessageController.h"
#import "SwrveInterfaceOrientation.h"
#import "SwrveReceiptProvider.h"
#import "SwrveResourceManager.h"
#import "SwrveSignatureProtectedFile.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"

#ifdef DEBUG
#define DebugLog( s, ... ) NSLog(s, ##__VA_ARGS__)
#else
#define DebugLog( s, ... )
#endif

#pragma clang diagnostic pop

/*! The release version of this SDK. */
#define SWRVE_SDK_VERSION "3.4"

/*! Result codes for Swrve methods. */
enum
{
    SWRVE_SUCCESS = 0,  /*!< Method executed successfully. */
    SWRVE_FAILURE = -1  /*!< Method did not execute successfully. */
};

/*! Defines the block signature for receiving resources after calling
 * Swrve getUserResources.
 *
 * \param resources         A dictionary containing the resources.
 * \param resourcesAsJSON   A string containing the resources as returned by the Swrve REST API.
 */
typedef void (^SwrveUserResourcesCallback) (NSDictionary* resources,
                                            NSString * resourcesAsJSON);

/*! Defines the block signature for receiving resouces after calling
 * Swrve getUserResourcesDiff.
 *
 * \param oldResourcesValues    A dictionary containing the old values of changed resources.
 * \param oldResourcesValues    A dictionary containing the new values of changed resources.
 * \param resourcesAsJSON       A string containing the resources diff as returned by the Swrve REST API.
 */
typedef void (^SwrveUserResourcesDiffCallback) (NSDictionary * oldResourcesValues,
                                                NSDictionary * newResourcesValues,
                                                NSString * resourcesAsJSON);

/*! Defines the block signature for notifications when an event is raised.
 * Typically used internally.
 *
 * \param eventPayload          A dictionary containing the event payload.
 * \param eventsPayloadAsJSON   A string containing the event payload encoded as JSON.
 */
typedef void (^SwrveEventQueuedCallback) (NSDictionary * eventPayload,
                                          NSString * eventsPayloadAsJSON);

/*! SwrveIAPRewards contains additional IAP rewards that you want to send to Swrve.
 *
 * If the IAP represents a bundle containing a few reward items and/or
 * in-app currencies you can create a SwrveIAPRewards object and call
 * addCurrency: and addItem: for each element contained in the bundle.
 * By including this when recording an IAP event with Swrve you will be able to track
 * individual bundle items as well as the bundle purchase itself.
 */
@interface SwrveIAPRewards : NSObject

/*! Add a purchased item
 *
 * \param resourceName The name of the resource item with which the user was rewarded.
 * \param quantity The quantity purchased
 */
- (void) addItem:(NSString*) resourceName withQuantity:(long) quantity;

/*! Add an in-app currency purchase
 *
 * \param currencyName The name of the in-app currency with which the user was rewarded.
 * \param amount The amount of in-app currency with which the user was rewarded.
 */
- (void) addCurrency:(NSString*) currencyName withAmount:(long) amount;


/*! Obtain all rewards.
 *
 * \returns All rewards added up until now.
 */
- (NSDictionary*) rewards;

@end

/*! Defines the block signature for being notified when the resources
 * have been updated with new content.
 */
typedef void (^SwrveResourcesUpdatedListener) ();

/*! Advanced configuration for the Swrve SDK. */
@interface SwrveConfig : NSObject

/*! The supported orientations of the app. */
@property (nonatomic) SwrveInterfaceOrientation orientation;

/*! By default Swrve will read the application version from the current
 * application bundle. This is used to allow you to test and target users with a
 * particular application version.
 * If you use a different application versioning system than you can specify
 * this here. If you are doing this please contact the Swrve team.
 */
@property (nonatomic, retain) NSString * appVersion;

/*! Swrve will read the language from the current device using the [NSLocale preferredLanguages] API.
 * If your app has a custom mechanism to allow users to change their language, then you should set this property.
 *
 * The language value here should be a valid IETF language tag.
 * See http://en.wikipedia.org/wiki/IETF_language_tag .
 *
 * Typical values are codes such as en_US, en_GB or fr_FR.
 */
@property (nonatomic, retain) NSString * language;

/*! Controls if resources and in-app messages are automatically downloaded.
 */
@property (nonatomic) BOOL autoDownloadCampaignsAndResources;

/* Controls if Swrve in-app messaging is enabled. */
@property (nonatomic) BOOL talkEnabled;

/* Default in-app background color used if none is specified in the template */
@property (nonatomic, retain) UIColor* defaultBackgroundColor;

/*! A callback to get notified when user resources have been updated.
 *
 * If config.autoDownloadCampaignsAndResources is YES (default) user resources will be kept up to date automatically
 * and this listener will be called whenever there has been a change.
 * Instead of using the listener, you could use the SwrveResourceManager ([swrve getResourceManager]) to get
 * the latest value for each attribute at the time you need it. Resources and attributes in the resourceManager
 * are kept up to date.
 *
 * When config.autoDownloadCampaignsAndResources is NO resources will not be kept up to date, and you will have
 * to manually call refreshCampaignsAndResources - which will call this listener on completion.
 *
 * This listener does not have any argument, use the resourceManager to get the updated resources
 */
@property (nonatomic, copy) SwrveResourcesUpdatedListener resourcesUpdatedCallback;

/*! Controls if sendEvents is automatically called when the app resumes
 * in the foreground.
 */
@property (nonatomic) BOOL autoSendEventsOnResume;

/*! Controls if saveEvents is automatically called when the app resigns to the background.
 */
@property (nonatomic) BOOL autoSaveEventsOnResign;

/*! Controls if push notifications are enabled. */
@property (nonatomic) BOOL pushEnabled;

/*! The set of Swrve events that will trigger push notifications. */
@property (nonatomic, retain) NSSet* pushNotificationEvents;

/*! Controls if the SDK automatically collects the push device token. To
 * manually set the device token yourself set to NO.
 */
@property (nonatomic) BOOL autoCollectDeviceToken;

/*! Set of iOS8+ interactive push notification categories (UIMutableUserNotificationCategory).
 * Initialize this set only if running on an iOS8+ device with the interactive actions that
 * your app supports for push notifications. Will be used when registering for
 * push notification permissions with UIUserNotificationSettings. 
 */
@property (nonatomic, copy) NSSet* pushCategories;

/*! Maximum delay for in-app messages to appear after initialization. */
@property (nonatomic) long autoShowMessagesMaxDelay;

/*! Specify the number of seconds to wait before considering a request as 'timed out'.
 * Typically a value between 5 and 20 seconds should suffice.
 */
@property (nonatomic) int httpTimeoutSeconds;

/*! Set to override the default location of the server to which Swrve will send analytics events.
 * If your company has a special API end-point enabled, then you should specify it here.
 * You should only need to change this value if you are working with Swrve support on a specific support issue.
 */
@property (nonatomic, retain) NSString * eventsServer;

/*! Use HTTPS for the event API endpoint.
 */
@property (nonatomic) BOOL useHttpsForEventServer;

/*! Set to override the default location of the server from which Swrve will receive personalized content.
 * If your company has a special API end-point enabled, then you should specify it here.
 * You should only need to change this value if you are working with Swrve support on a specific support issue.
 */
@property (nonatomic, retain) NSString * contentServer;

/*! Use HTTPS for the in-app and user resources API endpoint.
 */
@property (nonatomic) BOOL useHttpsForContentServer;

/*! The event cache stores data that has not yet been sent to Swrve.
 * If you plan to change this please contact the team at Swrve who will be happy to help you out.
 * This path should be located in app/Libraries/Caches/, as this is where Apple
 * recommend that persistent data should be stored. http://bit.ly/nCe9Zy
 */
@property (nonatomic, retain) NSString * eventCacheFile;

/*! Store signature to verify content of eventCacheFile. */
@property (nonatomic, retain) NSString * eventCacheSignatureFile;

/*! The user resources cache stores the result of calls to Swrve getUserResources
 * so that the results can be used when the device is offline.
 * If you plan to change this please contact the team at Swrve who will be happy to help you out.
 * This path should be located in app/Libraries/Caches/, as this is where Apple
 * recommend that persistent data should be stored. http://bit.ly/nCe9Zy
 */
@property (nonatomic, retain) NSString * userResourcesCacheFile;

/*! Store signature to verify content of userResourcesCacheFile. */
@property (nonatomic, retain) NSString * userResourcesCacheSignatureFile;

/*! The user resources diff cache stores the result of calls to Swrve getUserResourcesDiff
 * so that the results can be used when the device is offline.
 * If you plan to change this please contact the team at Swrve who will be happy to help you out.
 * This path should be located in app/Libraries/Caches/, as this is where Apple
 * recommend that persistent data should be stored. http://bit.ly/nCe9Zy
 */
@property (nonatomic, retain) NSString * userResourcesDiffCacheFile;

/*! Store signature to verify content of userResourcesDiffCacheFile. */
@property (nonatomic, retain) NSString * userResourcesDiffCacheSignatureFile;

/*! The install-time cache caches the time that the user first installed the app.
 * If you plan to change this please contact the team at Swrve who will be happy to help you out.
 * This path should be located in app/Libraries/Caches/, as this is where Apple
 * recommend that persistent data should be stored. http://bit.ly/nCe9Zy
 */
@property (nonatomic, retain) NSString * installTimeCacheFile;

/*! Maximum number of simultaneous asset downloads for Swrve in-app messages.
 */
@property (nonatomic) int maxConcurrentDownloads;

/*! Internal Only.
 * Used to get a base64 encoded string of the receipt associated
 * with a StoreKit SKPaymentTransaction.
 * This is exposed to the config object to allow dependency injection for testing
 * in isolation and for mocking.
 */
@property (nonatomic, retain) SwrveReceiptProvider* receiptProvider;

/*! Used for testing. Please do not use this property. */
@property (nonatomic) BOOL testBuffersActivated;

@end

/*! Immutable copy of a SwrveConfig object */
@interface ImmutableSwrveConfig : NSObject

- (id)initWithSwrveConfig:(SwrveConfig*)config;
@property (nonatomic, readonly) SwrveInterfaceOrientation orientation;
@property (nonatomic, readonly) int httpTimeoutSeconds;
@property (nonatomic, readonly) NSString * eventsServer;
@property (nonatomic, readonly) BOOL useHttpsForEventServer;
@property (nonatomic, readonly) NSString * contentServer;
@property (nonatomic, readonly) BOOL useHttpsForContentServer;
@property (nonatomic, readonly) NSString * language;
@property (nonatomic, readonly) NSString * eventCacheFile;
@property (nonatomic, readonly) NSString * eventCacheSignatureFile;
@property (nonatomic, readonly) NSString * userResourcesCacheFile;
@property (nonatomic, readonly) NSString * userResourcesCacheSignatureFile;
@property (nonatomic, readonly) NSString * userResourcesDiffCacheFile;
@property (nonatomic, readonly) NSString * userResourcesDiffCacheSignatureFile;
@property (nonatomic, readonly) NSString * installTimeCacheFile;
@property (nonatomic, readonly) NSString * appVersion;
@property (nonatomic, readonly) SwrveReceiptProvider* receiptProvider;
@property (nonatomic, readonly) int maxConcurrentDownloads;
@property (nonatomic, readonly) BOOL autoDownloadCampaignsAndResources;
@property (nonatomic, readonly) BOOL talkEnabled;
@property (nonatomic, readonly) UIColor* defaultBackgroundColor;
@property (nonatomic, readonly) SwrveResourcesUpdatedListener resourcesUpdatedCallback;
@property (nonatomic, readonly) BOOL autoSendEventsOnResume;
@property (nonatomic, readonly) BOOL autoSaveEventsOnResign;
@property (nonatomic, readonly) BOOL pushEnabled;
@property (nonatomic, readonly) NSSet* pushNotificationEvents;
@property (nonatomic, readonly) BOOL autoCollectDeviceToken;
@property (nonatomic, readonly) NSSet* pushCategories;
@property (nonatomic, readonly) long autoShowMessagesMaxDelay;
@property (nonatomic, readonly) BOOL testBuffersActivated;

@end

/*! Swrve SDK main class. */
@interface Swrve : NSObject<SwrveSignatureErrorListener>

#pragma mark -
#pragma mark Singleton

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
 * \returns An initialized Swrve object.
 */
+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey;

/*! Creates and initializes the shared Swrve singleton.
 * The userID is used by Swrve to identify unique users. It must be unique for all users
 * of your app. The default user ID is a random UUID.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveUserID The unique user id for your application.
 * \returns An initialized Swrve object.
 */
+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID;

/*! Creates and initializes the shared Swrve singleton.
 *
 * Takes a SwrveConfig object that can be used to change default settings.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveConfig The swrve configuration object used to override default settings.
 * \returns An initialized Swrve object.
 */
+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig;

/*! Creates and initializes the shared Swrve singleton.
 *
 * Takes a SwrveConfig object that can be used to change default settings.
 * The userID is used by Swrve to identify unique users. It must be unique for all users
 * of your app. The default user ID is a random UUID.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveConfig The swrve configuration object used to override default settings.
 * \param swrveUserID The unique user id for your application.
 * \returns An initialized Swrve object.
 */
+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig;

#pragma mark -
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
 * The userID is used by Swrve to identify unique users. It must be unique for all users
 * of your app. The default user ID is a random UUID.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveUserID The unique user id for your application.
 * \returns An initialized Swrve object.
 */
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID;

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

/*! Initializes a Swrve object that has already been allocated using [Swrve alloc].
 *
 * Takes a SwrveConfig object that can be used to change default settings.
 * The userID is used by Swrve to identify unique users. It must be unique for all users
 * of your app. The default user ID is a random UUID.
 *
 * \param swrveAppID The App ID for your app supplied by Swrve.
 * \param swrveAPIKey The secret token for your app supplied by Swrve.
 * \param swrveUserID The unique user id for your application.
 * \param swrveConfig The swrve configuration object used to override default settings.
 * \returns An initialized Swrve object.
 */
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig;

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

/*! Sends the user state to Swrve.
 * See the REST API docs for the user event for a detailed description of the
 * semantics of this call.
 *
 * \param attributes The attributes to be set for the user.
 * \returns SWRVE_SUCCESS if the call was successful, otherwise SWRVE_ERROR.
 */
-(int) userUpdate:(NSDictionary*)attributes;

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
-(SwrveResourceManager*) getSwrveResourceManager;

/*! Gets a list of resources for a user including modifications from active
 * A/B tests.  Please refer to our online documentation for more details:
 *
 * http://dashboard.swrve.com/help/docs/abtest_api#GetUserResources
 *
 * This function issues an asynchronous HTTP request to the Swrve content server
 * specified in SwrveConfig. This function will return immediately, and the
 * callback will be fired at some unspecified time in the future. The callback
 * will be fired after the Swrve server has sent some AB-Test modifications to
 * the SDK, or if the HTTP request fails (when the iOS device is offline or has
 * limited connectivity.
 *
 * The result of this call is cached in the userResourcesCacheFile specified in
 * SwrveConfig. This file is initially seeded with "[]", the empty JSON array.
 *
 * \param callbackBlock A callback block that will be called asynchronously when
 *                      A/B test data is available.
 */
-(void) getUserResources:(SwrveUserResourcesCallback)callbackBlock;

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
-(void) getUserResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock;

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

/*! Used internally to detect if the app is in the background.
 */
-(BOOL) appInBackground;

#pragma mark -
#pragma mark Properties

@property (atomic, readonly, strong) ImmutableSwrveConfig * config;           /*!< Configuration for this Swrve object */
@property (atomic, readonly)         long appID;                              /*!< App ID used to initialize this Swrve object. */
@property (atomic, readonly)         NSString * apiKey;                       /*!< Secret token used to initialize this Swrve object. */
@property (atomic, readonly)         NSString * userID;                       /*!< User ID used to initialize this Swrve object. */
@property (atomic, readonly)         NSDictionary * deviceInfo;               /*!< Information about the current device. */
@property (atomic, readonly)         SwrveMessageController * talk;           /*!< In-app message component. */
@property (atomic, readonly)         SwrveResourceManager * resourceManager;  /*!< Can be queried for up-to-date resource attribute values. */

@end
