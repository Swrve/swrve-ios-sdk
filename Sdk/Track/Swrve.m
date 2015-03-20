#if !__has_feature(objc_arc)
    #error Please enable ARC for this project (Project Settings > Build Settings), or add the -fobjc-arc compiler flag to each of the files in the Swrve SDK (Project Settings > Build Phases > Compile Sources)
#endif

#include <sys/time.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Swrve.h"
#import "SwrveCampaign.h"
#import "SwrveSwizzleHelper.h"

#if SWRVE_TEST_BUILD
#define SWRVE_STATIC_UNLESS_TEST_BUILD
#else
#define SWRVE_STATIC_UNLESS_TEST_BUILD static
#endif

#define NullableNSString(x) ((x == nil)? [NSNull null] : x)
#define KB(x) (1024*(x))
#define MB(x) (1024*KB((x)))

enum
{
    // The API version of this file.
    // This is sent to the server on each call, and should not be modified.
    SWRVE_VERSION = 2,

    // Initial size of the in-memory queue
    // Tweak this to avoid fragmenting memory when the queue is growing.
    SWRVE_MEMORY_QUEUE_INITIAL_SIZE = 16,

    // This is the largest number of bytes that the in-memory queue will use
    // If more than this numer of bytes are used, the entire queue will be written
    // to disk, and the queue will be emptied.
    SWRVE_MEMORY_QUEUE_MAX_BYTES = KB(100),

    // This is the largest size that the disk-cache persists between runs of the
    // application. The file may grow larger than this size over a very long run
    // of the app, but then next time the app is run, the file will be truncated.
    // To avoid losing data, you should allow enough disk space here for your app's
    // messages.
    SWRVE_DISK_MAX_BYTES = MB(4),

    // This is the max timeout on a HTTP send before Swrve will kill the connection
    // This is used for sending data to Swrve. For data where the client is reading
    // from Swrve, the timeout is much smaller, and is specified in swrve_config
    // This value of 4000 seconds is the maximum latency seen to api.swrve.com
    // over a 7 day period in July 2013
    SWRVE_SEND_TIMEOUT_SECONDS = 4000,

    // Flush frequency for automatic campaign/user resources updates
    SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_FREQUENCY = 60000,

    // Delay between flushing events and refreshing campaign/user resources
    SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_REFRESH_DELAY = 5000,
};

const static char* swrve_trailing_comma = ",\n";
static NSString* swrve_user_id_key = @"swrve_user_id";
static NSString* swrve_device_token_key = @"swrve_device_token";

typedef void (^ConnectionCompletionHandler)(NSURLResponse* response, NSData* data, NSError* error);

typedef void (*didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)(__strong id,SEL,UIApplication *, NSData*);
typedef void (*didFailToRegisterForRemoteNotificationsWithErrorImplSignature)(__strong id,SEL,UIApplication *, NSError*);

@interface SwrveSendContext : NSObject
@property (atomic, weak)   Swrve* swrveReference;
@property (atomic) long    swrveInstanceID;
@property (atomic, retain) NSArray* buffer;
@property (atomic)         int bufferLength;
@end

@implementation SwrveSendContext
@synthesize swrveReference;
@synthesize swrveInstanceID;
@synthesize buffer;
@synthesize bufferLength;
@end

@interface SwrveSendLogfileContext : NSObject
@property (atomic, weak) Swrve* swrveReference;
@property (atomic) long swrveInstanceID;
@end

@implementation SwrveSendLogfileContext
@synthesize swrveReference;
@synthesize swrveInstanceID;
@end

enum
{
    SWRVE_TRUNCATE_FILE,
    SWRVE_APPEND_TO_FILE,
    SWRVE_TRUNCATE_IF_TOO_LARGE,
};

@interface SwrveConnectionDelegate : NSObject <NSURLConnectionDataDelegate>

@property (atomic, weak) Swrve* swrve;
@property (atomic, retain) NSDate* startTime;
@property (atomic, retain) NSMutableDictionary* metrics;
@property (atomic, retain) NSMutableData* data;
@property (atomic, retain) NSURLResponse* response;
@property (atomic, strong) ConnectionCompletionHandler handler;

- (id)init:(Swrve*)swrve completionHandler:(ConnectionCompletionHandler)handler;

@end

@interface SwrveInstanceIDRecorder : NSObject
{
    NSMutableSet * swrveInstanceIDs;
    long nextInstanceID;
}

+(SwrveInstanceIDRecorder*) sharedInstance;

-(BOOL)hasSwrveInstanceID:(long)instanceID;
-(long)addSwrveInstanceID;
-(void)removeSwrveInstanceID:(long)instanceID;

@end

@interface SwrveResourceManager()

- (void)setResourcesFromArray:(NSArray*)json;

@end

@interface SwrveMessageController()

@property (nonatomic) bool autoShowMessagesEnabled;

-(void) updateCampaigns:(NSDictionary*)campaignJson;
-(NSString*) getCampaignQueryString;
-(void) writeToCampaignCache:(NSData*)campaignData;
-(void) autoShowMessages;

@end

@interface Swrve()
{
    UInt64 install_time;

    SwrveEventQueuedCallback event_queued_callback;

    // Used to retain user-blocks that are passed to C functions
    NSMutableDictionary *   blockStore;
    int                     blockStoreId;

    // The unique id associated with this instance of Swrve
    long    instanceID;

    didRegisterForRemoteNotificationsWithDeviceTokenImplSignature didRegisterForRemoteNotificationsWithDeviceTokenImpl;
    didFailToRegisterForRemoteNotificationsWithErrorImplSignature didFailToRegisterForRemoteNotificationsWithErrorImpl;
}

-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback;
-(void) setupConfig:(SwrveConfig*)config;
+(NSString*) getAppVersion;
-(void) maybeFlushToDisk;
-(void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback;
-(void) removeBlockStoreItem:(int)blockId;
-(void) updateDeviceInfo;
-(void) registerForNotifications;
-(void) appDidBecomeActive:(NSNotification*)notification;
-(void) appWillResignActive:(NSNotification*)notification;
-(void) appWillTerminate:(NSNotification*)notification;
-(void) queueUserUpdates;
-(void) pushNotificationReceived:(NSDictionary*)userInfo;
- (NSString*) createSessionToken;
- (NSString*) createJSON:(NSString*)sessionToken events:(NSString*)rawEvents;
- (NSString*) copyBufferToJson:(NSArray*)buffer;
- (void) sendCrashlyticsMetadata;
- (BOOL) isValidJson:(NSData*) json;
- (void) initResources;
- (UInt64) getInstallTime:(NSString*)fileName;
- (void) sendLogfile;
- (NSOutputStream*) createLogfile:(int)mode;
- (UInt64) getTime;
- (NSString*) createStringWithMD5:(NSString*)source;
- (void) initBuffer;
- (void) addHttpPerformanceMetrics:(NSString*) metrics;
- (void) checkForCampaignAndResourcesUpdates:(NSTimer*)timer;

// Used to store the merged user updates
@property (atomic, strong) NSMutableDictionary * userUpdates;

// Set to YES after the first sessionEnd so that multiple session starts are not generated if the app resume event occurs after swrve has been initialized
@property (atomic) BOOL okToStartSessionOnResume;

// Push notification device token
@property (atomic) NSString* deviceToken;

// Device id, used for tracking event streams from different devices
@property (atomic) NSString* deviceUUID;

// HTTP Request metrics that haven't been sent yet
@property (atomic) NSMutableArray* httpPerformanceMetrics;

// Flush values, ETag and timer for campaigns and resources update request
@property (atomic) NSString* campaignsAndResourcesETAG;
@property (atomic) double campaignsAndResourcesFlushFrequency;
@property (atomic) double campaignsAndResourcesFlushRefreshDelay;
@property (atomic) NSTimer* campaignsAndResourcesTimer;
@property (atomic) NSDate* campaignsAndResourcesLastRefreshed;
@property (atomic) BOOL campaignsAndResourcesInitialized; // Set to true after first call to API returns

// Resource cache files
@property (atomic) SwrveSignatureProtectedFile* resourcesFile;
@property (atomic) SwrveSignatureProtectedFile* resourcesDiffFile;

// An in-memory buffer of messages that are ready to be sent to the Swrve
// server the next time sendQueuedEvents is called.
@property (atomic) NSMutableArray* eventBuffer;

@property (atomic) bool eventFileHasData;
@property (atomic) NSOutputStream* eventStream;
@property (atomic) NSURL* eventFilename;

// Count the number of UTF-16 code points stored in buffer
@property (atomic) int eventBufferBytes;

// keep track of whether any events were sent so we know whether to check for resources / campaign updates
@property (atomic) bool eventsWereSent;

// URLs
@property (atomic) NSURL* batchURL;
@property (atomic) NSURL* campaignsAndResourcesURL;

@end

// Manages unique ids for each instance of Swrve
// This allows low-level c callbacks to know if it is safe to execute their callback functions.
// It is not safe to execute a callback function after a Swrve instance has been deallocated or shutdown.
@implementation SwrveInstanceIDRecorder

+(SwrveInstanceIDRecorder*) sharedInstance
{
    static dispatch_once_t pred;
    static SwrveInstanceIDRecorder *shared = nil;
    dispatch_once(&pred, ^{
        shared = [SwrveInstanceIDRecorder alloc];
    });
    return shared;
}

-(id)init
{
    if (self = [super init]) {
        nextInstanceID = 1;
    }
    return self;
}

-(BOOL)hasSwrveInstanceID:(long)instanceID
{
    @synchronized(self) {
        if (!swrveInstanceIDs) {
            return NO;
        }
        return [swrveInstanceIDs containsObject:[NSNumber numberWithLong:instanceID]];
    }
}

-(long)addSwrveInstanceID
{
    @synchronized(self) {
        if (!swrveInstanceIDs) {
            swrveInstanceIDs = [[NSMutableSet alloc]init];
        }
        long result = nextInstanceID++;
        [swrveInstanceIDs addObject:[NSNumber numberWithLong:result]];
        return result;
    }
}

-(void)removeSwrveInstanceID:(long)instanceID
{
    @synchronized(self) {
        if (swrveInstanceIDs) {
            [swrveInstanceIDs removeObject:[NSNumber numberWithLong:instanceID]];
        }
    }
}

@end


@implementation SwrveConfig

@synthesize orientation;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize useHttpsForEventServer;
@synthesize contentServer;
@synthesize useHttpsForContentServer;
@synthesize language;
@synthesize eventCacheFile;
@synthesize eventCacheSignatureFile;
@synthesize userResourcesCacheFile;
@synthesize userResourcesCacheSignatureFile;
@synthesize userResourcesDiffCacheFile;
@synthesize userResourcesDiffCacheSignatureFile;
@synthesize installTimeCacheFile;
@synthesize appVersion;
@synthesize receiptProvider;
@synthesize maxConcurrentDownloads;
@synthesize autoDownloadCampaignsAndResources;
@synthesize talkEnabled;
@synthesize defaultBackgroundColor;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
@synthesize autoShowMessagesMaxDelay;
@synthesize testBuffersActivated;

-(id) init
{
    if ( self = [super init] ) {
        httpTimeoutSeconds = 15;
        autoDownloadCampaignsAndResources = YES;
        maxConcurrentDownloads = 2;
        orientation = SWRVE_ORIENTATION_BOTH;
        appVersion = [Swrve getAppVersion];
        language = [[NSLocale preferredLanguages] objectAtIndex:0];

        NSString* caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        eventCacheFile = [caches stringByAppendingPathComponent: @"swrve_events.txt"];

        userResourcesCacheFile = [caches stringByAppendingPathComponent: @"srcngt2.txt"];
        userResourcesCacheSignatureFile = [caches stringByAppendingPathComponent: @"srcngtsgt2.txt"];

        userResourcesDiffCacheFile = [caches stringByAppendingPathComponent: @"rsdfngt2.txt"];
        userResourcesDiffCacheSignatureFile = [caches stringByAppendingPathComponent:@"rsdfngtsgt2.txt"];

        self.useHttpsForEventServer = YES;
        self.useHttpsForContentServer = NO;
        self.installTimeCacheFile = [caches stringByAppendingPathComponent: @"swrve_install.txt"];
        self.autoSendEventsOnResume = YES;
        self.autoSaveEventsOnResign = YES;
        self.talkEnabled = YES;
        self.pushEnabled = NO;
        self.pushNotificationEvents = [NSSet setWithObject:@"Swrve.session.start"];
        self.autoCollectDeviceToken = YES;
        self.autoShowMessagesMaxDelay = 5000;
        self.testBuffersActivated = NO;
        self.receiptProvider = [[SwrveReceiptProvider alloc] init];
        self.resourcesUpdatedCallback = ^() {
            // Do nothing by default.
        };
    }
    return self;
}

@end

@implementation ImmutableSwrveConfig

@synthesize orientation;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize useHttpsForEventServer;
@synthesize contentServer;
@synthesize useHttpsForContentServer;
@synthesize language;
@synthesize eventCacheFile;
@synthesize eventCacheSignatureFile;
@synthesize userResourcesCacheFile;
@synthesize userResourcesCacheSignatureFile;
@synthesize userResourcesDiffCacheFile;
@synthesize userResourcesDiffCacheSignatureFile;
@synthesize installTimeCacheFile;
@synthesize appVersion;
@synthesize receiptProvider;
@synthesize maxConcurrentDownloads;
@synthesize autoDownloadCampaignsAndResources;
@synthesize talkEnabled;
@synthesize defaultBackgroundColor;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
@synthesize autoShowMessagesMaxDelay;
@synthesize testBuffersActivated;

- (id)initWithSwrveConfig:(SwrveConfig*)config
{
    if (self = [super init]) {
        orientation = config.orientation;
        httpTimeoutSeconds = config.httpTimeoutSeconds;
        eventsServer = config.eventsServer;
        useHttpsForEventServer = config.useHttpsForEventServer;
        contentServer = config.contentServer;
        useHttpsForContentServer = config.useHttpsForContentServer;
        language = config.language;
        eventCacheFile = config.eventCacheFile;
        eventCacheSignatureFile = config.eventCacheSignatureFile;
        userResourcesCacheFile = config.userResourcesCacheFile;
        userResourcesCacheSignatureFile = config.userResourcesCacheSignatureFile;
        userResourcesDiffCacheFile = config.userResourcesDiffCacheFile;
        userResourcesDiffCacheSignatureFile = config.userResourcesDiffCacheSignatureFile;
        installTimeCacheFile = config.installTimeCacheFile;
        appVersion = config.appVersion;
        receiptProvider = config.receiptProvider;
        maxConcurrentDownloads = config.maxConcurrentDownloads;
        autoDownloadCampaignsAndResources = config.autoDownloadCampaignsAndResources;
        talkEnabled = config.talkEnabled;
        defaultBackgroundColor = config.defaultBackgroundColor;
        resourcesUpdatedCallback = config.resourcesUpdatedCallback;
        autoSendEventsOnResume = config.autoSendEventsOnResume;
        autoSaveEventsOnResign = config.autoSaveEventsOnResign;
        pushEnabled = config.pushEnabled;
        pushNotificationEvents = config.pushNotificationEvents;
        autoCollectDeviceToken = config.autoCollectDeviceToken;
        pushCategories = config.pushCategories;
        autoShowMessagesMaxDelay = config.autoShowMessagesMaxDelay;
        testBuffersActivated = config.testBuffersActivated;
    }

    return self;
}

@end


@interface SwrveIAPRewards()
@property (nonatomic, retain) NSMutableDictionary* rewards;
@end

@implementation SwrveIAPRewards
@synthesize rewards;

- (id) init
{
    self = [super init];
    self.rewards = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) addItem:(NSString*) resourceName withQuantity:(long) quantity
{
    [self addObject:resourceName withQuantity: quantity ofType: @"item"];
}

- (void) addCurrency:(NSString*) currencyName withAmount:(long) amount
{
    [self addObject:currencyName withQuantity:amount ofType:@"currency"];
}

- (void) addObject:(NSString*) name withQuantity:(long) quantity ofType:(NSString*) type
{
    if (![self checkArguments:name andQuantity:quantity andType:type]) {
        DebugLog(@"ERROR: SwrveIAPRewards has not been added because it received an illegal argument", nil);
        return;
    }

    NSDictionary* item = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithLong:quantity], @"amount", type, @"type", nil];
    [[self rewards] setValue:item forKey:name];
}

- (bool) checkArguments:(NSString*) name andQuantity:(long) quantity andType:(NSString*) type
{
    if (name == nil || [name length] <= 0) {
        DebugLog(@"SwrveIAPRewards illegal argument: reward name cannot be empty", nil);
        return false;
    }
    if (quantity <= 0) {
        DebugLog(@"SwrveIAPRewards illegal argument: reward amount must be greater than zero", nil);
        return false;
    }
    if (type == nil || [type length] <= 0) {
        DebugLog(@"SwrveIAPRewards illegal argument: type cannot be empty", nil);
        return false;
    }

    return true;
}

- (NSDictionary*) rewards {
    return rewards;
}

@end


@implementation Swrve

static Swrve * _swrveSharedInstance = nil;
static dispatch_once_t sharedInstanceToken = 0;
static bool didSwizzle = false;

@synthesize config;
@synthesize appID;
@synthesize apiKey;
@synthesize userID;
@synthesize deviceInfo;
@synthesize talk;
@synthesize resourceManager;

@synthesize userUpdates;
@synthesize okToStartSessionOnResume;
@synthesize deviceToken;
@synthesize deviceUUID;
@synthesize httpPerformanceMetrics;
@synthesize campaignsAndResourcesETAG;
@synthesize campaignsAndResourcesFlushFrequency;
@synthesize campaignsAndResourcesFlushRefreshDelay;
@synthesize campaignsAndResourcesTimer;
@synthesize campaignsAndResourcesLastRefreshed;
@synthesize campaignsAndResourcesInitialized;
@synthesize resourcesFile;
@synthesize resourcesDiffFile;
@synthesize eventBuffer;
@synthesize eventFileHasData;
@synthesize eventStream;
@synthesize eventFilename;
@synthesize eventBufferBytes;
@synthesize eventsWereSent;
@synthesize batchURL;
@synthesize campaignsAndResourcesURL;

+ (void) resetSwrveSharedInstance
{
    _swrveSharedInstance = nil;
    sharedInstanceToken = 0;
}

+ (void) addSharedInstance:(Swrve*)instance
{
    _swrveSharedInstance = instance;
    sharedInstanceToken = 1;
}

+(Swrve*) sharedInstance
{
    if (!_swrveSharedInstance) {
        DebugLog(@"Warning: [Swrve sharedInstance] called before sharedInstanceWithAppID:... method.", nil);
    }
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey];
    });
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey userID:swrveUserID];
    });
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig];
    });
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey userID:swrveUserID config:swrveConfig];
    });
    return _swrveSharedInstance;
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey
{
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey userID:nil];
}
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID
{
    // Create a custom config object
    SwrveConfig * newConfig = [[SwrveConfig alloc]init];
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey userID:swrveUserID config:newConfig];
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig
{
   return [self initWithAppID:swrveAppID apiKey:swrveAPIKey userID:nil config:swrveConfig];
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig
{
    NSCAssert(self.config == nil, @"Do not initialize Swrve instance more than once!", nil);
    if ( self = [super init] ) {
        if (self.config) {
            DebugLog(@"Swrve may not be initialized more than once.", nil);
            return self;
        }

        // Auto generate user id if necessary
        if (!swrveUserID) {
            swrveUserID = [[NSUserDefaults standardUserDefaults] stringForKey:swrve_user_id_key];
            if(!swrveUserID) {
                swrveUserID = [[NSUUID UUID] UUIDString];
            }
        }

        instanceID = [[SwrveInstanceIDRecorder sharedInstance] addSwrveInstanceID];
        [self sendCrashlyticsMetadata];

        NSCAssert(swrveConfig, @"Null config object given to Swrve", nil);

        appID = swrveAppID;
        apiKey = swrveAPIKey;
        userID = swrveUserID;

        NSCAssert(appID > 0, @"Invalid app ID given (%ld)", appID);
        NSCAssert(apiKey.length > 1, @"API Key is invalid (too short): %@", apiKey);
        NSCAssert(userID != nil, @"@UserID must not be nil.", nil);

        BOOL didSetUserId = [[NSUserDefaults standardUserDefaults] stringForKey:swrve_user_id_key] == nil;
        [[NSUserDefaults standardUserDefaults] setValue:userID forKey:swrve_user_id_key];

        [self setupConfig:swrveConfig];

        [self setHttpPerformanceMetrics:[[NSMutableArray alloc] init]];

        event_queued_callback = nil;

        blockStore = [[NSMutableDictionary alloc] init];
        blockStoreId = 0;

        config = [[ImmutableSwrveConfig alloc] initWithSwrveConfig:swrveConfig];
        [self initBuffer];
        deviceInfo = [NSMutableDictionary dictionary];

        install_time = [self getInstallTime:swrveConfig.installTimeCacheFile];

        NSURL* base_events_url = [NSURL URLWithString:swrveConfig.eventsServer];
        [self setBatchURL:[NSURL URLWithString:@"1/batch" relativeToURL:base_events_url]];

        NSURL* base_content_url = [NSURL URLWithString:self.config.contentServer];
        [self setCampaignsAndResourcesURL:[NSURL URLWithString:@"api/1/user_resources_and_campaigns" relativeToURL:base_content_url]];

        // Initialize resource cache file and resource manager
        [self initResources];

        [self initResourcesDiff];

        [self setEventFilename:[NSURL fileURLWithPath:swrveConfig.eventCacheFile]];
        [self setEventStream:[self createLogfile:SWRVE_TRUNCATE_IF_TOO_LARGE]];

        // All set up, so start to do any work now.
        self.deviceUUID = [[NSUserDefaults standardUserDefaults] stringForKey:@"swrve_device_id"];
        if (self.deviceUUID == nil) {
            // This is the first time we see this device, assign a UUID to it
            self.deviceUUID = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:self.deviceUUID forKey:@"swrve_device_id"];
        }

        // Set up empty user attributes store
        self.userUpdates = [[NSMutableDictionary alloc]init];
        [self.userUpdates setValue:@"user" forKey:@"type"];
        [self.userUpdates setValue:[[NSMutableDictionary alloc]init] forKey:@"attributes"];

        if(swrveConfig.autoCollectDeviceToken && [Swrve sharedInstance] == self && !didSwizzle){
            Class appDelegateClass = [[UIApplication sharedApplication].delegate class];

            SEL didRegister = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
            SEL didFail = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);

            // Cast to actual method signature
            didRegisterForRemoteNotificationsWithDeviceTokenImpl = (didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)[SwrveSwizzleHelper swizzleMethod:didRegister inClass:appDelegateClass withImplementationIn:self];
            didFailToRegisterForRemoteNotificationsWithErrorImpl = (didFailToRegisterForRemoteNotificationsWithErrorImplSignature)[SwrveSwizzleHelper swizzleMethod:didFail inClass:appDelegateClass withImplementationIn:self];
            didSwizzle = true;
        } else {
            didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;
            didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;
        }
        
        if (swrveConfig.talkEnabled) {
            talk = [[SwrveMessageController alloc]initWithSwrve:self];
        }
        
        [self queueSessionStart];
        [self queueDeviceProperties];

        self.okToStartSessionOnResume = NO;
        [self registerForNotifications];

        // If this is the first time this user has been seen send install analytics
        if(didSetUserId) {
            [self event:@"Swrve.first_session"];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMdd"];
            [self userUpdate:@{ @"swrve.install_date" : [dateFormatter stringFromDate:[self getNow]] } ];
        }

        [self setCampaignsAndResourcesInitialized:NO];

        self.campaignsAndResourcesFlushFrequency = [[NSUserDefaults standardUserDefaults] doubleForKey:@"swrve_cr_flush_frequency"];
        if (self.campaignsAndResourcesFlushFrequency == 0) {
            self.campaignsAndResourcesFlushFrequency = SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_FREQUENCY / 1000;
        }

        self.campaignsAndResourcesFlushRefreshDelay = [[NSUserDefaults standardUserDefaults] doubleForKey:@"swrve_cr_flush_delay"];
        if (self.campaignsAndResourcesFlushRefreshDelay == 0) {
            self.campaignsAndResourcesFlushRefreshDelay = SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_REFRESH_DELAY / 1000;
        }

        [self startCampaignsAndResourcesTimer];
        [self disableAutoShowAfterDelay];
    }

    [self sendQueuedEvents];

    return self;
}

- (void)_deswizzlePushMethods
{
    if( [Swrve sharedInstance] == self && didSwizzle) {
        Class appDelegateClass = [[UIApplication sharedApplication].delegate class];

        SEL didRegister = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [SwrveSwizzleHelper deswizzleMethod:didRegister inClass:appDelegateClass originalImplementation:(IMP)didRegisterForRemoteNotificationsWithDeviceTokenImpl];
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;

        SEL didFail = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        [SwrveSwizzleHelper deswizzleMethod:didFail inClass:appDelegateClass originalImplementation:(IMP)didFailToRegisterForRemoteNotificationsWithErrorImpl];
        didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;

        didSwizzle = false;
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    #pragma unused(application)
    Swrve* swrveInstance = [Swrve sharedInstance];
    if( swrveInstance == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {
        if (swrveInstance.talk != nil) {
            [swrveInstance.talk setDeviceToken:newDeviceToken];
        }

        if( swrveInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl != NULL ) {
            id target = [UIApplication sharedApplication].delegate;
            swrveInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl(target, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), [UIApplication sharedApplication], newDeviceToken);
        }
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    #pragma unused(application)
    Swrve* swrveInstance = [Swrve sharedInstance];
    if( swrveInstance == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {
        DebugLog(@"Could not auto collected device token.", nil);

        if( swrveInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl != NULL ) {
            id target = [UIApplication sharedApplication].delegate;
            swrveInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl(target, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), [UIApplication sharedApplication], error);
        }
    }
}

-(void) queueSessionStart
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [self queueEvent:@"session_start" data:json triggerCallback:true];
}

-(int) sessionStart
{
    [self queueSessionStart];
    [self sendQueuedEvents];
    return SWRVE_SUCCESS;
}

-(int) sessionEnd
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [self queueEvent:@"session_end" data:json triggerCallback:true];
    self.okToStartSessionOnResume = YES;
    return SWRVE_SUCCESS;
}

-(int) purchaseItem:(NSString*)itemName currency:(NSString*)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(itemName) forKey:@"item"];
    [json setValue:NullableNSString(itemCurrency) forKey:@"currency"];
    [json setValue:[NSNumber numberWithInt:itemCost] forKey:@"cost"];
    [json setValue:[NSNumber numberWithInt:itemQuantity] forKey:@"quantity"];
    [self queueEvent:@"purchase" data:json triggerCallback:true];
    return SWRVE_SUCCESS;
}

-(int) event:(NSString*)eventName
{
    return [self eventInternal:eventName payload:nil triggerCallback:true];
}

-(int) event:(NSString*)eventName payload:(NSDictionary*)eventPayload
{
    return [self eventInternal:eventName payload:eventPayload triggerCallback:true];
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product
{
    return [self iap:transaction product:product rewards:nil];
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product rewards:(SwrveIAPRewards*)rewards
{
    NSString* product_id = @"unknown";
    switch(transaction.transactionState) {
        case SKPaymentTransactionStatePurchased:
        {
            if( transaction.payment != nil && transaction.payment.productIdentifier != nil){
                product_id = transaction.payment.productIdentifier;
            }

            NSString* transactionId  = [transaction transactionIdentifier];
            #pragma unused(transactionId)

            SwrveReceiptProviderResult* receipt = [self.config.receiptProvider obtainReceiptForTransaction:transaction];
            if ( !receipt || !receipt.encodedReceipt) {
                DebugLog(@"No transaction receipt could be obtained for %@", transactionId);
                return SWRVE_FAILURE;
            }
            DebugLog(@"Swrve building IAP event for transaction %@ (product %@)", transactionId, product_id);
            NSString* encodedReceipt = receipt.encodedReceipt;
            NSString* localCurrency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
            double localCost = [[product price] doubleValue];

            // Construct the IAP event
            NSString* store = @"apple";
            if( encodedReceipt == nil ) {
                store = @"unknown";
            }
            if ( rewards == nil ) {
                rewards = [[SwrveIAPRewards alloc] init];
            }

            [self maybeFlushToDisk];
            NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
            [json setValue:store forKey:@"app_store"];
            [json setValue:localCurrency forKey:@"local_currency"];
            [json setValue:[NSNumber numberWithDouble:localCost] forKey:@"cost"];
            [json setValue:[rewards rewards] forKey:@"rewards"];
            [json setValue:encodedReceipt forKey:@"receipt"];
            // Payload data
            NSMutableDictionary* eventPayload = [[NSMutableDictionary alloc] init];
            [eventPayload setValue:product_id forKey:@"product_id"];
            [json setValue:eventPayload forKey:@"payload"];
            if ( receipt.transactionId ) {
                // Send transactionId only for iOS7+. This is how the server knows it is an iOS7 receipt!
                [json setValue:receipt.transactionId forKey:@"transaction_id"];
            }
            [self queueEvent:@"iap" data:json triggerCallback:true];

            // After IAP event we want to immediately flush the event buffer and update campaigns and resources if necessary
            if ([self.config autoDownloadCampaignsAndResources]) {
                [self checkForCampaignAndResourcesUpdates:nil];
            }
        }
            break;
        case SKPaymentTransactionStateFailed:
        {
            if( transaction.payment != nil && transaction.payment.productIdentifier != nil){
                product_id = transaction.payment.productIdentifier;
            }
            NSString* error = @"unknown";
            if( transaction.error != nil && transaction.error.description != nil ) {
                error = transaction.error.description;
            }
            [self event:@"Swrve.iap.transaction_failed_on_client" payload: @{@"product_id" : product_id, @"error" : error}];
        }
            break;
        case SKPaymentTransactionStateRestored:
        {
            if( transaction.originalTransaction != nil && transaction.originalTransaction.payment != nil && transaction.originalTransaction.payment.productIdentifier != nil){
                product_id = transaction.originalTransaction.payment.productIdentifier;
            }
            [self event:@"Swrve.iap.restored_on_client" payload: @{@"product_id" : product_id}];
        }
            break;
        default:
            break;
    }

    return SWRVE_SUCCESS;
}

-(int) unvalidatedIap:(SwrveIAPRewards*) rewards localCost:(double) localCost localCurrency:(NSString*) localCurrency productId:(NSString*) productId productIdQuantity:(int) productIdQuantity
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:@"unknown" forKey:@"app_store"];
    [json setValue:localCurrency forKey:@"local_currency"];
    [json setValue:[NSNumber numberWithDouble:localCost] forKey:@"cost"];
    [json setValue:productId forKey:@"product_id"];
    [json setValue:[NSNumber numberWithInteger:productIdQuantity] forKey:@"quantity"];
    [json setValue:[rewards rewards] forKey:@"rewards"];
    [self queueEvent:@"iap" data:json triggerCallback:true];
    // After IAP event we want to immediately flush the event buffer and update campaigns and resources if necessary
    if ([self.config autoDownloadCampaignsAndResources]) {
        [self checkForCampaignAndResourcesUpdates:nil];
    }
    
    return SWRVE_SUCCESS;
}

-(int) currencyGiven:(NSString*)givenCurrency givenAmount:(double)givenAmount
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(givenCurrency) forKey:@"given_currency"];
    [json setValue:[NSNumber numberWithDouble:givenAmount] forKey:@"given_amount"];
    [self queueEvent:@"currency_given" data:json triggerCallback:true];
    return SWRVE_SUCCESS;
}

-(int) userUpdate:(NSDictionary*)attributes
{
    [self maybeFlushToDisk];

    // Merge attributes with current set of attributes
    if (attributes) {
        NSMutableDictionary * currentAttributes = (NSMutableDictionary*)[self.userUpdates objectForKey:@"attributes"];
        [self.userUpdates setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
        for (id attributeKey in attributes) {
            id attribute = [attributes objectForKey:attributeKey];
            [currentAttributes setObject:attribute forKey:attributeKey];
        }
    }

    return SWRVE_SUCCESS;
}

-(SwrveResourceManager*) getSwrveResourceManager
{
    return [self resourceManager];
}

-(void) refreshCampaignsAndResources:(NSTimer*)timer
{
    #pragma unused(timer)
    [self refreshCampaignsAndResources];
}

-(void) refreshCampaignsAndResources
{
    // When campaigns need to be downloaded manually, enforce max. flush frequency
    if (!self.config.autoDownloadCampaignsAndResources) {
        NSDate* now = [self getNow];

        if (self.campaignsAndResourcesLastRefreshed != nil) {
            NSDate* nextAllowedTime = [NSDate dateWithTimeInterval:self.campaignsAndResourcesFlushFrequency sinceDate:self.campaignsAndResourcesLastRefreshed];
            if ([now compare:nextAllowedTime] == NSOrderedAscending) {
                // Too soon to call refresh again
                DebugLog(@"Request to retrieve campaign and user resource data was rate-limited.", nil);
                return;
            }
        }

        self.campaignsAndResourcesLastRefreshed = [self getNow];
    }

    NSMutableString* queryString = [NSMutableString stringWithFormat:@"?user=%@&api_key=%@&app_version=%@&joined=%llu",
                             self.userID, self.apiKey, self.config.appVersion, self->install_time];
    if (self.talk && [self.config talkEnabled]) {
        NSString* campaignQueryString = [self.talk getCampaignQueryString];
        [queryString appendFormat:@"&%@", campaignQueryString];
    }

    NSString* etagValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"campaigns_and_resources_etag"];
    if (etagValue != nil) {
        [queryString appendFormat:@"&etag=%@", etagValue];
    }

    NSURL* url = [NSURL URLWithString:queryString relativeToURL:[self campaignsAndResourcesURL]];
    [self sendHttpGETRequest:url completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        if (!error) {
            NSInteger statusCode = 200;
            enum HttpStatus status = HTTP_SUCCESS;

            NSDictionary* headers = [[NSDictionary alloc] init];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                statusCode = [httpResponse statusCode];
                status = [self getHttpStatus:httpResponse];
                headers = [httpResponse allHeaderFields];
            }

            if (status == SWRVE_SUCCESS) {
                if ([self isValidJson:data]) {
                    NSString* etagHeader = [headers objectForKey:@"ETag"];
                    if (etagHeader != nil) {
                        [[NSUserDefaults standardUserDefaults] setValue:etagHeader forKey:@"campaigns_and_resources_etag"];
                    }

                    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                    NSNumber* flushFrequency = [responseDict objectForKey:@"flush_frequency"];
                    if (flushFrequency != nil) {
                        self.campaignsAndResourcesFlushFrequency = [flushFrequency integerValue] / 1000;
                        [[NSUserDefaults standardUserDefaults] setDouble:self.campaignsAndResourcesFlushFrequency forKey:@"swrve_cr_flush_frequency"];
                    }

                    NSNumber* flushDelay = [responseDict objectForKey:@"flush_refresh_delay"];
                    if (flushDelay != nil) {
                        self.campaignsAndResourcesFlushRefreshDelay = [flushDelay integerValue] / 1000;
                        [[NSUserDefaults standardUserDefaults] setDouble:self.campaignsAndResourcesFlushRefreshDelay forKey:@"swrve_cr_flush_delay"];
                    }

                    if (self.talk && [self.config talkEnabled]) {
                        NSDictionary* campaignJson = [responseDict objectForKey:@"campaigns"];
                        if (campaignJson != nil) {
                            [self.talk updateCampaigns:campaignJson];

                            NSData* campaignData = [NSJSONSerialization dataWithJSONObject:campaignJson options:0 error:nil];
                            [[self talk] writeToCampaignCache:campaignData];

                            [[self talk] autoShowMessages];

                            // Notify campaigns have been downloaded
                            NSMutableArray* campaignIds = [[NSMutableArray alloc] init];
                            for( SwrveCampaign* campaign in self.talk.campaigns ){
                                [campaignIds addObject:[NSNumber numberWithUnsignedInteger:campaign.ID]];
                            }

                            NSDictionary* payload = @{ @"ids" : [campaignIds componentsJoinedByString:@","],
                                                       @"count" : [NSString stringWithFormat:@"%lu", (unsigned long)[self.talk.campaigns count]] };

                            [self event:@"Swrve.Messages.campaigns_downloaded" payload:payload];
                        }
                    }

                    NSArray* resourceJson = [responseDict objectForKey:@"user_resources"];
                    if (resourceJson != nil) {
                        [self updateResources:resourceJson writeToCache:YES];
                    }
                } else {
                    DebugLog(@"Invalid JSON received for user resources and campaigns", nil);
                }
            } else if (statusCode == 429) {
                DebugLog(@"Request to retrieve campaign and user resource data was rate-limited.", nil);
            } else {
                DebugLog(@"Request to retrieve campaign and user resource data failed", nil);
            }
        }

        if (![self campaignsAndResourcesInitialized]) {
            [self setCampaignsAndResourcesInitialized:YES];

            // Only called first time API call returns - whether failed or successful, whether new campaigns were returned or not;
            // this ensures that if API call fails or there are no changes, we call autoShowMessages with cached campaigns
            if ([self talk]) {
                [[self talk] autoShowMessages];
            }

            // Invoke listeners once to denote that the first attempt at downloading has finished
            // independent of whether the resources or campaigns have changed from cached values
            if ([[self config] resourcesUpdatedCallback]) {
                [[self config] resourcesUpdatedCallback];
            }
        }
    }];
}

- (void) checkForCampaignAndResourcesUpdates:(NSTimer*)timer
{
    // If this wasn't called from the timer then reset the timer
    if (timer == nil) {
        NSDate* nextInterval = [NSDate dateWithTimeIntervalSinceNow:self.campaignsAndResourcesFlushFrequency];
        @synchronized([self campaignsAndResourcesTimer]) {
            [self.campaignsAndResourcesTimer setFireDate:nextInterval];
        }
    }

    // Check if there are events in the buffer or in the cache
    if ([self eventFileHasData] || [[self eventBuffer] count] > 0 || [self eventsWereSent]) {
        [self sendQueuedEvents];
        [self setEventsWereSent:NO];

        [NSTimer scheduledTimerWithTimeInterval:self.campaignsAndResourcesFlushRefreshDelay target:self selector:@selector(refreshCampaignsAndResources:) userInfo:nil repeats:NO];
    }
}

-(void) setPushNotificationsDeviceToken:(NSData*)newDeviceToken
{
    NSCAssert(newDeviceToken, @"The device token cannot be null", nil);
    NSString* newTokenString = [[[newDeviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    self.deviceToken = newTokenString;
    [[NSUserDefaults standardUserDefaults] setValue:newTokenString forKey:swrve_device_token_key];
    [self queueDeviceProperties];
    [self sendQueuedEvents];
}

-(void) sendQueuedEvents
{
    if (!self.userID)
    {
        DebugLog(@"Swrve user_id is null. Not sending data.", nil);
        return;
    }

    DebugLog(@"Sending queued events", nil);
    if ([self eventFileHasData])
    {
        [self sendLogfile];
    }

    [self queueUserUpdates];

    // Early out if length is zero.
    if ([[self eventBuffer] count] == 0) return;

    // Swap buffers
    NSArray* buffer = [self eventBuffer];
    int bytes = [self eventBufferBytes];
    [self initBuffer];

    NSString* session_token = [self createSessionToken];
    NSString* array_body = [self copyBufferToJson:buffer];
    NSString* json_string = [self createJSON:session_token events:array_body];

    NSData* json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];

    [self setEventsWereSent:YES];

    [self sendHttpPOSTRequest:[self batchURL]
                     jsonData:json_data
            completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {

                if (error){
                    DebugLog(@"Error opening HTTP stream: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                    [self setEventBufferBytes:[self eventBufferBytes] + bytes];
                    [[self eventBuffer] addObjectsFromArray:buffer];
                    return;
                }

                // Schedule the stream on the current run loop, then open the stream (which
                // automatically sends the request).  Wait for at least one byte of data to
                // be returned by the server.  As soon as at least one byte is available,
                // the full HTTP response header is available.  If no data is returned
                // within the timeout period, give up.
                SwrveSendContext* sendContext = [[SwrveSendContext alloc] init];
                [sendContext setSwrveReference:self];
                [sendContext setSwrveInstanceID:self->instanceID];
                [sendContext setBuffer:buffer];
                [sendContext setBufferLength:bytes];

                enum HttpStatus status = HTTP_SUCCESS;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                    status = [self getHttpStatus:httpResponse];
                }
                [self eventsSentCallback:status withData:data andContext:sendContext];
    }];
}

-(void) saveEventsToDisk
{
    DebugLog(@"Writing unsent event data to file", nil);

    [self queueUserUpdates];

    if ([self eventStream] && [[self eventBuffer] count] > 0)
    {
        NSString* json = [self copyBufferToJson:[self eventBuffer]];
        NSData* buffer = [json dataUsingEncoding:NSUTF8StringEncoding];
        [[self eventStream] write:(const uint8_t *)[buffer bytes] maxLength:[buffer length]];
        [[self eventStream] write:(const uint8_t *)swrve_trailing_comma maxLength:strlen(swrve_trailing_comma)];
        [self setEventFileHasData:YES];
    }

    // Always empty the buffer
    [self initBuffer];
}

-(void) setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock
{
    event_queued_callback = callbackBlock;
}

-(void) shutdown
{
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:instanceID] == NO)
    {
        DebugLog(@"Swrve shutdown: called on invalid instance.", nil);
        return;
    }

    [self stopCampaignsAndResourcesTimer];

    talk = nil;
    resourceManager = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [[SwrveInstanceIDRecorder sharedInstance]removeSwrveInstanceID:instanceID];

    if ([self eventStream]) {
        [[self eventStream] close];
        [self setEventStream:nil];
    }

    [self setEventBuffer:nil];
}

- (BOOL) appInBackground {
    UIApplicationState swrveState = [[UIApplication sharedApplication] applicationState];
    return (swrveState == UIApplicationStateInactive || swrveState == UIApplicationStateBackground);
}

-(int) eventWithNoCallback:(NSString*)eventName payload:(NSDictionary*)eventPayload
{
    return [self eventInternal:eventName payload:eventPayload triggerCallback:false];
}


#pragma mark -
#pragma mark Private methods

-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback
{
    if (!eventPayload) {
        eventPayload = [[NSDictionary alloc]init];
    }

    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(eventName) forKey:@"name"];
    [json setValue:eventPayload forKey:@"payload"];
    [self queueEvent:@"event" data:json triggerCallback:triggerCallback];
    return SWRVE_SUCCESS;
}

-(void) dealloc
{
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:instanceID] == YES)
    {
        [self shutdown];
    }
}

-(void) removeBlockStoreItem:(int)blockId
{
    [blockStore removeObjectForKey:[NSNumber numberWithInt:blockId ]];
}

-(void) updateDeviceInfo
{
    NSMutableDictionary * mutableInfo = (NSMutableDictionary*)deviceInfo;
    [mutableInfo removeAllObjects];
    [mutableInfo addEntriesFromDictionary:[self getDeviceProperties]];
}

-(void) registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification object:nil];
}

-(void) appDidBecomeActive:(NSNotification*)notification
{
    #pragma unused(notification)
    if (self.okToStartSessionOnResume) {
        [self sessionStart];
        [self queueDeviceProperties];
        
        if (self.config.autoSendEventsOnResume) {
            [self sendQueuedEvents];
        }

        // Re-enable auto show messages at session start
        if ([self talk]) {
            [[self talk] setAutoShowMessagesEnabled:YES];
        }
    }

    [self startCampaignsAndResourcesTimer];
    [self disableAutoShowAfterDelay];
}

-(void) appWillResignActive:(NSNotification*)notification
{
    #pragma unused(notification)
    [self suspend];
}

-(void) appWillTerminate:(NSNotification*)notification
{
    #pragma unused(notification)
    [self suspend];
}

-(void) suspend
{
    [self sessionEnd];
    if (self.config.autoSaveEventsOnResign) {
        [self saveEventsToDisk];
    }

    [self stopCampaignsAndResourcesTimer];
}

-(void) startCampaignsAndResourcesTimer
{
    if (![[self config] autoDownloadCampaignsAndResources]) {
        return;
    }

    @synchronized([self campaignsAndResourcesTimer]) {
        // If there is not already a timer running initialize timers and call refresh
        if (![self campaignsAndResourcesTimer] || ![[self campaignsAndResourcesTimer] isValid]) {
            [self refreshCampaignsAndResources];

            // Start repeating timer
            [self setCampaignsAndResourcesTimer:[NSTimer scheduledTimerWithTimeInterval:[self campaignsAndResourcesFlushFrequency]
                                                                                 target:self
                                                                               selector:@selector(checkForCampaignAndResourcesUpdates:)
                                                                               userInfo:nil
                                                                                repeats:YES]];

            // Call refresh once after refresh delay to ensure campaigns are reloaded after initial events have been sent
            [NSTimer scheduledTimerWithTimeInterval:[self campaignsAndResourcesFlushRefreshDelay]
                                             target:self
                                           selector:@selector(refreshCampaignsAndResources:)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
}

- (void) stopCampaignsAndResourcesTimer
{
    @synchronized([self campaignsAndResourcesTimer]) {
        if ([self campaignsAndResourcesTimer] && [[self campaignsAndResourcesTimer] isValid]) {
            [[self campaignsAndResourcesTimer] invalidate];
        }
    }
}


//If talk enabled ensure that after SWRVE_DEFAULT_AUTOSHOW_MESSAGES_MAX_DELAY autoshow is disabled
-(void) disableAutoShowAfterDelay
{
    if ([self talk]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
        SEL authoShowSelector = @selector(setAutoShowMessagesEnabled:);
#pragma clang diagnostic pop

        NSInvocation* disableAutoshowInvocation = [NSInvocation invocationWithMethodSignature:
                                                   [[self talk] methodSignatureForSelector:authoShowSelector]];

        bool arg = NO;
        [disableAutoshowInvocation setSelector:@selector(setAutoShowMessagesEnabled:)];
        [disableAutoshowInvocation setTarget:[self talk]];
        [disableAutoshowInvocation setArgument:&arg atIndex:2];

        [NSTimer scheduledTimerWithTimeInterval:(self.config.autoShowMessagesMaxDelay/1000) invocation:disableAutoshowInvocation repeats:NO];
    }
}


-(void) queueUserUpdates
{
    NSMutableDictionary * currentAttributes =  (NSMutableDictionary*)[self.userUpdates objectForKey:@"attributes"];
    if (currentAttributes.count > 0) {
        [self queueEvent:@"user" data:self.userUpdates triggerCallback:true];
        [currentAttributes removeAllObjects];
    }
}

-(void) pushNotificationReceived:(NSDictionary *)userInfo
{
    // Try to get the identifier _p
    id push_identifier = [userInfo objectForKey:@"_p"];
    if (push_identifier && ![push_identifier isKindOfClass:[NSNull class]]) {
        NSString* push_id = @"-1";
        if ([push_identifier isKindOfClass:[NSString class]]) {
            push_id = (NSString*)push_identifier;
        }
        else if ([push_identifier isKindOfClass:[NSNumber class]]) {
            push_id = [((NSNumber*)push_identifier) stringValue];
        }
        else {
            DebugLog(@"Unknown Swrve notification ID class for _p attribute", nil);
            return;
        }

        NSString* eventName = [NSString stringWithFormat:@"Swrve.Messages.Push-%@.engaged", push_id];
        [self event:eventName];
        DebugLog(@"Got Swrve notification with ID %@", push_id);
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }
}

// Get a string that represents the current App Version
// The implementation intentionally is unspecified, the rest of the SDK is not aware
// of the details of this.
+(NSString*) getAppVersion
{
    NSString * appVersion = nil;
    @try {
        appVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    }
    @catch (NSException * e) {}
    if (!appVersion)
    {
        return @"error";
    }

    return appVersion;
}

static NSString* httpScheme(bool useHttps)
{
    return useHttps ? @"https" : @"http";
}

-(void) setupConfig:(SwrveConfig *)newConfig
{
    // Set up default server locations
    if (nil == newConfig.eventsServer) {
        newConfig.eventsServer = [NSString stringWithFormat:@"%@://%ld.api.swrve.com", httpScheme(newConfig.useHttpsForEventServer), self.appID];
    }

    if (nil == newConfig.contentServer) {
        newConfig.contentServer = [NSString stringWithFormat:@"%@://%ld.content.swrve.com", httpScheme(newConfig.useHttpsForContentServer), self.appID];
    }

    // Validate other values
    NSCAssert(newConfig.httpTimeoutSeconds > 0, @"httpTimeoutSeconds must be greater than zero or requests will fail immediately.", nil);
}

-(void) maybeFlushToDisk
{
    if ([self eventBufferBytes] > SWRVE_MEMORY_QUEUE_MAX_BYTES)
    {
        [self saveEventsToDisk];
    }
}

-(void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback
{
    if ([self eventBuffer]) {
        // Add common attributes (if not already present)
        if (![eventData objectForKey:@"type"]) {
            [eventData setValue:eventType forKey:@"type"];
        }
        if (![eventData objectForKey:@"time"]) {
            [eventData setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
        }
        if (![eventData objectForKey:@"seqnum"]) {
            [eventData setValue:[NSNumber numberWithInteger:[self nextEventSequenceNumber]] forKey:@"seqnum"];
        }

        // Convert to string
        NSData* json_data = [NSJSONSerialization dataWithJSONObject:eventData options:0 error:nil];
        if (json_data) {
            NSString* json_string = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
            [self setEventBufferBytes:[self eventBufferBytes] + (int)[json_string length]];
            [[self eventBuffer] addObject:json_string];

            if (triggerCallback && event_queued_callback != NULL )
            {
                event_queued_callback(eventData, json_string);
            }
        }
    }
}

- (float) _estimate_dpi
{
    float scale = 1;

    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scale = (float)[[UIScreen mainScreen] scale];
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 132.0f * scale;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 163.0f * scale;
    }

    return 160.0f * scale;
}

- (void) sendCrashlyticsMetadata
{
    // Check if Crashlytics is used in this project
    Class crashlyticsClass = NSClassFromString(@"Crashlytics");
    if (crashlyticsClass != nil) {
        SEL setObjectValueSelector = NSSelectorFromString(@"setObjectValue:forKey:");
        if ([crashlyticsClass respondsToSelector:setObjectValueSelector]) {
            IMP imp = [crashlyticsClass methodForSelector:setObjectValueSelector];
            void (*func)(__strong id, SEL, id, NSString*) = (void(*)(__strong id, SEL, id, NSString*))imp;
            func(crashlyticsClass, setObjectValueSelector, @SWRVE_SDK_VERSION, @"Swrve_version");
        }
    }
}

- (CGRect) getDeviceScreenBounds
{
    UIScreen* screen   = [UIScreen mainScreen];
    CGRect bounds = [screen bounds];
    float screen_scale = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        screen_scale = (float)[[UIScreen mainScreen] scale];
    }
    bounds.size.width  = bounds.size.width  * screen_scale;
    bounds.size.height = bounds.size.height * screen_scale;
    return bounds;
}

- (NSDictionary*) getDeviceProperties
{
    UIDevice* device   = [UIDevice currentDevice];
    NSTimeZone* tz     = [NSTimeZone localTimeZone];
    NSNumber* dpi = [NSNumber numberWithFloat:[self _estimate_dpi]];
    NSNumber* min_os = [NSNumber numberWithInt: __IPHONE_OS_VERSION_MIN_REQUIRED];
    NSString *sdk_language = self.config.language;
    CGRect screen_bounds = [self getDeviceScreenBounds];
    NSNumber* device_width = [NSNumber numberWithFloat: (float)screen_bounds.size.width];
    NSNumber* device_height = [NSNumber numberWithFloat: (float)screen_bounds.size.height];
    NSNumber* secondsFromGMT = [NSNumber numberWithInteger:[tz secondsFromGMT]];
    NSString* timezone_name = [tz name];

    NSMutableDictionary* deviceProperties = [[NSMutableDictionary alloc] init];
    [deviceProperties setValue:[device model]         forKey:@"swrve.device_name"];
    [deviceProperties setValue:[device systemName]    forKey:@"swrve.os"];
    [deviceProperties setValue:[device systemVersion] forKey:@"swrve.os_version"];
    [deviceProperties setValue:min_os                 forKey:@"swrve.ios_min_version"];
    [deviceProperties setValue:sdk_language           forKey:@"swrve.language"];
    [deviceProperties setValue:device_height          forKey:@"swrve.device_height"];
    [deviceProperties setValue:device_width           forKey:@"swrve.device_width"];
    [deviceProperties setValue:dpi                    forKey:@"swrve.device_dpi"];
    [deviceProperties setValue:@SWRVE_SDK_VERSION     forKey:@"swrve.sdk_version"];
    [deviceProperties setValue:@"apple"               forKey:@"swrve.app_store"];
    [deviceProperties setValue:secondsFromGMT         forKey:@"swrve.utc_offset_seconds"];
    [deviceProperties setValue:timezone_name          forKey:@"swrve.timezone_name"];

    if (self.deviceToken) {
        [deviceProperties setValue:self.deviceToken forKey:@"swrve.ios_token"];
    }
    
    // Carrier info
    CTCarrier *carrier = [self getCarrierInfo];
    if (carrier != nil) {
        NSString* mobileCountryCode = [carrier mobileCountryCode];
        NSString* mobileNetworkCode = [carrier mobileNetworkCode];
        if (mobileCountryCode != nil && mobileNetworkCode != nil) {
            NSMutableString* carrierCode = [[NSMutableString alloc] initWithString:mobileCountryCode];
            [carrierCode appendString:mobileNetworkCode];
            [deviceProperties setValue:carrierCode           forKey:@"swrve.sim_operator.code"];
        }
        [deviceProperties setValue:[carrier carrierName]     forKey:@"swrve.sim_operator.name"];
        [deviceProperties setValue:[carrier isoCountryCode]  forKey:@"swrve.sim_operator.iso_country_code"];
    }

    return deviceProperties;
}

- (CTCarrier*) getCarrierInfo
{
    // Obtain carrier info from the device
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    return [netinfo subscriberCellularProvider];
}

- (void) queueDeviceProperties
{
    NSDictionary* deviceProperties = [self getDeviceProperties];
    NSMutableString* formattedDeviceData = [[NSMutableString alloc] initWithFormat:
    @"                      User: %@\n"
     "                   API Key: %@\n"
     "                    App ID: %ld\n"
     "               App Version: %@\n"
     "                  Language: %@\n"
     "              Event Server: %@\n"
     "            Content Server: %@\n",
          self.userID,
          self.apiKey,
          self.appID,
          self.config.appVersion,
          self.config.language,
          self.config.eventsServer,
          self.config.contentServer];

    for (NSString* key in deviceProperties) {
        [formattedDeviceData appendFormat:@"  %24s: %@\n", [key UTF8String], [deviceProperties objectForKey:key]];
    }
    DebugLog(@"Swrve config:\n%@", formattedDeviceData);

    [self updateDeviceInfo];
    [self userUpdate:deviceInfo];
}

// Get the time that the application was first installed.
// This value is stored in a file. If this file is not available, then we assume
// that the application was installed now, and save the current time to the file.
- (UInt64) getInstallTimeHelper:(NSString*)fileName
{
    unsigned long long seconds = 0;

    NSError* error = NULL;
    NSString* file_contents = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];

    if (!error && file_contents) {
        seconds = (unsigned long long)[file_contents longLongValue];
    } else {
        DebugLog(@"could not read file: %@", fileName);
    }

    // If we loaded a non-zero value we're done.
    if (seconds > 0)
    {
        UInt64 result = seconds;
        return result * 1000;
    }

    UInt64 time = [self getTime];
    NSString* currentTime = [NSString stringWithFormat:@"%llu", time/(UInt64)1000L];
    [currentTime writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return (time / 1000 * 1000);
}

- (UInt64) getInstallTime:(NSString*)fileName
{
    UInt64 result = [self getInstallTimeHelper:fileName];

    NSDate* install_date = [NSDate dateWithTimeIntervalSince1970:(result/1000)];
    #pragma unused(install_date)
    DebugLog(@"Install Time: %@", install_date);

    return result;
}

/*
 * Invalidates the currently stored ETag
 * Should be called when a refresh of campaigns and resources needs to be forced (eg. when cached data cannot be read)
 */
- (void) invalidateETag
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"campaigns_and_resources_etag"];
}

- (void) initResources
{
    // Create signature protected cache file
    NSURL* fileURL = [NSURL fileURLWithPath:self.config.userResourcesCacheFile];
    NSURL* signatureURL = [NSURL fileURLWithPath:self.config.userResourcesCacheSignatureFile];
    [self setResourcesFile:[[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:[self getSignatureKey] signatureErrorListener:self]];

    // Initialize resource manager
    resourceManager = [[SwrveResourceManager alloc] init];

    // read content of resources file and update resource manager if signature valid
    NSData* content = [[self resourcesFile] readFromFile];

    if (content != nil) {
        NSError* error = nil;
        NSArray* resourcesArray = [NSJSONSerialization JSONObjectWithData:content options:NSJSONReadingMutableContainers error:&error];
        if (!error) {
            [self updateResources:resourcesArray writeToCache:NO];
        }
    } else {
        [self invalidateETag];
    }
}

- (void) updateResources:(NSArray*)resourceJson writeToCache:(BOOL)writeToCache
{
    [[self resourceManager] setResourcesFromArray:resourceJson];

    if (writeToCache) {
        NSData* resourceData = [NSJSONSerialization dataWithJSONObject:resourceJson options:0 error:nil];
        [[self resourcesFile] writeToFile:resourceData];
    }

    if ([[self config] resourcesUpdatedCallback] != nil) {
        [[[self config] resourcesUpdatedCallback] invoke];
    }
}

enum HttpStatus {
    HTTP_SUCCESS,
    HTTP_REDIRECTION,
    HTTP_CLIENT_ERROR,
    HTTP_SERVER_ERROR
};

- (enum HttpStatus) getHttpStatus:(NSHTTPURLResponse*) httpResponse
{
    long code = [httpResponse statusCode];

    if (code < 300) {
        return HTTP_SUCCESS;
    }

    if (code < 400) {
        return HTTP_REDIRECTION;
    }

    if (code < 500) {
        return HTTP_CLIENT_ERROR;
    }

    // 500+
    return HTTP_SERVER_ERROR;
}

- (NSOutputStream*) createLogfile:(int)mode
{
    // If the file already exists, close it.
    if ([self eventStream])
    {
        [[self eventStream] close];
    }

    NSOutputStream* newFile = NULL;
    [self setEventFileHasData:NO];

    switch (mode)
    {
        case SWRVE_TRUNCATE_FILE:
            newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:NO];
            break;

        case SWRVE_APPEND_TO_FILE:
            newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:YES];
            break;

        case SWRVE_TRUNCATE_IF_TOO_LARGE:
        {
            NSData* cacheContent = [NSData dataWithContentsOfURL:[self eventFilename]];

            if (cacheContent == nil)
            {
                newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:NO];
            } else {
                NSUInteger cacheLength = [cacheContent length];
                [self setEventFileHasData:(cacheLength > 0)];

                if (cacheLength < SWRVE_DISK_MAX_BYTES) {
                    newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:YES];
                } else {
                    newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:NO];
                    DebugLog(@"Swrve log file too large (%lu)... truncating", (unsigned long)cacheLength);
                    [self setEventFileHasData:NO];
                }
            }

            break;
        }
    }

    [newFile open];

    return newFile;
}

- (void) eventsSentCallback:(enum HttpStatus)status withData:(NSData*)data andContext:(SwrveSendContext*)client_info
{
    #pragma unused(data)
    Swrve* swrve = [client_info swrveReference];
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:[client_info swrveInstanceID]] == YES) {

        switch (status) {
            case HTTP_REDIRECTION:
            case HTTP_SUCCESS:
                DebugLog(@"Success sending events to Swrve", nil);
                break;
            case HTTP_CLIENT_ERROR:
                DebugLog(@"HTTP Error - not adding events back into the queue: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                break;
            case HTTP_SERVER_ERROR:
                DebugLog(@"Error sending event data to Swrve (%@) Adding data back onto unsent message buffer", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                [[swrve eventBuffer] addObjectsFromArray:[client_info buffer]];
                [swrve setEventBufferBytes:[swrve eventBufferBytes] + [client_info bufferLength]];
                break;
        }
    }
}

// Convert the array of strings into a json array.
// This does not add the square brackets.
- (NSString*) copyBufferToJson:(NSArray*) buffer
{
    return [buffer componentsJoinedByString:@",\n"];
}

- (NSString*) createJSON:(NSString*)sessionToken events:(NSString*)rawEvents
{
    NSString *eventArray = [NSString stringWithFormat:@"[%@]", rawEvents];
    NSData *bodyData = [eventArray dataUsingEncoding:NSUTF8StringEncoding];
    NSArray* body = [NSJSONSerialization
                     JSONObjectWithData:bodyData
                     options:NSJSONReadingMutableContainers
                     error:nil];

    // Device ID needs to be unique for this user only, so we create a shorter version to save on storage in S3
    NSUInteger shortDeviceID = [self.deviceUUID hash];
    if (shortDeviceID > 10000) {
        shortDeviceID = shortDeviceID / 1000;
    }

    NSMutableDictionary* jsonPacket = [[NSMutableDictionary alloc] init];
    [jsonPacket setValue:self.userID forKey:@"user"];
    [jsonPacket setValue:[NSNumber numberWithInteger:(NSInteger)shortDeviceID] forKey:@"device_id"];
    [jsonPacket setValue:[NSNumber numberWithInt:SWRVE_VERSION] forKey:@"version"];
    [jsonPacket setValue:NullableNSString(self.config.appVersion) forKey:@"app_version"];
    [jsonPacket setValue:NullableNSString(sessionToken) forKey:@"session_token"];
    [jsonPacket setValue:body forKey:@"data"];

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonPacket options:0 error:nil];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return json;
}

- (NSInteger) nextEventSequenceNumber {

    NSInteger seqno;
    @synchronized(self) {
        // Defaults to 0 if this value is not available
        seqno= [[NSUserDefaults standardUserDefaults] integerForKey:@"swrve_event_seqnum"];
        seqno += 1;
        [[NSUserDefaults standardUserDefaults] setInteger:seqno forKey:@"swrve_event_seqnum"];
    }

    return seqno;
}

- (void) logfileSentCallback:(enum HttpStatus)status withData:(NSData*)data andContext:(SwrveSendLogfileContext*)context
{
    #pragma unused(data)
    Swrve* swrve = [context swrveReference];
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:[context swrveInstanceID]] == YES) {
        int mode = SWRVE_TRUNCATE_FILE;

        switch (status) {
            case HTTP_SUCCESS:
            case HTTP_CLIENT_ERROR:
            case HTTP_REDIRECTION:
                DebugLog(@"Received a valid HTTP POST response. Truncating event log file", nil);
                break;
            case HTTP_SERVER_ERROR:
                DebugLog(@"Error sending log file - reopening in append mode: status", nil);
                mode = SWRVE_APPEND_TO_FILE;
                break;
        }

        // close, truncate and re-open the file.
        [swrve setEventStream:[swrve createLogfile:mode]];
    }
}

- (void) sendLogfile
{
    if (![self eventStream]) return;
    if (![self eventFileHasData]) return;

    DebugLog(@"Sending log file %@", [self eventFilename]);

    // Close the write stream and set it to null
    // No more appending will happen while it is null
    [[self eventStream] close];
    [self setEventStream:NULL];

    NSMutableData* contents = [[NSMutableData alloc] initWithContentsOfURL:[self eventFilename]];
    if (contents == nil)
    {
        [self resetEventCache];
        return;
    }

    const NSUInteger length = [contents length];
    if (length <= 2)
    {
        [self resetEventCache];
        return;
    }

    // Remove trailing comma
    [contents setLength:[contents length] - 2];
    NSString* file_contents = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
    NSString* session_token = [self createSessionToken];
    NSString* json_string = [self createJSON:session_token events:file_contents];

    NSData* json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];

    [self sendHttpPOSTRequest:[self batchURL]
                      jsonData:json_data
             completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            DebugLog(@"Error opening HTTP stream", nil);
            return;
        }

        SwrveSendLogfileContext* logfileContext = [[SwrveSendLogfileContext alloc] init];
        [logfileContext setSwrveReference:self];
        [logfileContext setSwrveInstanceID:self->instanceID];

        enum HttpStatus status = HTTP_SUCCESS;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            status = [self getHttpStatus:(NSHTTPURLResponse*)response];
        }
        [self logfileSentCallback:status withData:data andContext:logfileContext];
    }];
}

- (void) resetEventCache
{
    [self setEventStream:[self createLogfile:SWRVE_TRUNCATE_FILE]];
}

- (UInt64) getTime
{
    // Get the time since the epoch in seconds
    struct timeval time;
    gettimeofday(&time, NULL);
    return (((UInt64)time.tv_sec) * 1000) + (((UInt64)time.tv_usec) / 1000);
}

- (BOOL) isValidJson:(NSData*) json
{
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:&err];
    return obj != nil;
}

- (void) sendHttpGETRequest:(NSURL*)url queryString:(NSString*)query
{
    [self sendHttpGETRequest:url queryString:query completionHandler:nil];
}

- (void) sendHttpGETRequest:(NSURL*)url
{
    [self sendHttpGETRequest:url completionHandler:nil];
}

- (void) sendHttpGETRequest:(NSURL*)baseUrl queryString:(NSString*)query completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    NSURL* url = [NSURL URLWithString:query relativeToURL:baseUrl];
    [self sendHttpGETRequest:url completionHandler:handler];
}

- (void) sendHttpGETRequest:(NSURL*)url completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.config.httpTimeoutSeconds];
    if (handler == nil) {
        [request setHTTPMethod:@"HEAD"];
    } else {
        [request setHTTPMethod:@"GET"];
    }
    [self sendHttpRequest:request completionHandler:handler];
}

- (void) sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json
{
    [self sendHttpPOSTRequest:url jsonData:json completionHandler:nil];
}

- (void) sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:SWRVE_SEND_TIMEOUT_SECONDS];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:json];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[json length]] forHTTPHeaderField:@"Content-Length"];

    [self sendHttpRequest:request completionHandler:handler];
}

- (void) sendHttpRequest:(NSMutableURLRequest*)request completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    // Add http request performance metrics for any previous requests into the header of this request (see JIRA SWRVE-5067 for more details)
    NSArray* allMetricsToSend;

    @synchronized([self httpPerformanceMetrics]) {
        allMetricsToSend = [[self httpPerformanceMetrics] copy];
        [[self httpPerformanceMetrics] removeAllObjects];
    }

    if (allMetricsToSend != nil && [allMetricsToSend count] > 0) {
        NSString* fullHeader = [allMetricsToSend componentsJoinedByString:@";"];
        [request addValue:fullHeader forHTTPHeaderField:@"Swrve-Latency-Metrics"];
    }

    SwrveConnectionDelegate* connectionDelegate = [[SwrveConnectionDelegate alloc] init:self completionHandler:handler];
    [NSURLConnection connectionWithRequest:request delegate:connectionDelegate];
}

- (void) addHttpPerformanceMetrics:(NSString*) metrics
{
    @synchronized([self httpPerformanceMetrics]) {
        [[self httpPerformanceMetrics] addObject:metrics];
    }
}

- (void) initBuffer
{
    [self setEventBuffer:[[NSMutableArray alloc] initWithCapacity:SWRVE_MEMORY_QUEUE_INITIAL_SIZE]];
    [self setEventBufferBytes:0];
}

- (NSString*) createStringWithMD5:(NSString*)source
{
#define C "%02x"
#define CCCC C C C C
#define DIGEST_FORMAT CCCC CCCC CCCC CCCC

    NSString* digestFormat = [NSString stringWithFormat:@"%s", DIGEST_FORMAT];

    NSData* buffer = [source dataUsingEncoding:NSUTF8StringEncoding];

    unsigned char digest[CC_MD5_DIGEST_LENGTH] = {0};
    unsigned int length = (unsigned int)[buffer length];
    CC_MD5_CTX context;
    CC_MD5_Init(&context);
    CC_MD5_Update(&context, [buffer bytes], length);
    CC_MD5_Final(digest, &context);

    NSString* result = [NSString stringWithFormat:digestFormat,
                            digest[ 0], digest[ 1], digest[ 2], digest[ 3],
                            digest[ 4], digest[ 5], digest[ 6], digest[ 7],
                            digest[ 8], digest[ 9], digest[10], digest[11],
                            digest[12], digest[13], digest[14], digest[15]];

    return result;
}

- (NSString*) createSessionToken
{
    // Get the time since the epoch in seconds
    struct timeval time; gettimeofday(&time, NULL);
    const long session_start = time.tv_sec;

    NSString* source = [NSString stringWithFormat:@"%@%ld%@", self.userID, session_start, self.apiKey];

    NSString* digest = [self createStringWithMD5:source];

    // $session_token = "$app_id=$user_id=$session_start=$md5_hash";
    NSString* session_token = [NSString stringWithFormat:@"%ld=%@=%ld=%@",
                                                         self.appID,
                                                         self.userID,
                                                         session_start,
                                                         digest];
    return session_token;
}

- (NSString*) getSignatureKey
{
    return [NSString stringWithFormat:@"%@%llu", self.apiKey, self->install_time];
}

- (void)signatureError:(NSURL*)file
{
    #pragma unused(file)
    DebugLog(@"Signature check failed for file %@", file);
    [self event:@"Swrve.signature_invalid"];
}

- (void) initResourcesDiff
{
    // Create signature protected cache file
    NSURL* fileURL = [NSURL fileURLWithPath:self.config.userResourcesDiffCacheFile];
    NSURL* signatureURL = [NSURL fileURLWithPath:self.config.userResourcesDiffCacheSignatureFile];

    [self setResourcesDiffFile:[[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:[self getSignatureKey] signatureErrorListener:self]];
}

-(void) getUserResources:(SwrveUserResourcesCallback)callbackBlock
{
    NSCAssert(callbackBlock, @"getUserResources: callbackBlock must not be nil.", nil);

    NSDictionary* resourcesDict = [[self resourceManager] getResources];
    NSMutableString* jsonString = [[NSMutableString alloc] initWithString:@"["];
    BOOL first = YES;
    for (NSString* resourceName in resourcesDict) {
        if (!first) {
            [jsonString appendString:@","];
        }
        first = NO;

        NSDictionary* resource = [resourcesDict objectForKey:resourceName];
        NSData* resourceData = [NSJSONSerialization dataWithJSONObject:resource options:0 error:nil];
        [jsonString appendString:[[NSString alloc] initWithData:resourceData encoding:NSUTF8StringEncoding]];
    }
    [jsonString appendString:@"]"];

    @try {
        callbackBlock(resourcesDict, jsonString);
    }
    @catch (NSException * e) {
        DebugLog(@"Exception in getUserResources callback. %@", e);
    }
}

-(void) getUserResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock
{
    NSCAssert(callbackBlock, @"getUserResourcesDiff: callbackBlock must not be nil.", nil);

    NSURL* base_content_url = [NSURL URLWithString:self.config.contentServer];
    NSURL* resourcesDiffURL = [NSURL URLWithString:@"api/1/user_resources_diff" relativeToURL:base_content_url];
    NSString* queryString = [NSString stringWithFormat:@"user=%@&api_key=%@&app_version=%@&joined=%llu",
                             self.userID, self.apiKey, self.config.appVersion, self->install_time];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"?%@", queryString] relativeToURL:resourcesDiffURL];

    [self sendHttpGETRequest:url completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        NSData* resourcesDiffCacheContent = [[self resourcesDiffFile] readFromFile];

        if (!error) {
            enum HttpStatus status = HTTP_SUCCESS;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                status = [self getHttpStatus:(NSHTTPURLResponse*)response];
            }

            if (status == SWRVE_SUCCESS) {
                if ([self isValidJson:data]) {
                    resourcesDiffCacheContent = data;
                    [[self resourcesDiffFile] writeToFile:data];
                } else {
                    DebugLog(@"Invalid JSON received for user resources diff", nil);
                }
            }
        }

        // At this point the cached content has been updated with the http response if a valid response was received
        // So we can call the callbackBlock with the cached content
        @try {
            NSArray* resourcesArray = [NSJSONSerialization JSONObjectWithData:resourcesDiffCacheContent options:NSJSONReadingMutableContainers error:nil];

            NSMutableDictionary* oldResourcesDict = [[NSMutableDictionary alloc] init];
            NSMutableDictionary* newResourcesDict = [[NSMutableDictionary alloc] init];

            for (NSDictionary* resourceObj in resourcesArray) {
                NSString* itemName = [resourceObj objectForKey:@"uid"];
                NSDictionary* itemDiff = [resourceObj objectForKey:@"diff"];

                NSMutableDictionary* oldValues = [[NSMutableDictionary alloc] init];
                NSMutableDictionary* newValues = [[NSMutableDictionary alloc] init];

                for (NSString* propertyKey in itemDiff) {
                    NSDictionary* propertyVals = [itemDiff objectForKey:propertyKey];
                    [oldValues setObject:[propertyVals objectForKey:@"old"] forKey:propertyKey];
                    [newValues setObject:[propertyVals objectForKey:@"new"] forKey:propertyKey];
                }

                [oldResourcesDict setObject:oldValues forKey:itemName];
                [newResourcesDict setObject:newValues forKey:itemName];
            }

            NSString* jsonString = [[NSString alloc] initWithData:resourcesDiffCacheContent encoding:NSUTF8StringEncoding];
            callbackBlock(oldResourcesDict, newResourcesDict, jsonString);
        }
        @catch (NSException* e) {
            DebugLog(@"Exception in getUserResourcesDiff callback. %@", e);
        }
    }];
}

// Overwritten for unit tests
- (NSDate*)getNow
{
    return [NSDate date];
}

@end

// This connection delegate tracks performance metrics for each request (see JIRA SWRVE-5067 for more details)
@implementation SwrveConnectionDelegate

@synthesize swrve;
@synthesize startTime;
@synthesize metrics;
@synthesize data;
@synthesize response;
@synthesize handler;

- (id)init:(Swrve*)_swrve completionHandler:(ConnectionCompletionHandler)_handler
{
    self = [super init];
    if (self) {
        [self setSwrve:_swrve];
        [self setHandler:_handler];
        [self setData:[[NSMutableData alloc] init]];
        [self setMetrics:[[NSMutableDictionary alloc] init]];
        [self setStartTime:[NSDate date]];
        [self setResponse:nil];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSDate* finishTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:finishTime];

    NSURL* requestURL = [[connection originalRequest] URL];
    NSString* baseURL = [NSString stringWithFormat:@"%@://%@", [requestURL scheme], [requestURL host]];

    NSString* metricsString = [NSString stringWithFormat:@"u=%@", baseURL];

    NSString* failedOn = @"c";
    if ([[self metrics] objectForKey:@"sb"]) {
        failedOn = @"rh";
        metricsString = [metricsString stringByAppendingString:[NSString stringWithFormat:@",sb=%@", [[self metrics] valueForKey:@"sb"]]];
    }
    metricsString = [metricsString stringByAppendingString:[NSString stringWithFormat:@",%@=%@,%@_error=1", failedOn, interval, failedOn]];

    Swrve* swrveStrong = swrve;
    if (swrveStrong) {
        [swrveStrong addHttpPerformanceMetrics:metricsString];
    }

    if (self.handler) {
        self.handler([self response], [self data], error);
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    #pragma unused(connection, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    NSDate* sendBodyTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:sendBodyTime];

    [[self metrics] setValue:interval forKey:@"c"];
    [[self metrics] setValue:interval forKey:@"sh"];
    [[self metrics] setValue:interval forKey:@"sb"];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)receivedResponse
{
    #pragma unused(connection)
    NSDate* responseTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:responseTime];
    [self setResponse:receivedResponse];

    if (![[self metrics] objectForKey:@"sb"]) {
        [[self metrics] setValue:interval forKey:@"c"];
        [[self metrics] setValue:interval forKey:@"sh"];
        [[self metrics] setValue:interval forKey:@"sb"];
    }
    [[self metrics] setValue:interval forKey:@"rh"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)receivedData
{
    #pragma unused(connection)
    // This might be called multiple times while data is being received
    NSDate* responseDateTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:responseDateTime];
    [[self data] appendData:receivedData];

    if (![[self metrics] objectForKey:@"sb"]) {
        [[self metrics] setValue:interval forKey:@"c"];
        [[self metrics] setValue:interval forKey:@"sh"];
        [[self metrics] setValue:interval forKey:@"sb"];
    }
    if (![[self metrics] objectForKey:@"rh"]) {
        [[self metrics] setValue:interval forKey:@"rh"];
    }
    [[self metrics] setValue:interval forKey:@"rb"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDate* finishTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:finishTime];

    if (![[self metrics] objectForKey:@"sb"]) {
        [[self metrics] setValue:interval forKey:@"c"];
        [[self metrics] setValue:interval forKey:@"sh"];
        [[self metrics] setValue:interval forKey:@"sb"];
    }
    if (![[self metrics] objectForKey:@"rh"]) {
        [[self metrics] setValue:interval forKey:@"rh"];
    }
    if (![[self metrics] objectForKey:@"rb"]) {
        [[self metrics] setValue:interval forKey:@"rb"];
    }

    NSURL* requestURL = [[connection originalRequest] URL];
    NSString* baseURL = [NSString stringWithFormat:@"%@://%@", [requestURL scheme], [requestURL host]];

    NSString* metricsString = [NSString stringWithFormat:@"u=%@,c=%@,sh=%@,sb=%@,rh=%@,rb=%@",
                               baseURL,
                               [[self metrics] valueForKey:@"c"],
                               [[self metrics] valueForKey:@"sh"],
                               [[self metrics] valueForKey:@"sb"],
                               [[self metrics] valueForKey:@"rh"],
                               [[self metrics] valueForKey:@"rb"]];

    Swrve* swrveStrong = swrve;
    if (swrveStrong) {
        [swrveStrong addHttpPerformanceMetrics:metricsString];
    }

    if (self.handler) {
        self.handler([self response], [self data], nil);
    }
}

- (NSString*) getTimeIntervalFromStartAsString:(NSDate*)date
{
    NSTimeInterval interval = [date timeIntervalSinceDate:[self startTime]];
    return [NSString stringWithFormat:@"%.0f", round(interval * 1000)];
}

@end
