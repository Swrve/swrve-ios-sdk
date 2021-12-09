#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SwrveInterfaceOrientation.h"
#import "SwrveConfig.h"
#import "SwrveInAppMessageConfig.h"
#import "SwrveEmbeddedMessageConfig.h"
#import "SwrveReceiptProvider.h"
#import "SwrveDeeplinkDelegate.h"
#if __has_include(<SwrveSDKCommon/SwrvePermissionsDelegate.h>)
#import <SwrveSDKCommon/SwrvePermissionsDelegate.h>
#else
#import "SwrvePermissionsDelegate.h"
#endif

#if TARGET_OS_IOS
#if __has_include(<SwrveSDKCommon/SwrvePush.h>)
#import <SwrveSDKCommon/SwrvePush.h>
#else
#import "SwrvePush.h"
#endif
#endif //TARGET_OS_IOS

/*! Swrve stack names. */
enum SwrveStack {
    SWRVE_STACK_US,
    SWRVE_STACK_EU
};

/*! Swrve init modes.*/
typedef enum {
    /// This is the default mode and automatically tracks when your app appears in the foreground.
            SWRVE_INIT_MODE_AUTO,
    /// This mode should be configured to manage setting the userId and manage how it starts.
    /// See autoStartLastUser configuration also.
            SWRVE_INIT_MODE_MANAGED
} SwrveInitMode;

/*! Defines the block signature for being notified when the resources
 * have been updated with new content.
 */
typedef void (^SwrveResourcesUpdatedListener) (void);

/*! Advanced configuration for the Swrve SDK. */
@interface SwrveConfig : NSObject

/*! The supported orientations of the app. */
@property (nonatomic) SwrveInterfaceOrientation orientation;

/*! By default the app will choose the status bar appearance
 * when presenting any Conversation view controllers.
 * You can force the status bar to be hidden by setting
 * prefersConversationsStatusBarHidden to true.
 */
@property (nonatomic) BOOL prefersConversationsStatusBarHidden;

/*! By default Swrve will read the application version from the current
 * application bundle. This is used to allow you to test and target users with a
 * particular application version.
 * If you use a different application versioning system than you can specify
 * this here. If you are doing this please contact the Swrve team.
 */
@property (nonatomic, retain) NSString *appVersion;

/*! Swrve will read the language from the current device using the [NSLocale preferredLanguages] API.
 * If your app has a custom mechanism to allow users to change their language, then you should set this property.
 *
 * The language value here should be a valid IETF language tag.
 * See http://en.wikipedia.org/wiki/IETF_language_tag .
 *
 * Typical values are codes such as en_US, en_GB or fr_FR.
 */
@property (nonatomic, retain) NSString *language;

/*! Controls if resources and in-app messages are automatically downloaded.
 */
@property (nonatomic) BOOL autoDownloadCampaignsAndResources;

/*! in-app config */
@property (nonatomic, retain) SwrveInAppMessageConfig *inAppMessageConfig;

/*! embedded config */
@property (nonatomic, retain) SwrveEmbeddedMessageConfig *embeddedMessageConfig;

/*! Session timeout time in seconds. User activity after this time will be considered a new session. */
@property (nonatomic) double newSessionInterval;

/*! A callback to get notified when user resources have been updated.
 *
 * If config.autoDownloadCampaignsAndResources is YES (default) user resources will be kept up to date automatically
 * and this listener will be called whenever there has been a change.
 * Instead of using the listener, you could use the SwrveResourceManager ([swrve resourceManager]) to get
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

#if TARGET_OS_IOS
/*! Controls if push notifications are enabled. */
@property (nonatomic) BOOL pushEnabled;

/*! The set of Swrve events that will trigger a provisional push notifications request on iOS12+. If you want to request it at app start set the value to a set with "Swrve.session.start" */
@property (nonatomic, retain) NSSet *provisionalPushNotificationEvents;

/*! The set of Swrve events that will trigger a push notifications request. By default it is set to request the permission at the start of the app. */
@property (nonatomic, retain) NSSet *pushNotificationEvents;

/*! Controls if the SDK automatically collects the push device token. To
 * manually set the device token yourself set to NO.
 */
@property (nonatomic) BOOL autoCollectDeviceToken;

/*! Set of iOS10+ interactive push notification categories (UNUser).
 * Intialise this set only if running on an iOS10+ device with the interactive actions that
 * your app supports for push notifications. Will be used when registering for
 * notification permissions with UNUserNotificationCenter
 */
@property (nonatomic, copy) NSSet *notificationCategories;

/*!
 * This is an optional delegate that can be extended to fire rich push responses from a class of your choice.
 * For this to work effectively, please ensure it is added before Swrve initialisation and initialisation happens
 * before the application has finished loading.
 */
@property (nonatomic, weak) id<SwrvePushResponseDelegate> pushResponseDelegate;

#endif //TARGET_OS_IOS

/*! NSString identifier which refers to the app group that stores settings information.
 *  Intialise this if you are using extensions and want to share data across to swrve.
 *  The appGroupIdentifier must match the one used in the accompanying extension to be shared correctly.
 */
@property (nonatomic, copy) NSString *appGroupIdentifier;

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
@property (nonatomic, retain) NSString *eventsServer;

/*! Set to override the default location of the server from which Swrve will receive personalized content.
 * If your company has a special API end-point enabled, then you should specify it here.
 * You should only need to change this value if you are working with Swrve support on a specific support issue.
 */
@property (nonatomic, retain) NSString *contentServer;

/*! Set to override the default location of the server from which Swrve will Identify users.
 * If your company has a special API end-point enabled, then you should specify it here.
 * You should only need to change this value if you are working with Swrve support on a specific support issue.
 */
@property (nonatomic, retain) NSString *identityServer;

/*! The stack your app resides in.
 */
@property (nonatomic) enum SwrveStack stack;

/*! Default mode is SWRVE_INIT_MODE_AUTO which automatically starts when UI is shown. Set initMode to
 * SWRVE_INIT_MODE_MANAGED to delay starting the sdk until start api is called.
 */
@property(nonatomic) SwrveInitMode initMode;

/*! If true, the sdk will delay starting until the start api is called and the userId is set.
 * Once set, it will autostart when UI is shown. Set to false to force the sdk to always delay tracking until a
 * start api is called.
 */
@property(nonatomic) BOOL autoStartLastUser;

/*! Obtain information about the AB Tests a user is part of.
 */
@property (nonatomic) BOOL abTestDetailsEnabled;

/*! Implement this delegate in your app to be able to report on permissions and use them as message actions.
 */
@property (nonatomic, weak) id <SwrvePermissionsDelegate> permissionsDelegate;

/*!< Implement this delegate to override deeplink handling. */
@property(nonatomic, weak) id <SwrveDeeplinkDelegate> deeplinkDelegate;

/*! Controls if we auto collect and send the IDFV as a device property
 */
@property (nonatomic) BOOL autoCollectIDFV;

/*! implement this delegate to listen to our restclient calls for authentication challenges
 */
@property (nonatomic, weak) id <NSURLSessionDelegate> urlSessionDelegate;

@end

/*! Immutable copy of a SwrveConfig object */
@interface ImmutableSwrveConfig : NSObject

- (id)initWithMutableConfig:(SwrveConfig *)config;
@property (nonatomic, readonly) SwrveInterfaceOrientation orientation;
@property (nonatomic, readonly) BOOL prefersConversationsStatusBarHidden;
@property (nonatomic, readonly) int httpTimeoutSeconds;
@property (nonatomic, readonly) NSString *eventsServer;
@property (nonatomic, readonly) NSString *contentServer;
@property (nonatomic, readonly) NSString *identityServer;
@property (nonatomic, readonly) NSString *language;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) BOOL autoDownloadCampaignsAndResources;
@property (nonatomic, readonly) SwrveInAppMessageConfig *inAppMessageConfig;
@property (nonatomic, readonly) SwrveEmbeddedMessageConfig *embeddedMessageConfig;
@property (nonatomic, readonly) double newSessionInterval;
@property (nonatomic, readonly) SwrveResourcesUpdatedListener resourcesUpdatedCallback;
@property (nonatomic, readonly) BOOL autoSendEventsOnResume;
@property (nonatomic, readonly) BOOL autoSaveEventsOnResign;
#if TARGET_OS_IOS
@property (nonatomic, readonly) BOOL pushEnabled;
@property (nonatomic, readonly) NSSet *provisionalPushNotificationEvents;
@property (nonatomic, readonly) NSSet *pushNotificationEvents;
@property (nonatomic, readonly) BOOL autoCollectDeviceToken;
@property (nonatomic, readonly) NSSet *notificationCategories;
@property (nonatomic, weak, readonly) id<SwrvePushResponseDelegate> pushResponseDelegate;
#endif //TARGET_OS_IOS
@property (nonatomic, readonly) NSString *appGroupIdentifier;
@property (nonatomic, readonly) long autoShowMessagesMaxDelay;
@property (nonatomic, readonly) enum SwrveStack stack;
@property (nonatomic, readonly) SwrveInitMode initMode;
@property(nonatomic, readonly) BOOL autoStartLastUser;
@property (nonatomic) BOOL abTestDetailsEnabled;
@property (nonatomic, weak, readonly) id <SwrvePermissionsDelegate> permissionsDelegate;
@property (nonatomic, weak, readonly) id <SwrveDeeplinkDelegate> deeplinkDelegate;
@property (nonatomic) BOOL autoCollectIDFV;
@property (nonatomic, weak, readonly) id <NSURLSessionDelegate> urlSessionDelegate;

@end
