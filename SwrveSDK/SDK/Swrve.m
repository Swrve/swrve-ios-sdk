#if !__has_feature(objc_arc)
    #error Please enable ARC for this project (Project Settings > Build Settings), or add the -fobjc-arc compiler flag to each of the files in the Swrve SDK (Project Settings > Build Phases > Compile Sources)
#endif

#if defined(SWRVE_NO_ADDRESS_BOOK) || defined(SWRVE_NO_LOCATION) || defined(SWRVE_NO_PHOTO_LIBRARY) || defined(SWRVE_NO_PHOTO_CAMERA)
    #error These flags have been inverted as of SDK 5.0. The permissions are disabled by default and only enabled with SWRVE_X permission flags. Check docs.swrve.com for more information.
#endif

#import <sys/time.h>
#import <CommonCrypto/CommonHMAC.h>
#import <AdSupport/ASIdentifierManager.h>
#import "Swrve.h"
#import "SwrveEmpty.h"
#import "SwrveCampaign.h"
#import "SwrvePermissions.h"
#import "SwrveLocalStorage.h"
#import "SwrveRESTClient.h"
#import "SwrveMigrationsManager.h"
#import "SwrveReceiptProvider.h"
#import "SwrveMessageController+Private.h"
#import "SwrveDeviceProperties.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "SwrveEventsManager.h"

#if SWRVE_TEST_BUILD
#define SWRVE_STATIC_UNLESS_TEST_BUILD
#else
#define SWRVE_STATIC_UNLESS_TEST_BUILD static
#endif

#define NullableNSString(x) ((x == nil)? [NSNull null] : x)
#define KB(x) (1024*(x))
#define MB(x) (1024*KB((x)))

const static char* swrve_trailing_comma = ",\n";

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
- (void)setABTestDetailsFromDictionary:(NSDictionary*)json;

@end

@interface SwrveMessageController()

@property (nonatomic, retain) NSArray* campaigns;
@property (nonatomic) bool autoShowMessagesEnabled;

-(void) updateCampaigns:(NSDictionary*)campaignJson;
-(NSString*) campaignQueryString;
-(void) writeToCampaignCache:(NSData*)campaignData;
-(void) autoShowMessages;

@end

@interface Swrve() <SwrveCommonDelegate>
{
    BOOL initialised;
    SwrveEventsManager *eventsManager;

    UInt64 installTimeSeconds;
    NSDate *lastSessionDate;

    SwrveEventQueuedCallback event_queued_callback;
    // The unique id associated with this instance of Swrve
    long    instanceID;
}

@property (nonatomic, readonly) SwrveReceiptProvider* receiptProvider;

-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback;
-(void) setupConfig:(SwrveConfig*)config;
-(void) maybeFlushToDisk;
-(void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback;
-(void) updateDeviceInfo;
-(void) appDidBecomeActive:(NSNotification*)notification;
-(void) appWillResignActive:(NSNotification*)notification;
-(void) appWillTerminate:(NSNotification*)notification;
-(void) queueUserUpdates;
- (NSString*) createSessionToken;
- (NSString*) createJSON:(NSString*)sessionToken events:(NSString*)rawEvents;
- (NSString*) copyBufferToJson:(NSArray*)buffer;
- (void) sendCrashlyticsMetadata;
- (BOOL) isValidJson:(NSData*) json;
- (void) initResources;
- (void) sendLogfile;
- (NSOutputStream*) createLogfile:(int)mode;
- (UInt64) getTime;
- (void) initBuffer;
- (void) checkForCampaignAndResourcesUpdates:(NSTimer*)timer;

@property (atomic) BOOL initialised;
@property (atomic) SwrveProfileManager *profileManager;

// Used to store the merged user updates
@property (atomic, strong) NSMutableDictionary * userUpdates;

// Device id, used for tracking event streams from different devices
@property (atomic) NSNumber* deviceId;

// HTTP Request metrics that haven't been sent yet
@property (atomic) NSMutableArray* httpPerformanceMetrics;

// Flush values and timer for campaigns and resources update request
@property (atomic) double campaignsAndResourcesFlushFrequency;
@property (atomic) double campaignsAndResourcesFlushRefreshDelay;
@property (atomic) NSTimer* campaignsAndResourcesTimer;
@property (atomic) int campaignsAndResourcesTimerSeconds;
@property (atomic) NSDate* campaignsAndResourcesLastRefreshed;
@property (atomic) BOOL campaignsAndResourcesInitialized; // Set to true after first call to API returns

// Resource cache files
@property (atomic) SwrveSignatureProtectedFile* resourcesFile;
@property (atomic) SwrveSignatureProtectedFile* resourcesDiffFile;

// An in-memory buffer of messages that are ready to be sent to the Swrve
// server the next time sendQueuedEvents is called.
@property (atomic) NSMutableArray* eventBuffer;
// Count the number of UTF-16 code points stored in buffer
@property (atomic) int eventBufferBytes;

@property (atomic) bool eventFileHasData;
@property (atomic) NSOutputStream* eventStream;
@property (atomic) NSURL* eventFilename;

// keep track of whether any events were sent so we know whether to check for resources / campaign updates
@property (atomic) bool eventsWereSent;

// URLs
@property (atomic) NSURL* batchURL;
@property (atomic) NSURL* baseCampaignsAndResourcesURL;

@property (atomic) int locationSegmentVersion;

@property(atomic) SwrveRESTClient *restClient;

// Push
#if !defined(SWRVE_NO_PUSH)
@property (atomic, readonly)         SwrvePush *push;                         /*!< Push Notification Handler Service */
#endif //!defined(SWRVE_NO_PUSH)

@end

// Manages unique ids for each instance of Swrve
// This allows low-level c callbacks to know if it is safe to execute their callback functions.
// It is not safe to execute a callback function after a Swrve instance has been deallocated or shutdown.
@implementation SwrveInstanceIDRecorder

+ (SwrveInstanceIDRecorder*) sharedInstance
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

@implementation Swrve

@synthesize config;
@synthesize appID;
@synthesize apiKey;
@synthesize userID;
@synthesize deviceInfo;
@synthesize messaging;
@synthesize resourceManager;
#if !defined(SWRVE_NO_PUSH)
@synthesize push;
#endif

@synthesize initialised;
@synthesize profileManager;
@synthesize userUpdates;
@synthesize deviceToken = _deviceToken;
@synthesize deviceId;
@synthesize httpPerformanceMetrics;
@synthesize campaignsAndResourcesFlushFrequency;
@synthesize campaignsAndResourcesFlushRefreshDelay;
@synthesize campaignsAndResourcesTimer;
@synthesize campaignsAndResourcesTimerSeconds;
@synthesize campaignsAndResourcesLastRefreshed;
@synthesize campaignsAndResourcesInitialized;
@synthesize resourcesFile;
@synthesize resourcesDiffFile;
@synthesize eventBuffer;
@synthesize eventBufferBytes;
@synthesize eventFileHasData;
@synthesize eventStream;
@synthesize eventFilename;
@synthesize eventsWereSent;
@synthesize batchURL;
@synthesize baseCampaignsAndResourcesURL;
@synthesize locationSegmentVersion;
@synthesize restClient;
@synthesize receiptProvider;

// Non shared instance initialization methods
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey
{
    SwrveConfig* newConfig = [[SwrveConfig alloc] init];
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:newConfig launchOptions:nil];
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig
{
   return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig launchOptions:nil];
}

// Init methods with launchOptions for push
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey launchOptions:(NSDictionary*)launchOptions
{
    SwrveConfig* newConfig = [[SwrveConfig alloc] init];
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:newConfig launchOptions:launchOptions];
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig launchOptions:(NSDictionary*)launchOptions
{
    NSCAssert(self.config == nil, @"Do not initialize Swrve instance more than once!", nil);
    if ( self = [super init] ) {
        if (self.config) {
            DebugLog(@"Swrve may not be initialized more than once.", nil);
            return self;
        }

        // Do migrations first before anything else is done.
        SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:[[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig]];
        [migrationsManager checkMigrations];

        [SwrveCommon addSharedInstance:self];

        NSCAssert(swrveAppID > 0, @"Invalid app ID given (%d)", swrveAppID);
        appID = swrveAppID;

        NSCAssert(swrveAPIKey.length > 1, @"API Key is invalid (too short): %@", swrveAPIKey);
        apiKey = swrveAPIKey;

        NSCAssert(swrveConfig, @"Null config object given to Swrve", nil);
        [self setupConfig:swrveConfig];
        config = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];

        profileManager = [[SwrveProfileManager alloc] initWithConfig:config];
        userID = [profileManager userId];

        eventsManager = [[SwrveEventsManager alloc] initWithDelegate:self];

        instanceID = [[SwrveInstanceIDRecorder sharedInstance] addSwrveInstanceID];
        [self sendCrashlyticsMetadata];
        [self setHttpPerformanceMetrics:[[NSMutableArray alloc] init]];
        locationSegmentVersion = 0; // init to zero
        [self initSwrveRestClient:config.httpTimeoutSeconds];
        [self initBuffer];

        receiptProvider = [[SwrveReceiptProvider alloc] init];

        NSURL* base_events_url = [NSURL URLWithString:swrveConfig.eventsServer];
        [self setBatchURL:[NSURL URLWithString:@"1/batch" relativeToURL:base_events_url]];

        NSURL* base_content_url = [NSURL URLWithString:self.config.contentServer];
        [self setBaseCampaignsAndResourcesURL:[NSURL URLWithString:@"api/1/user_resources_and_campaigns" relativeToURL:base_content_url]];

        deviceId = [SwrveDeviceProperties deviceId];

#if !defined(SWRVE_NO_PUSH)
        if(swrveConfig.pushEnabled) {
            push = [SwrvePush sharedInstanceWithPushDelegate:self andCommonDelegate:self];

            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
                UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
                center.delegate = push;
            }

            if (swrveConfig.autoCollectDeviceToken) {
                [self.push observeSwizzling];
            }

            if (swrveConfig.pushResponseDelegate != nil) {
                [self.push setResponseDelegate:swrveConfig.pushResponseDelegate];
            }

            // Check if the launch options of the app has any push notification in it
            if (launchOptions != nil) {
                [self.push checkLaunchOptionsForPushData:launchOptions];
            }
        }
#else
        #pragma unused(launchOptions)
        DebugLog(@"\nWARNING: \nWe have deprecated the SWRVE_NO_PUSH flag as of release 4.9.1. \nIf you still need to exclude Push, please contact CSM with regards to future releases.\n", nil);
#endif //!defined(SWRVE_NO_PUSH)

        self.campaignsAndResourcesFlushFrequency =  [SwrveLocalStorage flushFrequency];
        if (self.campaignsAndResourcesFlushFrequency <= 0) {
            self.campaignsAndResourcesFlushFrequency = SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_FREQUENCY / 1000;
        }

        self.campaignsAndResourcesFlushRefreshDelay = [SwrveLocalStorage flushDelay];
        if (self.campaignsAndResourcesFlushRefreshDelay <= 0) {
            self.campaignsAndResourcesFlushRefreshDelay = SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_REFRESH_DELAY / 1000;
        }

        [self registerLifecycleCallbacks];
        [self initWithUserId:[profileManager userId]];
    }

    return self;
}

- (void)initWithUserId:(NSString *)swrveUserId {

    NSCAssert(swrveUserId != nil, @"UserId cannot be nil. Something has gone wrong.", nil);
    NSCAssert([swrveUserId length] > 0, @"UserId cannot be blank.", nil);
    userID = swrveUserId;

    event_queued_callback = nil;

    deviceInfo = [NSMutableDictionary dictionary];

    UInt64 installTimeSecondsFromFile = [SwrveLocalStorage installTimeForUserId:swrveUserId];
    if (installTimeSecondsFromFile == 0) {
        [profileManager setIsNewUser:true];
        installTimeSeconds = [self secondsSinceEpoch];
        [SwrveLocalStorage saveInstallTime:installTimeSeconds forUserId:swrveUserId];
    } else {
        [profileManager setIsNewUser:false];
        installTimeSeconds = installTimeSecondsFromFile;
    }

    if (config.abTestDetailsEnabled) {
        [self initABTestDetails];
    }

    [self initResources];
    [self initResourcesDiff];

    NSString* eventCacheFile = [SwrveLocalStorage eventsFilePathForUserId:swrveUserId];
    [self setEventFilename:[NSURL fileURLWithPath:eventCacheFile]];
    [self setEventStream:[self createLogfile:SWRVE_TRUNCATE_IF_TOO_LARGE]];

    // Set up empty user attributes store
    self.userUpdates = [[NSMutableDictionary alloc] init];
    [self.userUpdates setValue:@"user" forKey:@"type"];
    [self.userUpdates setValue:[[NSMutableDictionary alloc] init] forKey:@"attributes"];

    [self setCampaignsAndResourcesInitialized:NO];

    [self updateDeviceInfo];

    messaging = [[SwrveMessageController alloc] initWithSwrve:self];
}


- (void) beginSession {
    // The app has started and thus our session
    lastSessionDate = [self getNow];
    [self updateDeviceInfo];

    [self disableAutoShowAfterDelay];

    [self queueSessionStart];
    [self queueDeviceProperties];

    // If this is the first time this user has been seen send install analytics
    if ([profileManager isNewUser]) {
        [self eventInternal:@"Swrve.first_session" payload:nil triggerCallback:false];
    }

    [self startCampaignsAndResourcesTimer];
    [self sendQueuedEvents];
}

- (void)initSwrveRestClient:(NSTimeInterval)timeOut {
    [self setRestClient:[[SwrveRESTClient alloc] initWithTimeoutInterval:timeOut]];
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

-(int) purchaseItem:(NSString*)itemName currency:(NSString*)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity {
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(itemName) forKey:@"item"];
    [json setValue:NullableNSString(itemCurrency) forKey:@"currency"];
    [json setValue:[NSNumber numberWithInt:itemCost] forKey:@"cost"];
    [json setValue:[NSNumber numberWithInt:itemQuantity] forKey:@"quantity"];
    [self queueEvent:@"purchase" data:json triggerCallback:true];
    return SWRVE_SUCCESS;
}

-(int) event:(NSString*)eventName {
    if( [eventsManager isValidEventName:eventName]) {
        return [self eventInternal:eventName payload:nil triggerCallback:true];
    } else {
        return SWRVE_FAILURE;
    }
}

-(int) event:(NSString*)eventName payload:(NSDictionary*)eventPayload {
    if( [eventsManager isValidEventName:eventName]) {
        return [self eventInternal:eventName payload:eventPayload triggerCallback:true];
    } else {
        return SWRVE_FAILURE;
    }
}

-(int) eventWithNoCallback:(NSString*)eventName payload:(NSDictionary*)eventPayload {
    if( [eventsManager isValidEventName:eventName]) {
        return [self eventInternal:eventName payload:eventPayload triggerCallback:false];
    } else {
        return SWRVE_FAILURE;
    }
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product {
    return [self iap:transaction product:product rewards:nil];
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product rewards:(SwrveIAPRewards*)rewards {
    NSString* product_id = @"unknown";
    switch(transaction.transactionState) {
        case SKPaymentTransactionStatePurchased:
        {
            if( transaction.payment != nil && transaction.payment.productIdentifier != nil){
                product_id = transaction.payment.productIdentifier;
            }

            NSString* transactionId  = [transaction transactionIdentifier];
            #pragma unused(transactionId)

            SwrveReceiptProviderResult* receipt = [self.receiptProvider receiptForTransaction:transaction];
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
            NSDictionary *payload = @{@"product_id" : product_id, @"error" : error};
            [self eventInternal:@"Swrve.iap.transaction_failed_on_client" payload:payload triggerCallback:false];
        }
            break;
        case SKPaymentTransactionStateRestored:
        {
            if( transaction.originalTransaction != nil && transaction.originalTransaction.payment != nil && transaction.originalTransaction.payment.productIdentifier != nil){
                product_id = transaction.originalTransaction.payment.productIdentifier;
            }
            NSDictionary *payload = @{@"product_id" : product_id};
            [self eventInternal:@"Swrve.iap.restored_on_client" payload:payload triggerCallback:false];
        }
            break;
        default:
            break;
    }

    return SWRVE_SUCCESS;
}

-(int) unvalidatedIap:(SwrveIAPRewards*) rewards localCost:(double) localCost localCurrency:(NSString*) localCurrency productId:(NSString*) productId productIdQuantity:(int) productIdQuantity {
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

-(int) currencyGiven:(NSString*)givenCurrency givenAmount:(double)givenAmount {
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(givenCurrency) forKey:@"given_currency"];
    [json setValue:[NSNumber numberWithDouble:givenAmount] forKey:@"given_amount"];
    [self queueEvent:@"currency_given" data:json triggerCallback:true];
    return SWRVE_SUCCESS;
}

-(int) userUpdate:(NSDictionary*)attributes {
    [self maybeFlushToDisk];

    // Merge attributes with current set of attributes
    if (attributes) {
        @synchronized (self.userUpdates) {
            NSMutableDictionary * currentAttributes = (NSMutableDictionary*)[self.userUpdates objectForKey:@"attributes"];
            [self.userUpdates setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
            for (id attributeKey in attributes) {
                id attribute = [attributes objectForKey:attributeKey];
                [currentAttributes setObject:attribute forKey:attributeKey];
            }
        }
    }

    return SWRVE_SUCCESS;
}

- (int)userUpdate:(NSString *)name withDate:(NSDate *)date {
    if (name && date) {
        @synchronized (self.userUpdates) {
            NSMutableDictionary *currentAttributes = (NSMutableDictionary *) [self.userUpdates objectForKey:@"attributes"];
            [self.userUpdates setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
            [currentAttributes setObject:[self convertDateToString:date] forKey:name];
        }

    } else {
        DebugLog(@"nil object passed into userUpdate:withDate");
        return SWRVE_FAILURE;
    }

    return SWRVE_SUCCESS;
}

- (NSString *) convertDateToString:(NSDate* )date {

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];

    return [dateFormatter stringFromDate:date];
}

-(void) refreshCampaignsAndResources:(NSTimer*)timer {
    #pragma unused(timer)
    [self refreshCampaignsAndResources];
}

-(void) refreshCampaignsAndResources {
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

    NSURL* url = [self campaignsAndResourcesURL];
    DebugLog(@"Refreshing campaigns from URL %@", url);
    [restClient sendHttpGETRequest:url completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        if (!error) {
            NSInteger statusCode = 200;
            enum HttpStatus status = HTTP_SUCCESS;

            NSDictionary* headers = [[NSDictionary alloc] init];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                statusCode = [httpResponse statusCode];
                status = [self httpStatusFromResponse:httpResponse];
                headers = [httpResponse allHeaderFields];
            }

            if (status == SWRVE_SUCCESS) {
                if ([self isValidJson:data]) {
                    NSString* etagHeader = [headers objectForKey:@"ETag"];
                    if (etagHeader != nil) {
                        [SwrveLocalStorage saveETag:etagHeader];
                    }

                    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                    NSNumber* flushFrequency = [responseDict objectForKey:@"flush_frequency"];
                    if (flushFrequency != nil) {
                        self.campaignsAndResourcesFlushFrequency = [flushFrequency integerValue] / 1000;
                        [SwrveLocalStorage saveFlushFrequency:self.campaignsAndResourcesFlushFrequency];
                    }

                    NSNumber* flushDelay = [responseDict objectForKey:@"flush_refresh_delay"];
                    if (flushDelay != nil) {
                        self.campaignsAndResourcesFlushRefreshDelay = [flushDelay integerValue] / 1000;
                        [SwrveLocalStorage saveflushDelay:self.campaignsAndResourcesFlushRefreshDelay];
                    }

                    if (self.messaging) {
                        NSDictionary* campaignJson = [responseDict objectForKey:@"campaigns"];
                        if (campaignJson != nil) {
                            [self.messaging updateCampaigns:campaignJson];

                            NSData* campaignData = [NSJSONSerialization dataWithJSONObject:campaignJson options:0 error:nil];
                            [self.messaging writeToCampaignCache:campaignData];
                            [self.messaging autoShowMessages];

                            // Notify campaigns have been downloaded
                            NSMutableArray* campaignIds = [[NSMutableArray alloc] init];
                            for( SwrveCampaign* campaign in self.messaging.campaigns ){
                                [campaignIds addObject:[NSNumber numberWithUnsignedInteger:campaign.ID]];
                            }

                            NSDictionary* payload = @{ @"ids" : [campaignIds componentsJoinedByString:@","],
                                                       @"count" : [NSString stringWithFormat:@"%lu", (unsigned long)[self.messaging.campaigns count]] };

                            [self eventInternal:@"Swrve.Messages.campaigns_downloaded" payload:payload triggerCallback:false];
                        }
                    }

                    NSDictionary* locationCampaignJson = [responseDict objectForKey:@"location_campaigns"];
                    if (locationCampaignJson != nil) {
                        NSDictionary* campaignsJson = [locationCampaignJson objectForKey:@"campaigns"];
                        [self saveLocationCampaignsInCache:campaignsJson];
                    }

                    if (self.config.abTestDetailsEnabled) {
                        NSDictionary* campaignJson = [responseDict objectForKey:@"campaigns"];
                        if (campaignJson != nil) {
                            id abTestDetailsJson = [campaignJson objectForKey:@"ab_test_details"];
                            if (abTestDetailsJson != nil && [abTestDetailsJson isKindOfClass:[NSDictionary class]]) {
                                [self updateABTestDetails:abTestDetailsJson];
                            }
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
            if (self.messaging) {
                [self.messaging autoShowMessages];
            }

            // Invoke listeners once to denote that the first attempt at downloading has finished
            // independent of whether the resources or campaigns have changed from cached values
            if ([self.config resourcesUpdatedCallback]) {
                [[self.config resourcesUpdatedCallback] invoke];
            }
        }
    }];
}

- (UInt64)joinedDateMilliSeconds {
    return 1000 * self->installTimeSeconds;
}

- (NSURL *)campaignsAndResourcesURL {
    UInt64 joinedDateMilliSeconds = [self joinedDateMilliSeconds];
    NSMutableString *queryString = [NSMutableString stringWithFormat:@"?user=%@&api_key=%@&app_version=%@&joined=%llu",
                                                                     self.userID, self.apiKey, self.appVersion, joinedDateMilliSeconds];
    if (self.messaging) {
        NSString *campaignQueryString = [self.messaging campaignQueryString];
        [queryString appendFormat:@"&%@", campaignQueryString];
    }

    if (self.config.abTestDetailsEnabled) {
        [queryString appendString:@"&ab_test_details=1"];
    }

    NSString *etagValue =  [SwrveLocalStorage eTag];
    if (etagValue != nil) {
        [queryString appendFormat:@"&etag=%@", etagValue];
    }

    return [NSURL URLWithString:queryString relativeToURL:self.baseCampaignsAndResourcesURL];
}

- (void) checkForCampaignAndResourcesUpdates:(NSTimer*)timer {
    // If this wasn't called from the timer then reset the timer
    if (timer == nil) {
        NSDate* now = [self getNow];
        NSDate* nextInterval = [now dateByAddingTimeInterval:self.campaignsAndResourcesFlushFrequency];
        @synchronized([self campaignsAndResourcesTimer]) {
            [self.campaignsAndResourcesTimer setFireDate:nextInterval];
        }
    }

    // Check if there are events in the buffer or in the cache
    BOOL eventsToSend;
    @synchronized (self.eventBuffer) {
        eventsToSend = ([self eventFileHasData] || [self.eventBuffer count] > 0 || [self eventsWereSent]);
    }
    if (eventsToSend) {
        [self sendQueuedEvents];
        [self setEventsWereSent:NO];

        [NSTimer scheduledTimerWithTimeInterval:self.campaignsAndResourcesFlushRefreshDelay target:self selector:@selector(refreshCampaignsAndResources:) userInfo:nil repeats:NO];
    }
}

-(NSData*) campaignData:(int)category {
    if(SWRVE_CAMPAIGN_LOCATION == category) {
        SwrveSignatureProtectedFile * locationCampaignFile = [self signatureFileWithType:SWRVE_LOCATION_FILE errorDelegate:self];
        return [locationCampaignFile readFromFile];
    }
    return nil;
}

- (BOOL)processPermissionRequest:(NSString*)action {
    return [SwrvePermissions processPermissionRequest:action withSDK:self];
}

-(void) sendQueuedEvents {
    if (!self.userID) {
        DebugLog(@"Swrve user_id is null. Not sending data.", nil);
        return;
    }

    DebugLog(@"Sending queued events", nil);
    if ([self eventFileHasData]) {
        [self sendLogfile];
    }

    [self queueUserUpdates];

    // Early out if length is zero.
    NSArray* buffer = self.eventBuffer;
    int bytes = self.eventBufferBytes;

    @synchronized (buffer) {
        if ([buffer count] == 0) return;

        // Swap buffers
        [self initBuffer];
    }

    NSString* session_token = [self createSessionToken];
    NSString* array_body = [self copyBufferToJson:buffer];
    NSString* json_string = [self createJSON:session_token events:array_body];

    NSData* json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];
    [self setEventsWereSent:YES];

    [restClient sendHttpPOSTRequest:[self batchURL]
                     jsonData:json_data
            completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
                // Schedule the stream on the current run loop, then open the stream (which
                // automatically sends the request).  Wait for at least one byte of data to
                // be returned by the server.  As soon as at least one byte is available,
                // the full HTTP response header is available. If no data is returned
                // within the timeout period, give up.
                SwrveSendContext* sendContext = [[SwrveSendContext alloc] init];
                [sendContext setSwrveReference:self];
                [sendContext setSwrveInstanceID:self->instanceID];
                @synchronized (buffer) {
                    [sendContext setBuffer:buffer];
                    [sendContext setBufferLength:bytes];
                }

                if (error){
                    DebugLog(@"Error opening HTTP stream: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                    [self eventsSentCallback:HTTP_SERVER_ERROR withData:data andContext:sendContext]; //503 network error
                    return;
                }

                enum HttpStatus status = HTTP_SUCCESS;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                    status = [self httpStatusFromResponse:httpResponse];
                }
                [self eventsSentCallback:status withData:data andContext:sendContext];
    }];
}

-(void) saveEventsToDisk {
    DebugLog(@"Writing unsent event data to file", nil);

    [self queueUserUpdates];

    NSArray* buffer = self.eventBuffer;
    @synchronized (buffer) {
        if ([self eventStream] && [buffer count] > 0) {
            NSString* json = [self copyBufferToJson:buffer];
            NSData* bufferJson = [json dataUsingEncoding:NSUTF8StringEncoding];
            [[self eventStream] write:(const uint8_t *)[bufferJson bytes] maxLength:[bufferJson length]];
            long bytes = [[self eventStream] write:(const uint8_t *)swrve_trailing_comma maxLength:strlen(swrve_trailing_comma)];
            if(bytes == 0){
                DebugLog(@"Nothing was written to the event file");
            }else{
                DebugLog(@"Written to the event file");
                [self setEventFileHasData:YES];
                [self initBuffer];
            }
        }
    }
}

-(void) setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock {
    event_queued_callback = callbackBlock;
}

-(void) shutdown {
    DebugLog(@"shutting down swrveInstance..", nil);
    if ([[SwrveInstanceIDRecorder sharedInstance] hasSwrveInstanceID:instanceID] == NO) {
        DebugLog(@"Swrve shutdown: called on invalid instance.", nil);
        return;
    }

    [self stopCampaignsAndResourcesTimer];

    //ensure UI isn't displaying during shutdown
    [self.messaging cleanupConversationUI];
    [self.messaging dismissMessageWindow];
    messaging = nil;

    resourceManager = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [[SwrveInstanceIDRecorder sharedInstance] removeSwrveInstanceID:instanceID];

    if ([self eventStream]) {
        [[self eventStream] close];
        [self setEventStream:nil];
    }

    [self setEventBuffer:nil];

#if !defined(SWRVE_NO_PUSH)
    [self.push deswizzlePushMethods];
    [SwrvePush resetSharedInstance];
    push = nil;
#endif
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
    if ([[SwrveInstanceIDRecorder sharedInstance] hasSwrveInstanceID:instanceID] == YES)
    {
        [self shutdown];
    }
}

-(void) updateDeviceInfo
{
    NSMutableDictionary * mutableInfo = (NSMutableDictionary*)self.deviceInfo;
    [mutableInfo removeAllObjects];
    [mutableInfo addEntriesFromDictionary:[self deviceProperties]];
    // Send permission events
    [SwrvePermissions compareStatusAndQueueEventsWithSDK:self];
}

-(void) registerLifecycleCallbacks {
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

-(void) appDidBecomeActive:(NSNotification*)notification {
#pragma unused(notification)

    if (!initialised) {
        initialised = YES;
        // App started the first time
        [self beginSession];
        return;
    }

    // App became active after a pause
    NSDate* now = [self getNow];
    NSTimeInterval secondsPassed = [now timeIntervalSinceDate:lastSessionDate];
    if (secondsPassed >= self.config.newSessionInterval) {
        // We consider this a new session as more than newSessionInterval seconds
        // have passed.
        [self sessionStart];
        // Re-enable auto show messages at session start
        if (self.messaging) {
            [self.messaging setAutoShowMessagesEnabled:YES];
            [self disableAutoShowAfterDelay];
        }
    }

    [self queueDeviceProperties];
    if (self.config.autoSendEventsOnResume) {
        [self sendQueuedEvents];
    }

    if (self.messaging != nil) {
        [self.messaging appDidBecomeActive];
    }

#if !defined(SWRVE_NO_PUSH)
    if(self.config.pushEnabled) {
        [self.push processInfluenceData];
    }
#endif //!defined(SWRVE_NO_PUSH)

    [self resumeCampaignsAndResourcesTimer];
    lastSessionDate = [self getNow];
}

-(void) appWillResignActive:(NSNotification*)notification
{
    #pragma unused(notification)
    lastSessionDate = [self getNow];
    [self suspend:NO];
}

-(void) appWillTerminate:(NSNotification*)notification
{
    #pragma unused(notification)
    [self suspend:YES];
}

-(void) suspend:(BOOL)terminating
{
    if (terminating) {
        if (self.config.autoSaveEventsOnResign) {
            [self saveEventsToDisk];
        }
    } else {
        [self sendQueuedEvents];
    }

    [self stopCampaignsAndResourcesTimer];
}

-(void) startCampaignsAndResourcesTimer
{
    if (!self.config.autoDownloadCampaignsAndResources) {
        return;
    }

    [self refreshCampaignsAndResources];
    // Start repeating timer
    [self setCampaignsAndResourcesTimer:[NSTimer scheduledTimerWithTimeInterval:1
                                                                         target:self
                                                                       selector:@selector(campaignsAndResourcesTimerTick:)
                                                                       userInfo:nil
                                                                        repeats:YES]];

    // Call refresh once after refresh delay to ensure campaigns are reloaded after initial events have been sent
    [NSTimer scheduledTimerWithTimeInterval:[self campaignsAndResourcesFlushRefreshDelay]
                                     target:self
                                   selector:@selector(refreshCampaignsAndResources:)
                                   userInfo:nil
                                    repeats:NO];
}

-(void)campaignsAndResourcesTimerTick:(NSTimer*)timer
{
    self.campaignsAndResourcesTimerSeconds++;
    if (self.campaignsAndResourcesTimerSeconds >= self.campaignsAndResourcesFlushFrequency) {
        self.campaignsAndResourcesTimerSeconds = 0;
        [self checkForCampaignAndResourcesUpdates:timer];
    }
}

- (void) resumeCampaignsAndResourcesTimer
{
    if (!self.config.autoDownloadCampaignsAndResources) {
        return;
    }

    @synchronized(self.campaignsAndResourcesTimer) {
        [self stopCampaignsAndResourcesTimer];
        [self setCampaignsAndResourcesTimer:[NSTimer scheduledTimerWithTimeInterval:1
                                                                             target:self
                                                                           selector:@selector(campaignsAndResourcesTimerTick:)
                                                                           userInfo:nil
                                                                            repeats:YES]];
    }
}

- (void) stopCampaignsAndResourcesTimer
{
    @synchronized(self.campaignsAndResourcesTimer) {
        if (self.campaignsAndResourcesTimer && [self.campaignsAndResourcesTimer isValid]) {
            [self.campaignsAndResourcesTimer invalidate];
        }
    }
}

//If talk enabled ensure that after SWRVE_DEFAULT_AUTOSHOW_MESSAGES_MAX_DELAY autoshow is disabled
-(void) disableAutoShowAfterDelay
{
    if (self.messaging) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
        SEL authoShowSelector = @selector(setAutoShowMessagesEnabled:);
#pragma clang diagnostic pop

        NSInvocation* disableAutoshowInvocation = [NSInvocation invocationWithMethodSignature:
                                                   [self.messaging methodSignatureForSelector:authoShowSelector]];

        bool arg = NO;
        [disableAutoshowInvocation setSelector:authoShowSelector];
        [disableAutoshowInvocation setTarget:self.messaging];
        [disableAutoshowInvocation setArgument:&arg atIndex:2];
        [NSTimer scheduledTimerWithTimeInterval:(self.config.autoShowMessagesMaxDelay/1000) invocation:disableAutoshowInvocation repeats:NO];
    }
}


-(void) queueUserUpdates
{
    @synchronized (self.userUpdates) {
        NSMutableDictionary * currentAttributes = (NSMutableDictionary*)[self.userUpdates objectForKey:@"attributes"];
        if (currentAttributes.count > 0) {
            [self queueEvent:@"user" data:[self.userUpdates mutableCopy] triggerCallback:false];
            [currentAttributes removeAllObjects];
        }
    }
}

#if !defined(SWRVE_NO_PUSH)
- (void) deviceTokenIncoming:(NSData *)newDeviceToken {
    [self setDeviceToken:newDeviceToken];
}

- (void) deviceTokenUpdated:(NSString *) newDeviceToken {
    _deviceToken = newDeviceToken;
    [SwrveLocalStorage saveDeviceToken:newDeviceToken];
    [self queueDeviceProperties];
    [self sendQueuedEvents];
}

- (void) remoteNotificationReceived:(NSDictionary *) notificationInfo {
    [self pushNotificationReceived:notificationInfo];
}

- (void) setDeviceToken:(NSData*)deviceToken
{
    if (self.config.pushEnabled && deviceToken) {
        [self.push setPushNotificationsDeviceToken:deviceToken];

        if (self.messaging) {
            [self.messaging deviceTokenUpdated];
        }
    }
}

- (NSString*) deviceToken {
    return self->_deviceToken;
}

- (void) pushNotificationReceived:(NSDictionary*)userInfo
{
    if (self.config.pushEnabled) {
        // Do not process the push notification if the app was on the foreground
        BOOL appInBackground = [UIApplication sharedApplication].applicationState != UIApplicationStateActive;
        if (appInBackground) {
            [self.push pushNotificationReceived:userInfo];
            if (self.messaging) {
                [self.messaging pushNotificationReceived:userInfo];
            }
        }
    }
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler
{
    if (self.config.pushEnabled) {
        return [self.push didReceiveRemoteNotification:userInfo withBackgroundCompletionHandler:completionHandler];
    } else {
        if (completionHandler != nil) {
            completionHandler(UIBackgroundFetchResultFailed, nil);
        }
    }
    // Not a Swrve push, customer should handle
    return NO;
}

- (void) sendPushEngagedEvent:(NSString*)pushId {
    NSString* eventName = [NSString stringWithFormat:@"Swrve.Messages.Push-%@.engaged", pushId];
    [self eventInternal:eventName payload:nil triggerCallback:false];
}

- (void) processNotificationResponseWithIdentifier:(NSString *)identifier andUserInfo:(NSDictionary *)userInfo {
    DebugLog(@"Processing Push Notification Response: %@", identifier);
    [self.push pushNotificationResponseReceived:identifier withUserInfo:userInfo];
}

- (void) processNotificationResponse:(UNNotificationResponse *)response {
    [self processNotificationResponseWithIdentifier:response.actionIdentifier andUserInfo:response.notification.request.content.userInfo];
}

- (void) deeplinkReceived:(NSURL*) url {
    UIApplication *application = [UIApplication sharedApplication];

    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [application openURL:url options:@{} completionHandler:^(BOOL success) {
            DebugLog(@"Opening url [%@] successfully: %d", url, success);
        }];
    } else {
        BOOL success = [application openURL:url];
        DebugLog(@"Opening url [%@] successfully: %d", url, success);
    }
}

#endif //!defined(SWRVE_NO_PUSH)
#pragma mark -

-(void) setupConfig:(SwrveConfig *)newConfig
{
    NSString *prefix = [self stackHostPrefixFromConfig:newConfig];

    // Set up default server locations
    if (nil == newConfig.eventsServer) {
        newConfig.eventsServer = [NSString stringWithFormat:@"%@://%ld.%@api.swrve.com", @"https", self.appID, prefix];
    }

    if (nil == newConfig.contentServer) {
        newConfig.contentServer = [NSString stringWithFormat:@"%@://%ld.%@content.swrve.com", @"https", self.appID, prefix];
    }

    // Validate other values
    NSCAssert(newConfig.httpTimeoutSeconds > 0, @"httpTimeoutSeconds must be greater than zero or requests will fail immediately.", nil);
}

-(NSString *) stackHostPrefixFromConfig:(SwrveConfig *)newConfig {
    if (newConfig.stack == SWRVE_STACK_EU) {
        return @"eu-";
    } else {
        return @""; // default to US which has no prefix
    }
}


-(void) maybeFlushToDisk
{
    if (self.eventBufferBytes > SWRVE_MEMORY_QUEUE_MAX_BYTES) {
        [self saveEventsToDisk];
    }
}

-(void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback {

    NSMutableArray* buffer = self.eventBuffer;
    if (buffer) {
        // Add common attributes (if not already present)
        if (![eventData objectForKey:@"type"]) {
            [eventData setValue:eventType forKey:@"type"];
        }
        if (![eventData objectForKey:@"time"]) {
            [eventData setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
        }
        [eventData setValue:[NSNumber numberWithInteger:[self nextEventSequenceNumber]] forKey:@"seqnum"];

        // Convert to string
        NSData* json_data = [NSJSONSerialization dataWithJSONObject:eventData options:0 error:nil];
        if (json_data) {
            NSString* json_string = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
            @synchronized (buffer) {
                [self setEventBufferBytes:self.eventBufferBytes + (int)[json_string length]];
                [buffer addObject:json_string];
            }

            if (triggerCallback && event_queued_callback != NULL ) {
                event_queued_callback(eventData, json_string);
            }
        }
    }
}

-(NSString*) swrveSDKVersion {
    return @SWRVE_SDK_VERSION;
}

-(NSString*) appVersion {
    NSString * appVersion = self.config.appVersion;
    if (appVersion == nil) {
        @try {
            appVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
        }
        @catch (NSException * e) {
            DebugLog(@"Could not obtian version: %@", e);
        }
    }
    return appVersion;
}

- (NSSet*) pushCategories {
#if !defined(SWRVE_NO_PUSH)
    return self.config.pushCategories;
#else
    return nil;
#endif
}

- (NSSet*) notificationCategories {
#if !defined(SWRVE_NO_PUSH)
    return self.config.notificationCategories;
#else
    return nil;
#endif
}

- (NSString*) appGroupIdentifier {
    return self.config.appGroupIdentifier;
}

- (void) sendCrashlyticsMetadata {

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

- (NSDictionary*) deviceProperties {

    NSDictionary* permissionStatus = [SwrvePermissions currentStatusWithSDK:self];
    CTCarrier* carrierInfo = [SwrveUtils carrierInfo];
    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:@SWRVE_SDK_VERSION
                                                                               installTimeSeconds:installTimeSeconds
                                                                              conversationVersion:CONVERSATION_VERSION
                                                                                      deviceToken:self.deviceToken
                                                                                 permissionStatus:permissionStatus
                                                                                     sdk_language:self.config.language
                                                                                      carrierInfo:carrierInfo];

    return [swrveDeviceProperties deviceProperties];
}

- (void) queueDeviceProperties {

    NSDictionary* deviceProperties = [self deviceProperties];
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
          self.appVersion,
          self.config.language,
          self.config.eventsServer,
          self.config.contentServer];

    for (NSString* key in deviceProperties) {
        [formattedDeviceData appendFormat:@"  %24s: %@\n", [key UTF8String], [deviceProperties objectForKey:key]];
    }

    if (!getenv("RUNNING_UNIT_TESTS")) {
        DebugLog(@"Swrve config:\n%@", formattedDeviceData);
    }
    [self updateDeviceInfo];
    [self userUpdate:self.deviceInfo];
}

- (UInt64) secondsSinceEpoch {
    return (unsigned long long)([[NSDate date] timeIntervalSince1970]);
}

/*
 * Invalidates the currently stored ETag
 * Should be called when a refresh of campaigns and resources needs to be forced (eg. when cached data cannot be read)
 */
- (void) invalidateETag
{
     [SwrveLocalStorage removeETag];
}

- (void) saveLocationCampaignsInCache:(NSDictionary*)campaignsJson
{
    NSError* error = nil;
    NSData* locationCampaignsData = [NSJSONSerialization dataWithJSONObject:campaignsJson options:0 error:&error];
    if (error) {
        DebugLog(@"Error parsing/writing location campaigns.\nError: %@\njson: %@", error, campaignsJson);
    } else {

        SwrveSignatureProtectedFile * locationCampaignFile = [self signatureFileWithType:SWRVE_LOCATION_FILE errorDelegate:nil];

        [locationCampaignFile writeToFile:locationCampaignsData];
    }
}

- (void) initResources {

    SwrveSignatureProtectedFile * file = [self signatureFileWithType:SWRVE_RESOURCE_FILE errorDelegate:self];

    [self setResourcesFile:file];

    // Initialize resource manager
    if (resourceManager == nil) {
        resourceManager = [[SwrveResourceManager alloc] init];
    }

    // Read content of resources file and update resource manager if signature valid
    NSData* content = [self.resourcesFile readFromFile];
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

- (void) initABTestDetails
{
    SwrveSignatureProtectedFile * campaignFile =  [self signatureFileWithType:SWRVE_CAMPAIGN_FILE errorDelegate:nil];

    // Initialize resource manager
    if (resourceManager == nil) {
        resourceManager = [[SwrveResourceManager alloc] init];
    }

    // Read content of campaigns file and update ab test details
    NSData* content = [campaignFile readFromFile];
    if (content != nil) {
        NSError* jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:0 error:&jsonError];
        if (jsonError) {
            DebugLog(@"Error parsing AB Test details.\nError: %@ %@", [jsonError localizedDescription], [jsonError localizedFailureReason]);
        } else {
            id abTestDetailsJson = [jsonDict objectForKey:@"ab_test_details"];
            if (abTestDetailsJson != nil && [abTestDetailsJson isKindOfClass:[NSDictionary class]]) {
                [self updateABTestDetails:abTestDetailsJson];
            }
        }
    }
}

- (void) updateABTestDetails:(NSDictionary*)abTestDetailsJson
{
    [self.resourceManager setABTestDetailsFromDictionary:abTestDetailsJson];
}

- (void) updateResources:(NSArray*)resourceJson writeToCache:(BOOL)writeToCache
{
    [self.resourceManager setResourcesFromArray:resourceJson];

    if (writeToCache) {
        NSData* resourceData = [NSJSONSerialization dataWithJSONObject:resourceJson options:0 error:nil];
        [self.resourcesFile writeToFile:resourceData];
    }

    if (self.config.resourcesUpdatedCallback != nil) {
        [self.config.resourcesUpdatedCallback invoke];
    }
}

enum HttpStatus {
    HTTP_SUCCESS,
    HTTP_REDIRECTION,
    HTTP_CLIENT_ERROR,
    HTTP_SERVER_ERROR
};

- (enum HttpStatus) httpStatusFromResponse:(NSHTTPURLResponse*) httpResponse
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
    if ([self eventStream]) {
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
    if ([[SwrveInstanceIDRecorder sharedInstance] hasSwrveInstanceID:[client_info swrveInstanceID]] == YES) {

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

                NSMutableArray* buffer = swrve.eventBuffer;
                @synchronized (buffer) {
                    if (buffer) {
                        [buffer addObjectsFromArray:[client_info buffer]];
                    }
                }
                [swrve setEventBufferBytes:swrve.eventBufferBytes + [client_info bufferLength]];
                [swrve saveEventsToDisk];
                break;
        }
    }
}

// Convert the array of strings into a json array.
// This does not add the square brackets.
- (NSString*) copyBufferToJson:(NSArray*) buffer {
    @synchronized (buffer) {
        return [buffer componentsJoinedByString:@",\n"];
    }
}

- (NSString*) createJSON:(NSString*)sessionToken events:(NSString*)rawEvents
{
    NSString *eventArray = [NSString stringWithFormat:@"[%@]", rawEvents];
    NSData *bodyData = [eventArray dataUsingEncoding:NSUTF8StringEncoding];
    NSArray* body = [NSJSONSerialization
                     JSONObjectWithData:bodyData
                     options:NSJSONReadingMutableContainers
                     error:nil];

    NSMutableDictionary* jsonPacket = [[NSMutableDictionary alloc] init];
    [jsonPacket setValue:self.userID forKey:@"user"];
    [jsonPacket setValue:self.deviceId forKey:@"short_device_id"];
    [jsonPacket setValue:[NSNumber numberWithInt:SWRVE_VERSION] forKey:@"version"];
    [jsonPacket setValue:NullableNSString(self.appVersion) forKey:@"app_version"];
    [jsonPacket setValue:NullableNSString(sessionToken) forKey:@"session_token"];
    [jsonPacket setValue:body forKey:@"data"];

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonPacket options:0 error:nil];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return json;
}

- (NSInteger) nextEventSequenceNumber
{
    NSInteger seqno;
    @synchronized(self) {
        // Defaults to 0 if this value is not available
        NSString *seqNumKey = [[profileManager userId] stringByAppendingString:@"swrve_event_seqnum"];
        seqno = [SwrveLocalStorage seqNumWithCustomKey:seqNumKey];
        seqno += 1;
        [SwrveLocalStorage saveSeqNum:seqno withCustomKey:seqNumKey];
    }

    return seqno;
}

- (void) logfileSentCallback:(enum HttpStatus)status withData:(NSData*)data andContext:(SwrveSendLogfileContext*)context
{
    #pragma unused(data)
    Swrve* swrve = [context swrveReference];
    if ([[SwrveInstanceIDRecorder sharedInstance] hasSwrveInstanceID:[context swrveInstanceID]] == YES) {
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

- (void) sendLogfile {

    if (![self eventStream]) return;
    if (![self eventFileHasData]) return;

    // Close the write stream and set it to null
    // No more appending will happen while it is null
    [[self eventStream] close];
    [self setEventStream:NULL];

    NSMutableData* contents = [[NSMutableData alloc] initWithContentsOfURL:[self eventFilename]];
    if (contents == nil) {
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

    [restClient sendHttpPOSTRequest:[self batchURL]
                      jsonData:json_data
             completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {

                 SwrveSendLogfileContext* logfileContext = [[SwrveSendLogfileContext alloc] init];
                 [logfileContext setSwrveReference:self];
                 [logfileContext setSwrveInstanceID:self->instanceID];

        if (error) {
            DebugLog(@"Error opening HTTP stream when sending the contents of the log file", nil);
            [self logfileSentCallback:HTTP_SERVER_ERROR withData:data andContext:logfileContext]; //HTTP 503 Error, service not available
            return;
        }

        enum HttpStatus status = HTTP_SUCCESS;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            status = [self httpStatusFromResponse:(NSHTTPURLResponse*)response];
        }
        [self logfileSentCallback:status withData:data andContext:logfileContext];
    }];
}

- (void) resetEventCache {
    [self setEventStream:[self createLogfile:SWRVE_TRUNCATE_FILE]];
}

- (UInt64) getTime
{
    // Get the time since the epoch in milliseconds
    struct timeval time;
    gettimeofday(&time, NULL);
    return (((UInt64)time.tv_sec) * 1000) + (((UInt64)time.tv_usec) / 1000);
}

- (void) initBuffer {
    [self setEventBuffer:[[NSMutableArray alloc] initWithCapacity:SWRVE_MEMORY_QUEUE_INITIAL_SIZE]];
    [self setEventBufferBytes:0];
}

- (BOOL) isValidJson:(NSData*) jsonNSData {
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:jsonNSData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        DebugLog(@"Error with json.\nError:%@", err);
    }
    return obj != nil;
}

- (NSString*) createSessionToken
{
    // Get the time since the epoch in seconds
    struct timeval time; gettimeofday(&time, NULL);
    const long startTime = time.tv_sec;

    NSString * sessionToken = [profileManager sessionTokenFromAppId:self.appID
                                                             apiKey:self.apiKey
                                                             userID:self.userID
                                                          startTime:startTime];
    return sessionToken;
}

- (NSString*) signatureKey
{
   return [NSString stringWithFormat:@"%@%llu", self.apiKey, self->installTimeSeconds];
}

- (void)signatureError:(NSURL*)file
{
    #pragma unused(file)
    DebugLog(@"Signature check failed for file %@", file);
    [self eventInternal:@"Swrve.signature_invalid" payload:nil triggerCallback:false];
}

- (void) initResourcesDiff {

    SwrveSignatureProtectedFile * file =  [self signatureFileWithType:SWRVE_RESOURCE_FILE errorDelegate:self];
    [self setResourcesDiffFile:file];
}

-(void) userResources:(SwrveUserResourcesCallback)callbackBlock {
    NSCAssert(callbackBlock, @"getUserResources: callbackBlock must not be nil.", nil);
    NSDictionary* resourcesDict = [self resourceManager].resources;
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

    if (callbackBlock != nil) {
        @try {
            callbackBlock(resourcesDict, jsonString);
        }
        @catch (NSException * e) {
            DebugLog(@"Exception in userResources callback. %@", e);
        }
    }
}

-(void) userResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock {
    NSCAssert(callbackBlock, @"getUserResourcesDiff: callbackBlock must not be nil.", nil);
    NSURL* url = [self userResourcesDiffURL];
    [restClient sendHttpGETRequest:url completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        NSData* resourcesDiffCacheContent = [[self resourcesDiffFile] readFromFile];

        if (!error) {
            enum HttpStatus status = HTTP_SUCCESS;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                status = [self httpStatusFromResponse:(NSHTTPURLResponse*)response];
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
            DebugLog(@"Exception in userResourcesDiff callback. %@", e);
        }
    }];
}

- (NSURL *)userResourcesDiffURL {
    NSURL* base_content_url = [NSURL URLWithString:self.config.contentServer];
    NSURL* resourcesDiffURL = [NSURL URLWithString:@"api/1/user_resources_diff" relativeToURL:base_content_url];
    UInt64 joinedDateMilliSeconds = [self joinedDateMilliSeconds];
    NSString* queryString = [NSString stringWithFormat:@"user=%@&api_key=%@&app_version=%@&joined=%llu",
                                                       self.userID, self.apiKey, self.appVersion, joinedDateMilliSeconds];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"?%@", queryString] relativeToURL:resourcesDiffURL];
    return url;
}

// Overwritten for unit tests
- (NSDate*)getNow
{
    return [NSDate date];
}

- (SwrveSignatureProtectedFile *)signatureFileWithType:(int)type errorDelegate:(id<SwrveSignatureErrorDelegate>)delegate {

    SwrveSignatureProtectedFile * file =  [[SwrveSignatureProtectedFile alloc] protectedFileType:type
                                                                                          userID:userID
                                                                                    signatureKey:[self signatureKey]
                                                                                   errorDelegate:delegate];

    return file;
}

- (SwrveMessageController *)messagingController {
    
    return self.messaging;
}

@end
