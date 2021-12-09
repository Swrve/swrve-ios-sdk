#import "SwrvePermissionsDelegate.h"
#import "SwrveSessionDelegate.h"
#import "SwrveLogger.h"
#import <UIKit/UIKit.h>

/*! Swrve SDK shared protocol (interface) definition */
@protocol SwrveCommonDelegate <NSObject>

@required
- (int)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload triggerCallback:(bool)triggerCallback;
- (int)userUpdate:(NSDictionary *)attributes;
- (BOOL)processPermissionRequest:(NSString *)action;
- (void)sendQueuedEvents;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;
- (void)mergeWithCurrentDeviceInfo:(NSDictionary *)attributes;
- (void)handleNotificationToCampaign:(NSString *)campaignId;
- (void)fetchNotificationCampaigns:(NSMutableSet *)campaignIds;

- (NSString *)swrveSDKVersion;
- (NSString *)appVersion;
- (NSSet *)notificationCategories;
- (NSString *)appGroupIdentifier;
- (NSString *)userID;
- (NSDictionary *)deviceInfo;
- (void)sendPushNotificationEngagedEvent:(NSString *)pushId;
- (id <SwrvePermissionsDelegate>)permissionsDelegate;
- (double)flushRefreshDelay;
- (NSInteger)nextEventSequenceNumber;
- (NSString *)sessionToken;
- (void)setSwrveSessionDelegate:(id<SwrveSessionDelegate>)sessionDelegate;

@optional
- (id <NSURLSessionDelegate>)urlSessionDelegate;

@property(atomic, readonly) long appID;
@property(atomic, readonly) NSString* deviceToken;
@property(atomic, readonly) NSString *apiKey;
@property(atomic, readonly) NSString *eventsServer;
@property(atomic, readonly) NSString *contentServer;
@property(atomic, readonly) NSString *identityServer;
@property(atomic, readonly) NSString *joined;
@property(atomic, readonly) NSString *language;
@property(atomic, readonly) int httpTimeout;
@property(atomic, readonly) NSString *deviceUUID;

@end

@interface SwrveCommon : NSObject

+(id<SwrveCommonDelegate>) sharedInstance;
+(void) addSharedInstance:(id<SwrveCommonDelegate>)swrveCommon;
+(BOOL)supportedOS;
+(UIApplication *) sharedUIApplication NS_EXTENSION_UNAVAILABLE_IOS("");
@end

#define NullableNSString(x) ((x == nil)? [NSNull null] : x)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

/*! Result codes for Swrve methods. */
enum
{
    SWRVE_SUCCESS = 0,  /*!< Method executed successfully. */
    SWRVE_FAILURE = -1  /*!< Method did not execute successfully. */
};

enum
{
    SWRVE_CAMPAIGN_LOCATION = 0
};

enum  {
    SWRVE_RESOURCE_FILE,
    SWRVE_RESOURCE_DIFF_FILE,
    SWRVE_CAMPAIGN_FILE,
    SWRVE_AD_CAMPAIGN_FILE,
    SWRVE_NOTIFICATION_CAMPAIGN_FILE_DEBUG,
    SWRVE_NOTIFICATION_CAMPAIGNS_FILE,
    SWRVE_REAL_TIME_USER_PROPERTIES_FILE
};

#define KB(x) (1024*(x))
#define MB(x) (1024*KB((x)))

enum
{
    // The API version of this file.
    // This is sent to the server on each call, and should not be modified.
    SWRVE_VERSION = 3,

    // Initial size of the in-memory queue
    // Tweak this to avoid fragmenting memory when the queue is growing.
    SWRVE_MEMORY_QUEUE_INITIAL_SIZE = 16,

    // This is the largest number of bytes that the in-memory queue will use
    // If more than this number of bytes are used, the entire queue will be written
    // to disk, and the queue will be emptied.
    SWRVE_MEMORY_QUEUE_MAX_BYTES = KB(100),

    // This is the largest size that the disk-cache persists between runs of the
    // application. The file may grow larger than this size over a very long run
    // of the app, but then next time the app is run, the file will be truncated.
    // To avoid losing data, you should allow enough disk space here for your app's
    // messages.
    SWRVE_DISK_MAX_BYTES = MB(4),

    // Flush frequency for automatic campaign/user resources updates
    SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_FREQUENCY = 60000,

    // Delay between flushing events and refreshing campaign/user resources
    SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_REFRESH_DELAY = 5000,
};
