#import "SwrveMessageController.h"
#import "SwrveMessageController+Private.h"
#import "SwrveButtonActions.h"
#import "Swrve+Private.h"

#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)

#import <SwrveSDKCommon/SwrveAssetsManager.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#import <SwrveSDKCommon/SwrveQA.h>
#import <SwrveSDKCommon/TextTemplating.h>
#import <SwrveSDKCommon/SwrveQACampaignInfo.h>

#if TARGET_OS_IOS /** exclude tvOS **/

#import <SwrveSDKCommon/SwrvePermissions.h>

#endif //TARGET_OS_IOS
#else
#import "SwrveQACampaignInfo.h"
#import "SwrveLocalStorage.h"
#import "SwrveAssetsManager.h"
#import "SwrveUtils.h"
#import "SwrveQA.h"
#import "TextTemplating.h"
#if TARGET_OS_IOS /** exclude tvOS **/
#import "SwrvePermissions.h"
#endif //TARGET_OS_IOS
#endif

#import "SwrveMessagePage.h"
#import "SwrveInterfaceOrientation.h"
#import "SwrveMessageViewController.h"
#import "SwrveMessageController+Private.h"

#if __has_include(<SwrveSDKCommon/SwrveQACampaignInfo.h>)
#import <SwrveSDKCommon/SwrveQACampaignInfo.h>

#else
#import "SwrveQACampaignInfo.h"
#endif

#if __has_include(<SwrveSDKCommon/SwrveInAppCapabilitiesDelegate.h>)
#import <SwrveSDKCommon/SwrveInAppCapabilitiesDelegate.h>
#else
#import "SwrveInAppCapabilitiesDelegate.h"
#endif


#if __has_include(<SwrveSDK/SwrveSDK-Swift.h>)
#import <SwrveSDK/SwrveSDK-Swift.h>
#elif __has_include("SwrveSDK-Swift.h")
#import "SwrveSDK-Swift.h"
#endif

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSArray *SUPPORTED_DEVICE_FILTERS;
static NSArray *SUPPORTED_STATIC_DEVICE_FILTERS;
static NSArray *ALL_SUPPORTED_DYNAMIC_DEVICE_FILTERS;

const static int DEFAULT_DELAY_FIRST_MESSAGE = 150;
const static int DEFAULT_MAX_SHOWS = 99999;
const static int DEFAULT_MIN_DELAY = 55;

#if TARGET_OS_IOS

@interface SwrvePush (SwrvePushInternalAccess)
- (void)registerForPushNotifications:(BOOL)provisional providesAppNotificationSettings:(BOOL)providesAppNotificationSettings;
@end

#endif //TARGET_OS_IOS

@interface Swrve (PrivateMethodsForMessageController)
@property BOOL campaignsAndResourcesInitialized;
@property NSString *sessionToken;

- (NSDictionary *)internalRealTimeUserProperties;

- (void)invalidateETag;

- (NSDate *)getNow;
@end

@interface Swrve (SwrveHelperMethods)

@property(atomic) SwrveRESTClient *restClient;
@property(atomic, readonly) NSString *language;
- (CGRect)deviceScreenBounds;
- (NSString *)signatureKey;
- (NSString *)userID;
@end

@interface SwrveCampaign (PrivateMethodsForMessageController)
- (void)wasShownToUserAt:(NSDate *)timeShown;
@end

@interface SwrveMessageController ()

@property(nonatomic, assign) BOOL addedNotificiationsForMenuWindow;
@property(nonatomic, assign) UIWindowLevel originalMenuWindowLevel;
@property(nonatomic, retain) SwrveAssetsManager *assetsManager;
@property(nonatomic, retain) NSString *user;
@property(nonatomic, retain) NSString *apiKey;
@property(nonatomic, retain) NSArray *campaigns; // List of campaigns available to the user.
@property(nonatomic, retain) NSMutableDictionary *campaignsState; // Serializable state of the campaigns.
@property(nonatomic, retain) NSString *server;
@property(nonatomic, retain) SwrveSignatureProtectedFile *campaignFile;
@property(nonatomic, retain) NSString *language; // ISO language code
@property(nonatomic, retain) NSFileManager *manager;
@property(nonatomic, retain) NSMutableArray *notifications;
@property(nonatomic, retain) NSString *campaignsStateFilePath;
@property(nonatomic, retain) NSDate *initialisedTime; // SDK init time
@property(nonatomic, retain) NSDate *showMessagesAfterLaunch; // Only show messages after this time.
@property(nonatomic, retain) NSDate *showMessagesAfterDelay; // Only show messages after this time.
#if TARGET_OS_IOS
@property(nonatomic) bool pushEnabled; // Decide if push notification is enabled
@property(nonatomic, retain) NSSet *provisionalPushNotificationEvents; // Events that trigger the provisional push permission request
@property(nonatomic, retain) NSSet *pushNotificationPermissionEvents; // Events that trigger the push notification dialog
#endif //TARGET_OS_IOS
@property(nonatomic) bool autoShowMessagesEnabled;
@property(nonatomic, retain) UIWindow *inAppMessageWindow;
@property(nonatomic) SwrveActionType inAppMessageActionType;
@property(nonatomic, retain) NSString *inAppMessageAction;
@property(nonatomic, retain) NSString *inAppButtonPressedName;
@property(nonatomic, retain) NSString *inAppButtonPressedText;

// Current Device Properties
@property(nonatomic) int device_width;
@property(nonatomic) int device_height;
@property(nonatomic) SwrveInterfaceOrientation orientation;

// Only ever show this many messages. This number is decremented each time a message is shown.
@property(atomic) long messagesLeftToShow;
@property(atomic) NSTimeInterval minDelayBetweenMessage;

@property(nonatomic, retain) NSMutableArray *iamQueue;

@end

@implementation SwrveMessageController

@synthesize addedNotificiationsForMenuWindow;
@synthesize originalMenuWindowLevel;
@synthesize server, apiKey;
@synthesize campaignFile;
@synthesize manager;
@synthesize campaignsStateFilePath;
@synthesize initialisedTime;
@synthesize showMessagesAfterLaunch;
@synthesize showMessagesAfterDelay;
@synthesize messagesLeftToShow;
@synthesize inAppMessageConfig;
@synthesize embeddedMessageConfig;
@synthesize campaigns;
@synthesize campaignsState;
@synthesize assetsManager;
@synthesize user;
@synthesize notifications;
@synthesize language;
#if TARGET_OS_IOS
@synthesize pushEnabled;
@synthesize provisionalPushNotificationEvents;
@synthesize pushNotificationPermissionEvents;
#endif //TARGET_OS_IOS
@synthesize inAppMessageWindow;
@synthesize inAppMessageActionType;
@synthesize inAppMessageAction;
@synthesize inAppButtonPressedName;
@synthesize inAppButtonPressedText;
@synthesize device_width;
@synthesize device_height;
@synthesize orientation;
@synthesize autoShowMessagesEnabled;
@synthesize analyticsSDK;
@synthesize minDelayBetweenMessage;
@synthesize personalizationCallback;
@synthesize iamQueue;

+ (void)initialize {
    
#if TARGET_OS_IOS /** exclude tvOS **/
    ALL_SUPPORTED_DYNAMIC_DEVICE_FILTERS = [NSArray arrayWithObjects:
                                            [[swrve_permission_location_always stringByAppendingString:swrve_permission_requestable] lowercaseString],
                                            [[swrve_permission_location_when_in_use stringByAppendingString:swrve_permission_requestable] lowercaseString],
                                            [[swrve_permission_photos stringByAppendingString:swrve_permission_requestable] lowercaseString],
                                            [[swrve_permission_camera stringByAppendingString:swrve_permission_requestable] lowercaseString],
                                            [[swrve_permission_contacts stringByAppendingString:swrve_permission_requestable] lowercaseString],
                                            [[swrve_permission_push_notifications stringByAppendingString:swrve_permission_requestable] lowercaseString], nil];
    SUPPORTED_STATIC_DEVICE_FILTERS = [NSArray arrayWithObjects:@"ios", nil];
    SUPPORTED_DEVICE_FILTERS = [NSMutableArray arrayWithArray:SUPPORTED_STATIC_DEVICE_FILTERS];
    [(NSMutableArray *) SUPPORTED_DEVICE_FILTERS addObjectsFromArray:ALL_SUPPORTED_DYNAMIC_DEVICE_FILTERS];
#endif //TARGET_OS_IOS
}

- (id)initWithSwrve:(Swrve *)sdk {
    self = [super init];
    
    if (sdk == nil) {
        return self;
    }
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    self.assetsManager = [[SwrveAssetsManager alloc] initWithRestClient:sdk.restClient andCacheFolder:cacheFolder];
    self.campaignsStateFilePath = [SwrveLocalStorage campaignsStateFilePathForUserId:[sdk userID]];
    
    CGRect screen_bounds = [SwrveUtils deviceScreenBounds];
    self.device_height = (int) screen_bounds.size.height;
    self.device_width = (int) screen_bounds.size.width;
    self.orientation = sdk.config.orientation;
    self.language = sdk.language;
    self.user = [sdk userID];
    self.apiKey = sdk.apiKey;
    self.server = sdk.config.contentServer;
    self.analyticsSDK = sdk;
#if TARGET_OS_IOS
    self.pushEnabled = sdk.config.pushEnabled;
    self.provisionalPushNotificationEvents = sdk.config.provisionalPushNotificationEvents;
    self.pushNotificationPermissionEvents = sdk.config.pushNotificationPermissionEvents;
#endif //TARGET_OS_IOS
    self.inAppMessageConfig = sdk.config.inAppMessageConfig;
    
    if (self.inAppMessageConfig.personalizationCallback != nil) {
        self.personalizationCallback = self.inAppMessageConfig.personalizationCallback;
    }
    
    self.embeddedMessageConfig = sdk.config.embeddedMessageConfig;
    self.personalizationCallback = self.inAppMessageConfig.personalizationCallback;
    
    self.manager = [NSFileManager defaultManager];
    self.notifications = [NSMutableArray new];
    self.autoShowMessagesEnabled = YES;
    
    // Game rule defaults
    self.initialisedTime = [sdk getNow];
    self.showMessagesAfterLaunch = [sdk getNow];
    self.messagesLeftToShow = LONG_MAX;
    
    NSAssert1([self.language length] > 0, @"Invalid language specified %@", self.language);
    NSAssert1([self.user length] > 0, @"Invalid username specified %@", self.user);
    NSAssert(self.analyticsSDK != NULL, @"Swrve Analytics SDK is null", nil);
    
#if TARGET_OS_IOS
    NSData *device_token = [SwrveLocalStorage deviceToken];
    if (self.pushEnabled && device_token) {
        // Once we have a device token, ask for it every time as it may change under certain circumstances
        [SwrvePermissions refreshDeviceToken:(id <SwrveCommonDelegate>) analyticsSDK];
    }
#endif //TARGET_OS_IOS
    
    self.campaignsState = [NSMutableDictionary new];
    // Initialize campaign cache file
    [self initCampaignsFromCacheFile];
    self.iamQueue = [NSMutableArray new];
    
    return self;
}

- (void)campaignsStateFromDisk:(NSMutableDictionary *)states {
    NSData *data = [NSData dataWithContentsOfFile:self.campaignsStateFilePath];
    if (!data) {
        [SwrveLogger debug:@"No campaigns states loaded. [Reading from %@]", [self.campaignsStateFilePath lastPathComponent]];
        return;
    }
    
    NSError *error = NULL;
    NSArray *loadedStates = [NSPropertyListSerialization propertyListWithData:data
                                                                      options:NSPropertyListImmutable
                                                                       format:NULL
                                                                        error:&error];
    if (error) {
        [SwrveLogger error:@"Could not load campaign states from disk.\nError: %@\njson: %@", error, data];
    } else {
        @synchronized (states) {
            for (NSDictionary *dicState in loadedStates) {
                SwrveCampaignState *state = [[SwrveCampaignState alloc] initFrom: dicState];
                NSString *stateKey = [NSString stringWithFormat:@"%lu", (unsigned long) state.campaignID];
                [states setValue:state forKey:stateKey];
            }
        }
    }
}

- (void)campaignsStateFromDefaults:(NSMutableDictionary *)states {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:self.campaignsStateFilePath.lastPathComponent];
    if (!data) {
        [SwrveLogger debug:@"No campaigns states loaded. [Reading from defaults %@]", self.campaignsStateFilePath.lastPathComponent];
        return;
    }
    
    NSError *error = NULL;
    NSArray *loadedStates = [NSPropertyListSerialization propertyListWithData:data
                                                                      options:NSPropertyListImmutable
                                                                       format:NULL
                                                                        error:&error];
    if (error) {
        [SwrveLogger error:@"Could not load campaign states from disk.\nError: %@\njson: %@", error, data];
    } else {
        @synchronized (states) {
            for (NSDictionary *dicState in loadedStates) {
                SwrveCampaignState *state = [[SwrveCampaignState alloc] initFrom: dicState];
                NSString *stateKey = [NSString stringWithFormat:@"%lu", (unsigned long) state.campaignID];
                [states setValue:state forKey:stateKey];
            }
        }
    }
}

- (void)saveCampaignsState {
#if TARGET_OS_IOS
    [self saveCampaignsStateToFile];
#else
    [self saveCampaignsStateToDefaults];
#endif
}

- (void)saveCampaignsStateToFile {
    NSMutableArray *newStates;
    @synchronized (self.campaignsState) {
        newStates = [[NSMutableArray alloc] initWithCapacity:self.campaignsState.count];
        [self.campaignsState enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
#pragma unused(key, stop)
            [newStates addObject:[value asDictionary]];
        }];
    }
    
    NSError *error = NULL;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:newStates
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:&error];
    
    if (error) {
        [SwrveLogger error:@"Could not serialize campaign states.\nError: %@\njson: %@", error, newStates];
    } else if (data) {
        BOOL success = [data writeToFile:self.campaignsStateFilePath atomically:YES];
        if (!success) {
            [SwrveLogger error:@"Error saving campaigns state to: %@", self.campaignsStateFilePath];
        }
    } else {
        [SwrveLogger error:@"Error saving campaigns state: %@ writing to %@", error, self.campaignsStateFilePath];
    }
}

- (void)saveCampaignsStateToDefaults {
    NSMutableArray *newStates;
    @synchronized (self.campaignsState) {
        newStates = [[NSMutableArray alloc] initWithCapacity:self.campaignsState.count];
        [self.campaignsState enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
#pragma unused(key, stop)
            [newStates addObject:[value asDictionary]];
        }];
    }
    
    NSError *error = NULL;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:newStates
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:&error];
    
    if (error) {
        [SwrveLogger error:@"Could not serialize campaign states.\nError: %@\njson: %@", error, newStates];
    } else if (data && self.campaignsStateFilePath.lastPathComponent != nil) {
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:self.campaignsStateFilePath.lastPathComponent];
    } else {
        [SwrveLogger error:@"Error saving campaigns state: %@ writing to %@", error, self.campaignsStateFilePath];
    }
}


- (void)initCampaignsFromCacheFile {
    // Create campaign cache folder
    NSString *cacheFolder = [assetsManager cacheFolder];
    NSError *error;
    if (![manager createDirectoryAtPath:cacheFolder
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error]) {
        [SwrveLogger error:@"Error creating %@: %@", cacheFolder, error];
    }
    // Create signature protected cache file
    campaignFile = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_CAMPAIGN_FILE
                                                                   userID:self.user
                                                             signatureKey:[self.analyticsSDK signatureKey]
                                                            errorDelegate:nil];
#if TARGET_OS_IOS
    // Read from cache the state of campaigns
    [self campaignsStateFromDisk:self.campaignsState];
#else
    [self campaignsStateFromDefaults:self.campaignsState];
#endif
    // Read content of campaigns file and update campaigns
    NSData *content = [campaignFile readWithRespectToPlatform];
    
    if (content != nil) {
        NSError *jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:0 error:&jsonError];
        if (!jsonError) {
            BOOL isLoadingPreviousCampaignState = ![[SwrveQA sharedInstance] resetDeviceState];
            // A cache load is not a campaigns change, so notifyCampaignsUpdated is NO.
            [self updateCampaigns:jsonDict withLoadingPreviousCampaignState:isLoadingPreviousCampaignState notifyCampaignsUpdated:NO];
        }
    } else {
        [self.analyticsSDK invalidateETag];
    }
}

static NSNumber *numberFromJsonWithDefault(NSDictionary *json, NSString *key, int defaultValue) {
    NSNumber *result = [json objectForKey:key];
    if (result == nil) {
        result = [NSNumber numberWithInt:defaultValue];
    }
    return result;
}

- (void)writeToCampaignCache:(NSData *)campaignData {
    [self.campaignFile writeWithRespectToPlatform:campaignData];
}

- (BOOL)canSupportDeviceFilter:(NSString *)filter {
    // Used to check all global filters this SDK supports
    return [SUPPORTED_DEVICE_FILTERS containsObject:[filter lowercaseString]];
}

- (BOOL)filtersOk:(NSArray *)filters {
    // Check device filters (permission requests, platform)
    if (filters != nil) {
        for (NSString *filter in filters) {
            if (![self canSupportDeviceFilter:filter]) {
                return false;
            }
        }
    }
    return true;
}

- (NSArray *)currentlySupportedDeviceFilters {
    NSMutableArray *supported = [NSMutableArray arrayWithArray:SUPPORTED_STATIC_DEVICE_FILTERS];
#if TARGET_OS_IOS /** exclude tvOS **/
    NSArray *currentPermissionFilters = [SwrvePermissions currentPermissionFilters];
    [supported addObjectsFromArray:currentPermissionFilters];
#endif
    return supported;
}

- (void)updateCampaigns:(NSDictionary *)campaignDic withLoadingPreviousCampaignState:(BOOL)isLoadingPreviousCampaignState notifyCampaignsUpdated:(BOOL)notifyCampaignsUpdated {
    
    if (campaignDic == nil) {
        [SwrveLogger error:@"Error parsing campaign JSON", nil];
        return;
    }
    
    if ([campaignDic count] == 0) {
        [SwrveLogger debug:@"Campaign JSON empty, no campaigns downloaded", nil];
        self.campaigns = [NSArray new];
        if (notifyCampaignsUpdated) {
            // No assets to wait for, so notify here rather than from the completion handler below.
            [self.analyticsSDK invokeCampaignsUpdatedDelegate];
        }
        return;
    }
    
    NSMutableSet *assetsQueue = [NSMutableSet new];
    NSMutableArray *result = [NSMutableArray new];
    
    // Version check
    NSNumber *version = [campaignDic objectForKey:@"version"];
    if ([version integerValue] != CAMPAIGN_RESPONSE_VERSION) {
        [SwrveLogger error:@"Campaign JSON has the wrong version. No campaigns loaded.", nil];
        return;
    }
    
    [self updateCdnPaths:campaignDic];
    
    NSDictionary *rules = [campaignDic objectForKey:@"rules"];
    {
        NSNumber *delay = numberFromJsonWithDefault(rules, @"delay_first_message", DEFAULT_DELAY_FIRST_MESSAGE);
        NSNumber *maxShows = numberFromJsonWithDefault(rules, @"max_messages_per_session", DEFAULT_MAX_SHOWS);
        NSNumber *minDelay = numberFromJsonWithDefault(rules, @"min_delay_between_messages", DEFAULT_MIN_DELAY);
        
        self.showMessagesAfterLaunch = [self.initialisedTime dateByAddingTimeInterval:delay.doubleValue];
        self.minDelayBetweenMessage = minDelay.doubleValue;
        self.messagesLeftToShow = maxShows.longValue;
        
        [SwrveLogger debug:@"Game rules OK: Delay Seconds: %@ Max shows: %@ ", delay, maxShows];
        [SwrveLogger debug:@"Time is %@ show messages after %@", [self.analyticsSDK getNow], [self showMessagesAfterLaunch]];
    }
    
    // Call personalization
    NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:nil];
    
    NSMutableDictionary *campaignsDownloaded = nil;
    if ([[SwrveQA sharedInstance] isQALogging]) {
        campaignsDownloaded = [NSMutableDictionary new];
    }
    
    // Empty saved push notifications
    [self.notifications removeAllObjects];
    
    NSArray *jsonCampaigns = [campaignDic objectForKey:@"campaigns"];
    bool saveNewCampaignState = false;
    for (NSDictionary *dict in jsonCampaigns) {
        SwrveCampaign *campaign = nil;
        if ([dict objectForKey:@"message"] != nil) {
            campaign = [[SwrveInAppCampaign alloc] initAtTime:self.initialisedTime fromDictionary:dict withAssetsQueue:assetsQueue forController:self withPersonalization:personalizationProperties];
        } else if ([dict objectForKey:@"embedded_message"] != nil) {
            campaign = [[SwrveEmbeddedCampaign alloc] initAt:self.initialisedTime from:dict];
        }
        
        if (campaign != nil) {
            @synchronized (self.campaignsState) {
                NSString *campaignIDStr = [NSString stringWithFormat:@"%lu", (unsigned long) campaign.ID];
                [SwrveLogger debug:@"Got campaign with id %@", campaignIDStr];
                SwrveCampaignState *campaignState = [self.campaignsState objectForKey:campaignIDStr];
                if (!campaignState) {
                    // A campaign with no state means it hasn't ever been triggered and is potentially new. Save the campaign state to record the download time.
                    saveNewCampaignState = true;
                }
                if (isLoadingPreviousCampaignState && campaignState) {
                    [campaign setState:campaignState];
                }
                [self.campaignsState setValue:campaign.state forKey:campaignIDStr];
            }
            [result addObject:campaign];
            
            if ([[SwrveQA sharedInstance] isQALogging]) {
                // Add campaign for QA purposes
                [campaignsDownloaded setValue:@"" forKey:[NSString stringWithFormat:@"%ld", (long) campaign.ID]];
            }
        }
    }
    
    if (saveNewCampaignState) {
        [self saveCampaignsState];
    }
    
    // QA logging
    [SwrveQA campaignsDownloaded:jsonCampaigns];
    
    // Must stay above downloadAssets: its completion handler reaches autoShowMessages, which reads self.campaigns, and that handler runs synchronously when there is nothing left to fetch.
    self.campaigns = [result copy];

    // Obtain assets we don't have yet
    [assetsManager downloadAssets:assetsQueue withCompletionHandler:^{
        [self autoShowMessages];
        if (notifyCampaignsUpdated) {
            // Campaigns are filtered on assetsReady, so this is the earliest point at which the new ones are actually returned by the getters.
            [self.analyticsSDK invokeCampaignsUpdatedDelegate];
        }
    }];
}

- (void)updateCdnPaths:(NSDictionary *)campaignJson {
    NSDictionary *cdnPaths = [campaignJson objectForKey:@"cdn_paths"];
    if (cdnPaths) {
        NSString *cdnImages = [cdnPaths objectForKey:@"message_images"];
        [assetsManager setCdnImages:cdnImages];
        NSString *cdnFonts = [cdnPaths objectForKey:@"message_fonts"];
        [assetsManager setCdnFonts:cdnFonts];
        [SwrveLogger debug:@"CDN URL images: %@ fonts:%@", cdnImages, cdnFonts];
    } else {
        NSString *cdnRoot = [campaignJson objectForKey:@"cdn_root"];
        [assetsManager setCdnImages:cdnRoot];
        [SwrveLogger debug:@"CDN URL: %@", cdnRoot];
    }
}


- (void)refreshInAppCampaignAssets {
    // Call personalization
    NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:nil];
    
    // Obtain all assets required for the available campaigns
    NSMutableSet *assetsQ = [[NSMutableSet alloc] init];
    for (SwrveCampaign *campaign in self.campaigns) {
        if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
            SwrveInAppCampaign *swrveCampaign = (SwrveInAppCampaign *) campaign;
            [swrveCampaign addAssetsToQueue:assetsQ withPersonalization:personalizationProperties];
        }
    }
    
    [assetsManager downloadAssets:assetsQ withCompletionHandler:^{
        [self.analyticsSDK invokeCampaignsUpdatedDelegate];
    }];
}

- (void)appDidBecomeActive {
    
    // Call personalization
    NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:nil];
    
    // Obtain all assets required for the available campaigns
    NSMutableSet *assetsQ = [[NSMutableSet alloc] init];
    for (SwrveCampaign *campaign in self.campaigns) {
        if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
            SwrveInAppCampaign *swrveCampaign = (SwrveInAppCampaign *) campaign;
            [swrveCampaign addAssetsToQueue:assetsQ withPersonalization:personalizationProperties];
        }
    }
    
    // Obtain assets we don't have yet
    [assetsManager downloadAssets:assetsQ withCompletionHandler:^{
        [self autoShowMessages];
    }];
}

- (void)autoShowMessages {
    
    // Don't do anything if we've already shown a message or if it is too long after session start
    if (![self autoShowMessagesEnabled]) {
        return;
    }
    
    // Only execute if at least 1 call to the /user_content api endpoint has been completed
    if (![self.analyticsSDK campaignsAndResourcesInitialized]) {
        return;
    }
    
    for (SwrveCampaign *campaign in self.campaigns) {
        if ([campaign isKindOfClass:[SwrveInAppCampaign class]] || [campaign isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            
            BOOL hasEmbeddedPresent = NO;
            BOOL hasInAppPresent = NO;
            
            if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
                SwrveInAppCampaign *specificCampaign = (SwrveInAppCampaign *) campaign;
                if ([specificCampaign hasMessageForEvent:AUTOSHOW_AT_SESSION_START_TRIGGER withPayload:nil]) {
                    hasInAppPresent = YES;
                }
            }
            
            if ([campaign isKindOfClass:[SwrveEmbeddedCampaign class]]) {
                SwrveEmbeddedCampaign *embedded = (SwrveEmbeddedCampaign *) campaign;
                if ([embedded hasMessageForEvent:AUTOSHOW_AT_SESSION_START_TRIGGER withPayload:nil]) {
                    hasEmbeddedPresent = YES;
                }
            }
            
            // if either message is available for display then proceed
            if (hasInAppPresent || hasEmbeddedPresent) {
                @synchronized (self) {
                    if ([self autoShowMessagesEnabled]) {
                        NSDictionary *event = @{@"type": @"event", @"name": AUTOSHOW_AT_SESSION_START_TRIGGER};
                        if ([self eventRaised:event]) {
                            // If a message was shown we want to disable autoshow
                            [self setAutoShowMessagesEnabled:NO];
                        }
                    }
                }
                break;
            }
            
        }
    }
}

- (BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate *)now {
    return [now compare:[self showMessagesAfterLaunch]] == NSOrderedAscending;
}

- (BOOL)isTooSoonToShowMessageAfterDelay:(NSDate *)now {
    return [now compare:[self showMessagesAfterDelay]] == NSOrderedAscending;
}

- (BOOL)hasShowTooManyMessagesAlready {
    return self.messagesLeftToShow <= 0;
}

- (BOOL)checkGlobalRulesForCampaignType:(SwrveCampaignType)type
                          withEventName:(NSString *)eventName
                       withEventPayload:(NSDictionary *)eventPayload
                               withDate:(NSDate *)now {
    NSString *reason = nil;
    NSString *campaignType = swrveCampaignTypeToString(type);
    if ([self.campaigns count] == 0) {
        reason = [NSString stringWithFormat:@"No %@s available", campaignType];
        [self noMessagesWereShownForEventName:eventName withPayload:eventPayload withReason:reason];
        return NO;
    }
    
    // Ignore delay after launch throttle limit for auto show messages
    if ([eventName caseInsensitiveCompare:AUTOSHOW_AT_SESSION_START_TRIGGER] != NSOrderedSame && [self isTooSoonToShowMessageAfterLaunch:now]) {
        reason = [NSString stringWithFormat:@"{App throttle limit} Too soon after launch. Wait until %@", [[self class] formattedTime:self.showMessagesAfterLaunch]];
        [self noMessagesWereShownForEventName:eventName withPayload:eventPayload withReason:reason];
        return NO;
    }
    
    if ([self isTooSoonToShowMessageAfterDelay:now]) {
        reason = [NSString stringWithFormat:@"{App throttle limit} Too soon after last %@. Wait until %@", campaignType, [[self class] formattedTime:self.showMessagesAfterDelay]];
        [self noMessagesWereShownForEventName:eventName withPayload:eventPayload withReason:reason];
        return NO;
    }
    
    if ([self hasShowTooManyMessagesAlready]) {
        reason = [NSString stringWithFormat:@"{App Throttle limit} Too many %@ s shown", campaignType];
        [self noMessagesWereShownForEventName:eventName withPayload:eventPayload withReason:reason];
        return NO;
    }
    return YES;
}

- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload {
    if (analyticsSDK == nil || self.campaigns == nil) {
        [SwrveLogger debug:@"Not showing message: no campaigns"];
        return nil;
    }
    
    NSDate *now = [self.analyticsSDK getNow];
    SwrveBaseMessage *result = nil;
    SwrveCampaign *campaign = nil;
    BOOL isQALogging = [[SwrveQA sharedInstance] isQALogging];
    
    NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:payload];
    
    if (![self checkGlobalRulesForCampaignType:SWRVE_CAMPAIGN_IAM withEventName:eventName withEventPayload:payload withDate:now]
        && ![self checkGlobalRulesForCampaignType:SWRVE_CAMPAIGN_EMBEDDED withEventName:eventName withEventPayload:payload withDate:now]) {
        return nil;
    }
    
    NSMutableArray<SwrveQACampaignInfo *> *qaCampaignInfoArray = nil;
    NSMutableDictionary *campaignReasons = [NSMutableDictionary new];
    if (isQALogging) {
        qaCampaignInfoArray = [NSMutableArray new];
    }
    
    NSMutableArray *availableMessages = [NSMutableArray new];
    NSNumber *minPriority = [NSNumber numberWithInteger:INT_MAX]; // Select messages with higher priority that have the current orientation
    NSMutableArray *candidateMessages = [NSMutableArray new];
    for (SwrveCampaign *baseCampaignIt in self.campaigns) {
        SwrveBaseMessage *nextMessage;
        if ([baseCampaignIt isKindOfClass:[SwrveInAppCampaign class]]) {
            SwrveInAppCampaign *campaignIt = (SwrveInAppCampaign *) baseCampaignIt;
            NSSet *assetsOnDisk = [assetsManager assetsOnDisk];
            nextMessage = [campaignIt messageForEvent:eventName withPayload:payload withAssets:assetsOnDisk withPersonalization:personalizationProperties atTime:now withReasons:campaignReasons];
        } else if ([baseCampaignIt isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            SwrveEmbeddedCampaign *campaignIt = (SwrveEmbeddedCampaign *) baseCampaignIt;
            nextMessage = [campaignIt messageForEvent:eventName withPayload:payload at:now withReasons:campaignReasons];
        }
        
        if (nextMessage != nil) {
            [availableMessages addObject:nextMessage]; // Add to list of returned messages
            long nextMessagePriorityLong = [nextMessage.priority longValue]; // Check if it is a candidate to be shown
            long minPriorityLong = [minPriority longValue];
            if (nextMessagePriorityLong <= minPriorityLong) {
                if (nextMessagePriorityLong < minPriorityLong) {
                    [candidateMessages removeAllObjects]; // If it is lower than any of the previous ones remove those from being candidates
                }
                minPriority = nextMessage.priority;
                [candidateMessages addObject:nextMessage];
            }
        } else {
            
            if (isQALogging) {
                if ([baseCampaignIt isKindOfClass:[SwrveInAppCampaign class]]) {
                    SwrveInAppCampaign *campaignIt = (SwrveInAppCampaign *) baseCampaignIt;
                    // If we are a QA user and it's an invalid campaign we do save it as part of this loop.
                    if (campaignIt.message != nil) {
                        SwrveMessage *message = campaignIt.message;
                        NSString *reason = [campaignReasons objectForKey:[NSString stringWithFormat:@"%ld", (long) [campaignIt ID]]];
                        [qaCampaignInfoArray addObject:[[SwrveQACampaignInfo alloc] initWithCampaignID:campaignIt.ID variantID:[message.messageID unsignedLongValue] type:SWRVE_CAMPAIGN_IAM displayed:NO reason:reason]];
                    }
                } else if ([baseCampaignIt isKindOfClass:[SwrveEmbeddedCampaign class]]) {
                    SwrveEmbeddedCampaign *campaignIt = (SwrveEmbeddedCampaign *) baseCampaignIt;
                    NSString *reason = [campaignReasons objectForKey:[NSString stringWithFormat:@"%ld", (long) [campaignIt ID]]];
                    [qaCampaignInfoArray addObject:[[SwrveQACampaignInfo alloc] initWithCampaignID:campaignIt.ID variantID:[campaignIt.message.messageID unsignedLongValue] type:SWRVE_CAMPAIGN_EMBEDDED displayed:NO reason:reason]];
                }
            }
        }
    }
    
    NSArray *shuffledCandidates = [SwrveMessageController shuffled:candidateMessages];
    if ([shuffledCandidates count] > 0) {
        result = [shuffledCandidates objectAtIndex:0];
        campaign = result.campaign;
    }
    
    if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
        bool filterRedundantCampaign = [self filterRedundantCampaign:(SwrveMessage *) result];
        result = (filterRedundantCampaign) ? nil : result;
        if (isQALogging && filterRedundantCampaign) {
            NSString *reason = [NSString stringWithFormat:@"Campaign %ld was selected for display but canRequestCapability delegate returned false", (long) campaign.ID];
            [qaCampaignInfoArray addObject:[[SwrveQACampaignInfo alloc] initWithCampaignID:campaign.ID variantID:[result.messageID unsignedLongValue] type:campaign.campaignType displayed:NO reason:reason]];
        }
    }
    
    if (isQALogging && campaign != nil && result != nil) {
        // A message was chosen, set the reason for the others
        for (SwrveBaseMessage *otherMessage in availableMessages) {
            SwrveCampaign *c = otherMessage.campaign;
            if (result != otherMessage && c != nil) {
                NSString *reason = [NSString stringWithFormat:@"Campaign %ld was selected for display ahead of this campaign", (long) campaign.ID];
                [qaCampaignInfoArray addObject:[[SwrveQACampaignInfo alloc] initWithCampaignID:c.ID variantID:[otherMessage.messageID unsignedLongValue] type:c.campaignType displayed:NO reason:reason]];
            }
        }
        // Add the chosen message as well.
        [qaCampaignInfoArray addObject:[[SwrveQACampaignInfo alloc] initWithCampaignID:campaign.ID variantID:[result.messageID unsignedLongValue] type:campaign.campaignType displayed:YES reason:@""]];
    }
    
    [SwrveQA messageCampaignTriggered:eventName eventPayload:payload displayed:(result != nil) campaignInfoDict:qaCampaignInfoArray];
    
    if (result == nil) {
        [SwrveLogger debug:@"Not showing message: no candidate base message for %@", eventName];
    }
    return result;
}

- (BOOL)filterRedundantCampaign:(SwrveMessage *)message {
    // Check all buttons to see if any are requesting a capability or action that's already granted or not relevant, thus making the campaign redundant
    
    id <SwrveInAppCapabilitiesDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppCapabilitiesDelegate;
    for (SwrveMessageFormat *format in message.formats) {
        NSDictionary *pages = [format pages];
        for (id key in pages) {
            SwrveMessagePage *page = [pages objectForKey:key];
            for (SwrveButton *button in page.buttons) {
                bool canRequest = true;
                if (button.actionType == kSwrveActionCapability && [button.actionString isEqualToString:@"swrve.push"]) {
#if TARGET_OS_IOS
                    if (self.pushEnabled) {
                        canRequest = ![SwrvePermissions didWeAskForPushPermissionsAlready];
                    } else {
                        canRequest = false;
                        [SwrveLogger error:@"Push is not enabled"];
                    }
#else
                    canRequest = false; // TARGET_OS_TV cannot request push capability
#endif
                } else if (button.actionType == kSwrveActionCapability && button.actionString != nil) {
                    if (delegate != nil && [delegate respondsToSelector:@selector(canRequestCapability:)]) {
                        canRequest = [delegate canRequestCapability:button.actionString];
                    } else {
                        canRequest = false;
                    }
                } else if (button.actionType == kSwrveActionStartGeo) {
                    canRequest = [self shouldStartSwrveGeoSDK];
                }
                
                if (!canRequest) {
                    return true; // no need to check any other buttons so exit fast
                }
            }
        }
    }
    
    return false;
}

- (void)noMessagesWereShownForEventName:(NSString *)eventName
                            withPayload:(NSDictionary *)eventPayload
                             withReason:(NSString *)reason {
    [SwrveQA campaignTriggered:eventName eventPayload:eventPayload displayed:NO reason:reason campaignInfo:nil];
}

+ (NSString *)formattedTime:(NSDate *)date {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"HH:mm:ss Z"];
    return [dateFormatter stringFromDate:date];
}

+ (NSArray *)shuffled:(NSArray *)source; {
    unsigned long count = [source count];
    
    // Early out if there is 0 or 1 elements.
    if (count < 2) {
        return source;
    }
    
    // Copy
    NSMutableArray *result = [NSMutableArray arrayWithArray:source];
    
    for (unsigned long i = 0; i < count; i++) {
        unsigned long remain = count - i;
        unsigned long n = (arc4random() % remain) + i;
        [result exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    
    return result;
}

- (void)setMessageMinDelayThrottle {
    NSDate *now = [self.analyticsSDK getNow];
    [self setShowMessagesAfterDelay:[now dateByAddingTimeInterval:[self minDelayBetweenMessage]]];
}

- (void)messageWasShownToUser:(SwrveMessage *)message {
    [self baseMessageWasHandledOrShownToUser:message embedded:@"false"];
    id <SwrveInAppMessageDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppMessageDelegate;
    if (delegate != nil && [delegate respondsToSelector:@selector(onAction:messageDetails:selectedButton:)]) {
        SwrveMessageDetails *md = [self messageDetails:message];
        [delegate onAction:SwrveMessageActionImpression messageDetails:md selectedButton:nil];
    }
}

- (void)embeddedMessageWasShownToUser:(SwrveEmbeddedMessage *)message {
    [self baseMessageWasHandledOrShownToUser:message embedded:@"true"];
}

- (void)baseMessageWasHandledOrShownToUser:(SwrveBaseMessage *)message embedded:(NSString *)embedded {
    // The message was shown. Take the current time so that we can throttle messages from being shown too quickly.
    [self setMessageMinDelayThrottle];
    [self setMessagesLeftToShow:self.messagesLeftToShow - 1];
    
    SwrveCampaign *campaign = message.campaign;
    if (campaign != nil) {
        NSDate *now = [self.analyticsSDK getNow];
        [campaign wasShownToUserAt:now];
    }
    [self saveCampaignsState];
    
    [self sendImpressionEvent:message embedded:embedded];
}

- (void)embeddedControlMessageImpressionEvent:(SwrveEmbeddedMessage *)message {
    [self sendImpressionEvent:message embedded:@"true"];
}

- (void)sendImpressionEvent:(SwrveBaseMessage *)message embedded:(NSString *)embedded {
    NSString *viewEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%d.impression", [message.messageID intValue]];
    NSMutableDictionary *payload = [SwrveUtils iamCommonEventPayload];
    [payload setValue:embedded forKey:@"embedded"];
    [SwrveLogger debug:@"Queuing message impression event: %@", viewEvent];
    [self.analyticsSDK eventInternal:viewEvent payload:payload triggerCallback:false];
}

- (void)queueMessageClickEvent:(SwrveButton *)button page:(SwrveMessagePage *)page {
    if (button.actionType != kSwrveActionDismiss) {
        NSString *clickEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%lld.click", button.messageId];
        [SwrveLogger debug:@"Sending click event: %@", clickEvent];
        NSMutableDictionary *payload = [SwrveUtils iamCommonEventPayload];
        [payload setValue:button.name forKey:@"name"];
        [payload setValue:@"false" forKey:@"embedded"];
        if (page && page.pageName && page.pageName.length > 0) {
            [payload setValue:page.pageName forKey:@"pageName"];
        }
        if (page && page.pageId > 0) {
            [payload setValue:[NSNumber numberWithLong:page.pageId] forKey:@"contextId"];
        }
        if (button.buttonId && [button.buttonId integerValue] > 0) {
            [payload setValue:button.buttonId forKey:@"buttonId"];
        }
        [self.analyticsSDK eventInternal:clickEvent payload:payload triggerCallback:false];
    }
}

- (void)embeddedButtonWasPressed:(SwrveEmbeddedMessage *)message buttonName:(NSString *)button {
    if (message != nil) {
        NSString *clickEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%ld.click", [message.messageID longValue]];
        [SwrveLogger debug:@"Sending click event: %@", clickEvent];
        NSDictionary *payload = @{@"name": button, @"embedded": @"true"};
        [self.analyticsSDK eventInternal:clickEvent payload:payload triggerCallback:false];
    }
}

- (NSString *)personalizeEmbeddedMessageData:(SwrveEmbeddedMessage *)message withPersonalization:(NSDictionary *)personalizationProperties {
    if (message != nil) {
        NSError *error = nil;
        NSString *resolvedMessageData = nil;

        BOOL useLocalTimezone = message.campaign.useLocalTimezone;
        if (message.campaign.freemarkerEnabled && message.type == SwrveEmbeddedDataTypeJson) {
            resolvedMessageData = [self applyFreemarkerToJSONString:message.dataRaw properties:personalizationProperties useLocalTimezone:useLocalTimezone error:&error];
        } else if (message.campaign.freemarkerEnabled) {
            resolvedMessageData = [SwrveFreemarkerEvaluator evaluate:message.dataRaw properties:(NSDictionary<NSString*, id>*)personalizationProperties useLocalTimezone:useLocalTimezone error:&error];
        } else if (message.type == SwrveEmbeddedDataTypeJson) {
            resolvedMessageData = [TextTemplating templatedTextFromJSONString:message.dataRaw withProperties:personalizationProperties andError:&error];
        } else {
            resolvedMessageData = [TextTemplating templatedTextFromString:message.dataRaw withProperties:personalizationProperties andError:&error];
        }
        
        if (error != nil || resolvedMessageData == nil) {
            SwrveEmbeddedCampaign *campaign = (SwrveEmbeddedCampaign *) message.campaign;
            if (campaign != nil) {
                [SwrveLogger debug:@"For campaign id: %lu. Could not resolve personalization. Error: %@. Data: %@", (unsigned long)campaign.ID, error.localizedDescription, message.dataRaw];
                [SwrveQA embeddedPersonalizationFailed:[NSNumber numberWithUnsignedInteger:campaign.ID] variantId:message.messageID unresolvedData:message.dataRaw reason:@"Failed to resolve personalization"];
            } else {
                [SwrveLogger debug:@"Could not resolve embedded message personalization. Error: %@. Data: %@", error.localizedDescription, message.dataRaw];
            }
            return nil;
        } else {
            return resolvedMessageData;
        }
    }
    
    return nil;
}

- (NSString *)applyFreemarkerToJSONString:(NSString *)jsonString properties:(NSDictionary *)properties useLocalTimezone:(BOOL)useLocalTimezone error:(NSError **)error {
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseError = nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&parseError];
    if (parseError || !parsed) {
        if (error) *error = parseError;
        return nil;
    }
    id resolved = [self applyFreemarkerToJSONValue:parsed properties:properties useLocalTimezone:useLocalTimezone error:error];
    if ((error && *error) || !resolved) {
        return nil;
    }
    NSData *resultData = [NSJSONSerialization dataWithJSONObject:resolved options:0 error:error];
    if ((error && *error) || !resultData) {
        return nil;
    }
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

- (id)applyFreemarkerToJSONValue:(id)value properties:(NSDictionary *)properties useLocalTimezone:(BOOL)useLocalTimezone error:(NSError **)error {
    if ([value isKindOfClass:[NSString class]]) {
        NSString *resolved = [SwrveFreemarkerEvaluator evaluate:value properties:(NSDictionary<NSString*, id>*)properties useLocalTimezone:useLocalTimezone error:error];
        return (error && *error) ? nil : resolved;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        return [self applyFreemarkerToJSONDictionary:value properties:properties useLocalTimezone:useLocalTimezone error:error];
    } else if ([value isKindOfClass:[NSArray class]]) {
        return [self applyFreemarkerToJSONArray:value properties:properties useLocalTimezone:useLocalTimezone error:error];
    }
    return value;
}

- (NSDictionary *)applyFreemarkerToJSONDictionary:(NSDictionary *)dict properties:(NSDictionary *)properties useLocalTimezone:(BOOL)useLocalTimezone error:(NSError **)error {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:dict.count];
    for (NSString *key in dict) {
        NSString *resolvedKey = [SwrveFreemarkerEvaluator evaluate:key properties:(NSDictionary<NSString*, id>*)properties useLocalTimezone:useLocalTimezone error:error];
        if (error && *error) {
            [SwrveLogger debug:@"FreeMarker failed evaluating key '%@': %@", key, (*error).localizedDescription];
            return nil;
        }
        id resolvedValue = [self applyFreemarkerToJSONValue:dict[key] properties:properties useLocalTimezone:useLocalTimezone error:error];
        if (error && *error) {
            [SwrveLogger debug:@"FreeMarker failed evaluating value for key '%@': %@", key, (*error).localizedDescription];
            return nil;
        }
        result[resolvedKey] = resolvedValue;
    }
    return result;
}

- (NSArray *)applyFreemarkerToJSONArray:(NSArray *)array properties:(NSDictionary *)properties useLocalTimezone:(BOOL)useLocalTimezone error:(NSError **)error {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];
    for (id item in array) {
        id resolvedItem = [self applyFreemarkerToJSONValue:item properties:properties useLocalTimezone:useLocalTimezone error:error];
        if (error && *error) return nil;
        [result addObject:resolvedItem];
    }
    return result;
}

- (NSString *)personalizeText:(NSString *)text withPersonalization:(NSDictionary *)personalizationProperties {
    return [self personalizeText:text withPersonalization:personalizationProperties freemarkerEnabled:NO useLocalTimezone:NO];
}

- (NSString *)personalizeText:(NSString *)text withPersonalization:(NSDictionary *)personalizationProperties freemarkerEnabled:(BOOL)freemarkerEnabled useLocalTimezone:(BOOL)useLocalTimezone {
    if (text != nil) {
        NSError *error = nil;
        NSString *resolvedText;
        if (freemarkerEnabled) {
            resolvedText = [SwrveFreemarkerEvaluator evaluate:text properties:(NSDictionary<NSString*, id>*)personalizationProperties useLocalTimezone:useLocalTimezone error:&error];
        } else {
            resolvedText = [TextTemplating templatedTextFromString:text withProperties:personalizationProperties andError:&error];
        }
        if (error != nil || resolvedText == nil) {
            [SwrveLogger debug:@"Could not resolve personalization: %@", text];
            return nil;
        } else {
            return resolvedText;
        }
    }
    return nil;
}

- (NSString *)eventName:(NSDictionary *)eventParameters {
    NSString *eventName = @"";
    
    NSString *eventType = [eventParameters objectForKey:@"type"];
    if ([eventType isEqualToString:@"session_start"]) {
        eventName = @"Swrve.session.start";
    } else if ([eventType isEqualToString:@"session_end"]) {
        eventName = @"Swrve.session.end";
    } else if ([eventType isEqualToString:@"buy_in"]) {
        eventName = @"Swrve.buy_in";
    } else if ([eventType isEqualToString:@"iap"]) {
        eventName = @"Swrve.iap";
    } else if ([eventType isEqualToString:@"event"]) {
        eventName = [eventParameters objectForKey:@"name"];
    } else if ([eventType isEqualToString:@"purchase"]) {
        eventName = @"Swrve.user_purchase";
    } else if ([eventType isEqualToString:@"currency_given"]) {
        eventName = @"Swrve.currency_given";
    } else if ([eventType isEqualToString:@"user"]) {
        eventName = @"Swrve.user_properties_changed";
    }
    
    return eventName;
}

- (void)showMessage:(nullable SwrveMessage *)message {
    [self showMessage:message queue:false withPersonalization:nil];
}

- (void)showMessage:(nullable SwrveMessage *)message withPersonalization:(NSDictionary *)personalization {
    [self showMessage:message queue:false withPersonalization:personalization];
}

- (void)showMessage:(nullable SwrveMessage *)message queue:(bool)isQueued withPersonalization:(NSDictionary *)personalization {
    if (message == nil) {
        return;
    }
    @synchronized (self) {
        if (self.inAppMessageWindow == nil) {
            SwrveMessageViewController *messageViewController = [[SwrveMessageViewController alloc]
                                                                 initWithMessageController:self
                                                                 message:message
                                                                 personalization:personalization];
            [self showMessageWindow:messageViewController];
        } else if (isQueued && ![self.iamQueue containsObject:message]) {
            [self.iamQueue addObject:message];
        }
    }
}

- (UIWindow *)createUIWindow NS_EXTENSION_UNAVAILABLE_IOS("") {
    // Check if using Swift UI
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        for (UIWindowScene *wScene in [UIApplication sharedApplication].connectedScenes) {
            if (wScene.activationState == UISceneActivationStateForegroundActive) {
                UIWindow *window = wScene.windows.firstObject;
                return [[UIWindow alloc] initWithWindowScene:window.windowScene];
            }
        }
    }
    return [[UIWindow alloc] init];
}

- (void)handleNextIAM:(NSMutableArray *)queue {
    if ([queue count] > 0) {
        SwrveMessage *message = [queue objectAtIndex:0];
        [self showMessage:message queue:false withPersonalization:nil];
        [queue removeObjectAtIndex:0];
    }
}

- (void)showMessageWindow:(SwrveMessageViewController *)messageViewController {
    if (messageViewController == nil) {
        [SwrveLogger error:@"Cannot show a nil view.", nil];
        return;
    }
    
    if (self.inAppMessageWindow != nil) {
        [SwrveLogger warning:@"A message is already displayed, ignoring second message.", nil];
        return;
    }
    
    self.inAppMessageWindow = [self createUIWindow];
    self.inAppMessageWindow.backgroundColor = [UIColor clearColor];
    self.inAppMessageWindow.frame = [[UIScreen mainScreen] bounds];
    self.inAppMessageWindow.rootViewController.view.alpha = 0.0f;
    self.inAppMessageWindow.windowLevel = UIWindowLevelAlert + 1;
    [self.inAppMessageWindow makeKeyAndVisible];
    self.inAppMessageWindow.rootViewController = messageViewController;
    [self beginShowMessageAnimation:messageViewController];
    
    if (@available(iOS 13.0, *)) {
        if (!self.addedNotificiationsForMenuWindow) {
            self.addedNotificiationsForMenuWindow = true;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(willShowMenuNotification)
                                                         name:@"UIMenuControllerWillShowMenuNotification"
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(willHideMenuNotification)
                                                         name:@"UIMenuControllerWillHideMenuNotification"
                                                       object:nil];
        }
    }
}

- (void)willShowMenuNotification {
    if (self.inAppMessageWindow == nil) return;
    
    UIWindow *menuWindow = [self menuWindow];
    if (menuWindow != nil) {
        self.originalMenuWindowLevel = menuWindow.windowLevel;
        menuWindow.windowLevel = self.inAppMessageWindow.windowLevel + 1;
    }
}

- (void)willHideMenuNotification {
    if (self.inAppMessageWindow == nil) return;
    
    UIWindow *menuWindow = [self menuWindow];
    if (menuWindow != nil) {
        menuWindow.windowLevel = self.originalMenuWindowLevel;
        self.originalMenuWindowLevel = 0;
    }
}

- (UIWindow *)menuWindow NS_EXTENSION_UNAVAILABLE_IOS("") {
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if (!window.hidden && [window isKindOfClass:NSClassFromString(@"UITextEffectsWindow")]) {
            for (UIView *subview in [window subviews]) {
                if ([subview isKindOfClass:NSClassFromString(@"UICalloutBar")]) {
                    return window;
                }
            }
        }
    }
    return nil;
}

- (SwrveMessageDetails *)messageDetails:(SwrveMessage *)message {
    id <SwrveInAppMessageDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppMessageDelegate;
    if (delegate == nil || ![delegate respondsToSelector:@selector(onAction:messageDetails:selectedButton:)]) {
        return nil;
    }
    SwrveInAppCampaign *campaign = (SwrveInAppCampaign *) message.campaign;
    NSString *subject = @"";
    if (campaign.messageCenterDetails != nil) {
        subject = campaign.messageCenterDetails.subject;
    }
    
    NSMutableArray *allButtons = [NSMutableArray new];
    for (SwrveMessageFormat *format in message.formats) {
        NSDictionary *pages = [format pages];
        for (id key in pages) {
            SwrveMessagePage *page = [pages objectForKey:key];
            for (SwrveButton *button in page.buttons) {
                
                NSDictionary *personalizationProps = ((SwrveMessageViewController *) self.inAppMessageWindow.rootViewController).personalization;
                NSString *personalizedText = [self personalizeText:button.text withPersonalization:personalizationProps freemarkerEnabled:campaign.freemarkerEnabled useLocalTimezone:campaign.useLocalTimezone];
                NSString *personalizedActionString = [self personalizeText:button.actionString withPersonalization:personalizationProps freemarkerEnabled:campaign.freemarkerEnabled useLocalTimezone:campaign.useLocalTimezone];
                SwrveMessageButtonDetails *messageButtonDetails = [[SwrveMessageButtonDetails alloc] initWith:button.name
                                                                                                   buttonText:personalizedText
                                                                                                   actionType:button.actionType
                                                                                                 actionString:personalizedActionString];
                [allButtons addObject:messageButtonDetails];
            }
        }
    }
    
    SwrveMessageDetails *messageDetails = [[SwrveMessageDetails alloc] initWith:subject campaignId:campaign.ID variantId:[message.messageID unsignedLongValue] messageName:message.name buttons:allButtons];
    
    return messageDetails;
}

- (void)dismissMessageWindow NS_EXTENSION_UNAVAILABLE_IOS("") {
    if (self.inAppMessageWindow == nil) {
        [SwrveLogger error:@"No message to dismiss.", nil];
        return;
    }
    [self setMessageMinDelayThrottle];
    NSDate *now = [self.analyticsSDK getNow];
    SwrveMessage *message = ((SwrveMessageViewController *) self.inAppMessageWindow.rootViewController).message;
    SwrveInAppCampaign *dismissedCampaign = (SwrveInAppCampaign *) message.campaign;
    [dismissedCampaign messageDismissed:now];
    
    NSString *action = self.inAppMessageAction;
    NSString *nonProcessedAction = nil;
    NSString *actionTypeString = @"dismiss";
    switch (self.inAppMessageActionType) {
        case kSwrveActionPageLink:
            break;
        case kSwrveActionDismiss: {
            id <SwrveInAppMessageDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppMessageDelegate;
            if (delegate != nil && [delegate respondsToSelector:@selector(onAction:messageDetails:selectedButton:)]) {
                SwrveMessageDetails *md = [self messageDetails:message];
                SwrveMessageButtonDetails *selectedButton = nil;
                if (self.inAppButtonPressedName) { // In App Story with last page progression of dismiss won't have a selected button, therefore no pressed name
                    selectedButton = [[SwrveMessageButtonDetails alloc] initWith:self.inAppButtonPressedName
                                                                      buttonText:self.inAppButtonPressedText
                                                                      actionType:self.inAppMessageActionType
                                                                    actionString:self.inAppMessageAction];
                }
                [delegate onAction:SwrveMessageActionDismiss messageDetails:md selectedButton:selectedButton];
            }
        }
            break;
        case kSwrveActionInstall: {
            nonProcessedAction = action;
            actionTypeString = @"install";
        }
            break;
        case kSwrveActionCustom: {
            actionTypeString = @"deeplink";
            // if this callback is implemented we still process deeplinks internally.
            // Customer can override this by implementing SwrveDeeplinkDelegate.
            nonProcessedAction = action;
            
            id <SwrveInAppMessageDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppMessageDelegate;
            if (delegate != nil && [delegate respondsToSelector:@selector(onAction:messageDetails:selectedButton:)]) {
                SwrveMessageDetails *md = [self messageDetails:message];
                SwrveMessageButtonDetails *selectedButton = [[SwrveMessageButtonDetails alloc]initWith:self.inAppButtonPressedName
                                                                                            buttonText:self.inAppButtonPressedText
                                                                                            actionType:self.inAppMessageActionType
                                                                                          actionString:self.inAppMessageAction];
                [delegate onAction:SwrveMessageActionCustom messageDetails:md selectedButton:selectedButton];
            }
        }
            break;
        case kSwrveActionClipboard: {
            actionTypeString = @"clipboard";
            
#if TARGET_OS_IOS /** exclude tvOS **/
            if (action != nil) {
                UIPasteboard *pb = [UIPasteboard generalPasteboard];
                [pb setString:action];
            }
#endif /*TARGET_OS_IOS*/
            
            id <SwrveInAppMessageDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppMessageDelegate;
            if (delegate != nil && [delegate respondsToSelector:@selector(onAction:messageDetails:selectedButton:)]) {
                SwrveMessageDetails *md = [self messageDetails:message];
                SwrveMessageButtonDetails *selectedButton = [[SwrveMessageButtonDetails alloc]initWith:self.inAppButtonPressedName
                                                                                            buttonText:self.inAppButtonPressedText
                                                                                            actionType:self.inAppMessageActionType
                                                                                          actionString:self.inAppMessageAction];
                [delegate onAction:SwrveMessageActionClipboard messageDetails:md selectedButton:selectedButton];
            }
        }
            break;
        case kSwrveActionCapability: {
            actionTypeString = @"request_capability";
            // action is the capability type eg @"swrve.camera" @"swrve.photo" etc.
            // special case for "swrve.push", we do that internally and not through a client delegate
            if ([action isEqualToString:@"swrve.push"]) {
#if TARGET_OS_IOS
                if (self.pushEnabled) {
                    [self.analyticsSDK.push registerForPushNotifications:NO providesAppNotificationSettings:self.analyticsSDK.config.providesAppNotificationSettings];
                } else {
                    [SwrveLogger error:@"Push is not enabled"];
                }
#endif //TARGET_OS_IOS
            } else {
                id <SwrveInAppCapabilitiesDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppCapabilitiesDelegate;
                if (delegate != nil && [delegate respondsToSelector:@selector(requestCapability:completionHandler:)]) {
                    [delegate requestCapability:action completionHandler:^(BOOL success) {
                        //do nothing for now
                        NSString *status = (success) ? @"success" : @"failure";
                        [SwrveLogger debug:@"Callback received for requestCapability delegate: %@ status: %@", action, status];
                    }];
                }
            }
        }
            break;
        case kSwrveActionOpenSettings: {
#if TARGET_OS_IOS
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[SwrveCommon sharedUIApplication] openURL:url options:@{} completionHandler:nil];
#endif //TARGET_OS_IOS
        }
        case kSwrveActionOpenNotificationSettings: {
#if TARGET_OS_IOS
            if (@available(iOS 15.4, *)) {
                actionTypeString = @"open_notification_settings";
                NSURL *url = [NSURL URLWithString:UIApplicationOpenNotificationSettingsURLString];
                [[SwrveCommon sharedUIApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                actionTypeString = @"open_app_settings";
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[SwrveCommon sharedUIApplication] openURL:url options:@{} completionHandler:nil];
            }
#endif //TARGET_OS_IOS
        }
            break;
        case kSwrveActionStartGeo: {
#if TARGET_OS_IOS
            [self startSwrveGeoSDK];
#endif //TARGET_OS_IOS
        }
            break;
    }
    
    // QA logging
    [SwrveQA campaignButtonClicked:[NSNumber numberWithUnsignedLong:dismissedCampaign.ID]
                         variantId:message.messageID
                        buttonName:self.inAppButtonPressedName ? self.inAppButtonPressedName : @"" // inAppButtonPressedName can be nil if IAM is programmatically dismissed
                        actionType:actionTypeString
                       actionValue:action
    ];
    
    if (nonProcessedAction != nil) {
        NSURL *url = [NSURL URLWithString:nonProcessedAction];
        if (url != nil) {
            [SwrveLogger debug:@"Action - %@ - handled.  Sending to application as URL", nonProcessedAction];
            id <SwrveDeeplinkDelegate> del = self.analyticsSDK.config.deeplinkDelegate;
            if (del != nil && [del respondsToSelector:@selector(handleDeeplink:)]) {
                [del handleDeeplink:url];
                [SwrveLogger debug:@"Passing url to deeplink delegate for processing [%@]", url];
            } else {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                    [SwrveLogger debug:@"Opening url [%@] successfully: %@", url, success ? @"YES" : @"NO"];
                }];
            }
        } else {
            [SwrveLogger error:@"Action - %@ -  not handled. Override the customButtonCallback to customize message actions", nonProcessedAction];
        }
    }
    
    self.inAppMessageWindow.hidden = YES;
    self.inAppMessageWindow = nil;
    self.inAppMessageAction = nil;
    self.inAppButtonPressedName = nil;
    self.inAppButtonPressedText = nil;
    
    if ([SwrveLocalStorage trackingState] != STOPPED) {
        [self handleNextIAM:self.iamQueue];
    }
}

- (void)beginShowMessageAnimation:(SwrveMessageViewController *)viewController {
    viewController.view.alpha = 0.0f;
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.inAppMessageWindow.rootViewController.view.alpha = 1.0f;
    }
                     completion:nil];
}

- (BOOL)eventRaised:(NSDictionary *)event {
    
    BOOL campaignShown = NO;
    if (analyticsSDK == nil) {
        return campaignShown;
    }
    
    NSString *eventName = [self eventName:event];
    NSDictionary *payload = [event objectForKey:@"payload"];
    
    [self registerForPushNotificationsWithEvent:eventName];
    
    // Find a message that should be displayed
    SwrveBaseMessage *message = [self baseMessageForEvent:eventName withPayload:payload];
    
    if (message != nil && [message isKindOfClass:[SwrveMessage class]]) { // If the returned message is of type SwrveMessage then show IAM
        SwrveMessage *messageToBeDisplayed = (SwrveMessage *) message;
                
        // Check if the campaign is a control LAST so that other conditional checks are applied to control campaigns
        if (messageToBeDisplayed.control) {
            [SwrveLogger warning:@"This message is a control message and will not be displayed.", nil];
            [self baseMessageWasHandledOrShownToUser:message embedded:@"false"];
            return campaignShown;
        }
        
        NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:payload];
        dispatch_block_t showMessageBlock = ^{
            [self showMessage:messageToBeDisplayed withPersonalization:personalizationProperties];
        };
        if ([NSThread isMainThread]) {
            showMessageBlock();
        } else {
            // Run in the main thread as we have been called from other thread
            dispatch_async(dispatch_get_main_queue(), showMessageBlock);
        }
        campaignShown = YES;
    } else if (message != nil && [message isKindOfClass:[SwrveEmbeddedMessage class]]) { // If the returned message is of type SwrveEmbeddedMessage then trigger embedded callback
        SwrveEmbeddedMessage *messageToBeDisplayed = (SwrveEmbeddedMessage *) message;
        if (messageToBeDisplayed.control) {
            [SwrveLogger warning:@"This message is a control message and should not be displayed.", nil];
        }
        if (self.embeddedMessageConfig.embeddedCallback != nil) {
            NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:payload];
            self.embeddedMessageConfig.embeddedCallback(messageToBeDisplayed, personalizationProperties, messageToBeDisplayed.control);
            campaignShown = YES;
        }
    }
    
    return campaignShown;
}

- (void)registerForPushNotificationsWithEvent:(NSString *)eventName {
#if TARGET_OS_IOS
    if (self.pushEnabled) {
        if (self.pushNotificationPermissionEvents != nil && [self.pushNotificationPermissionEvents containsObject:eventName]) {
            // Ask for push notification permission (can display a dialog to the user)
            [analyticsSDK.push registerForPushNotifications:NO providesAppNotificationSettings:analyticsSDK.config.providesAppNotificationSettings];
        } else if (self.provisionalPushNotificationEvents != nil && [self.provisionalPushNotificationEvents containsObject:eventName]) {
            // Ask for provisioanl push notification permission
            [analyticsSDK.push registerForPushNotifications:YES providesAppNotificationSettings:analyticsSDK.config.providesAppNotificationSettings];
        }
    }
#endif //TARGET_OS_IOS
}

- (NSString *)orientationName {
    switch (orientation) {
        case SWRVE_ORIENTATION_LANDSCAPE:
            return @"landscape";
        case SWRVE_ORIENTATION_PORTRAIT:
            return @"portrait";
        default:
            return @"both";
    }
}

- (NSString *)campaignQueryString API_AVAILABLE(ios(12.0)) {
    const NSString *orientationName = [self orientationName];
    UIDevice *device = [UIDevice currentDevice];
    NSString *encodedDeviceName = [[device model] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *encodedSystemVersion = [[device systemVersion] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *systemName = [[device systemName] lowercaseString];
    NSString *deviceType = [SwrveUtils platformDeviceType];
    
    return [NSString stringWithFormat:@"version=%d&orientation=%@&language=%@&app_store=%@&device_width=%d&device_height=%d&os_version=%@&device_name=%@&os=%@&device_type=%@&embedded_campaign_version=%d&in_app_version=%d",
            CAMPAIGN_VERSION, orientationName, self.language, @"apple", self.device_width, self.device_height, encodedSystemVersion, encodedDeviceName, systemName, deviceType, EMBEDDED_CAMPAIGN_VERSION, IN_APP_CAMPAIGN_VERSION];
}

- (UIImage *)imageFromCache:(NSString *)sha {
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSURL *localImageFileUrl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, sha, nil]];
    return [UIImage imageWithData:[NSData dataWithContentsOfURL:localImageFileUrl]];
}

- (SwrveMessageCenterDetails *)personalizeMessageCenterDetails:(SwrveMessageCenterDetails *)rawMessageCenterDetails withPersonalization:(NSDictionary *)personalization freemarkerEnabled:(BOOL)freemarkerEnabled useLocalTimezone:(BOOL)useLocalTimezone {
    if (rawMessageCenterDetails == nil) return nil;

    NSString *subject = rawMessageCenterDetails.subject;
    if (subject != nil) {
        subject = [self personalizeText:subject withPersonalization:personalization freemarkerEnabled:freemarkerEnabled useLocalTimezone:useLocalTimezone];
    }

    NSString *description = rawMessageCenterDetails.description;
    if (description != nil) {
        description = [self personalizeText:description withPersonalization:personalization freemarkerEnabled:freemarkerEnabled useLocalTimezone:useLocalTimezone];
    }

    NSString *imageAccessibilityText = rawMessageCenterDetails.imageAccessibilityText;
    if (imageAccessibilityText != nil) {
        imageAccessibilityText = [self personalizeText:imageAccessibilityText withPersonalization:personalization freemarkerEnabled:freemarkerEnabled useLocalTimezone:useLocalTimezone];
    }

    NSString *imageUrl = rawMessageCenterDetails.imageUrl;
    if (imageUrl != nil) {
        imageUrl = [self personalizeText:imageUrl withPersonalization:personalization freemarkerEnabled:freemarkerEnabled useLocalTimezone:useLocalTimezone];
    }
    
    NSString *imageSha = rawMessageCenterDetails.imageSha; // imageSha is not personalized
    UIImage *image = [self loadMessageCenterAssetsFromCache:imageUrl imageSha:imageSha];
    
    return [[SwrveMessageCenterDetails alloc] initWithSubject:subject
                                              descriptionText:description
                                            accessibilityText:imageAccessibilityText
                                                     imageUrl:imageUrl
                                                     imageSha:imageSha
                                                        image:image];
}

- (UIImage *)loadMessageCenterAssetsFromCache:(NSString *)imageUrl imageSha:(NSString *)imageSha {
    UIImage *image = nil;
    if (imageUrl != nil) {
        NSData *data = [imageUrl dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        image = [self imageFromCache:[SwrveUtils sha1:data]];
    }
    if (image == nil && imageSha != nil) {
        // try load the cdn image asset, this is also used as a fallback, when the imageUrl above failed to download and wasn't in cache.
        image = [self imageFromCache:imageSha];
    }
    return image;
}

- (SwrveCampaign *)messageCenterCampaignWithID:(NSUInteger)campaignID andPersonalization:(NSDictionary *)personalization {
    NSArray *result = [self messageCenterCampaignsWithPersonalization:personalization andPredicate:^BOOL(SwrveCampaign *campaign) {
        return campaign.ID == campaignID;
    }];
    return [result count] == 1 ? [result objectAtIndex:0] : nil;
}

- (NSArray<SwrveCampaign *> *)messageCenterCampaignsWithPersonalization:(NSDictionary *)personalization andPredicate:(BOOL (^)(SwrveCampaign *))predicate {
    NSMutableArray *result = [NSMutableArray new];
    if (analyticsSDK == nil) {
        return result;
    }
    
    NSDate *now = [self.analyticsSDK getNow];
    for (SwrveCampaign *campaign in self.campaigns) {
        
        if (predicate != nil && !predicate(campaign)) {
            continue;
        }
        
        if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
            SwrveInAppCampaign *swrveInAppCampaign = (SwrveInAppCampaign *) campaign;
            SwrveMessage *message = swrveInAppCampaign.message;
            bool filterRedundantCampaign = [self filterRedundantCampaign:message];
            if (filterRedundantCampaign) {
                continue;
            } else if (![message canResolvePersonalization:personalization]) {
                continue; // Skip IAM campaign if personalization cannot be resolved
            } else {
                campaign.priority = message.priority;
                campaign.messageCenterDetails = [self personalizeMessageCenterDetails:message.messageCenterDetails withPersonalization:personalization freemarkerEnabled:swrveInAppCampaign.freemarkerEnabled useLocalTimezone:swrveInAppCampaign.useLocalTimezone];
            }
        } else if ([campaign isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            SwrveEmbeddedCampaign *swrveEmbeddedCampaign = (SwrveEmbeddedCampaign *) campaign;
            NSString *personalizedData = [self personalizeEmbeddedMessageData:swrveEmbeddedCampaign.message withPersonalization:personalization];
            if (!personalizedData) {
                continue; // Skip embedded campaign if personalization cannot be resolved
            }
            swrveEmbeddedCampaign.message.data = personalizedData; // originalData retained automatically
            campaign.priority = swrveEmbeddedCampaign.message.priority;
        }
        
        NSSet *assetsOnDisk = [assetsManager assetsOnDisk];
        if (campaign.messageCenter
            && campaign.state.status != SwrveCampaignStatusDeleted
            && [campaign isActiveAt:now withReasons:[NSMutableDictionary new]]
            && [campaign assetsReady:assetsOnDisk withPersonalization:personalization]) {
            [result addObject:campaign];
        }
    }
    return result;
}

- (NSArray<SwrveCampaign *> *)messageCenterCampaigns {
    return [self messageCenterCampaignsWithPersonalization:[self includeRealTimeUserProperties:nil] andPredicate:nil];
}

#if TARGET_OS_IOS /** exclude tvOS **/

- (NSArray<SwrveCampaign *> *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)messageOrientation {
    return [self messageCenterCampaignsWithPersonalization:[self includeRealTimeUserProperties:nil] andPredicate:^BOOL(SwrveCampaign *campaign) {
        return [campaign supportsOrientation:messageOrientation];
    }];
}

- (NSArray<SwrveCampaign *> *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)messageOrientation withPersonalization:(NSDictionary *)personalization {
    NSDictionary *personalizationProperties = [self includeRealTimeUserProperties:personalization];
    return [self messageCenterCampaignsWithPersonalization:personalizationProperties andPredicate:^BOOL(SwrveCampaign *campaign) {
        BOOL supportsOrientation = [campaign supportsOrientation:messageOrientation];
        if (!supportsOrientation) {
            return NO;
        }
        return YES;
    }];
}

- (NSArray <SwrveInAppCampaign *>*)inAppMessageCenterCampaignsWith:(UIInterfaceOrientation)messageOrientation withPersonalization:(NSDictionary *)personalization {
    NSDictionary *personalizationProperties = [self includeRealTimeUserProperties:personalization];
    NSArray *inAppCampaigns = [self messageCenterCampaignsWithPersonalization:personalizationProperties andPredicate:^BOOL(SwrveCampaign *campaign) {
        return [campaign isKindOfClass:[SwrveInAppCampaign class]] && [campaign supportsOrientation:messageOrientation];
    }];
    return inAppCampaigns;
}

#endif

- (NSArray <SwrveEmbeddedMessage *>*)embeddedMessageCenterCampaigns:(NSDictionary *)personalization {
    NSDictionary *personalizationProperties = [self includeRealTimeUserProperties:personalization];
    NSArray *embeddedCampaigns = [self messageCenterCampaignsWithPersonalization:personalizationProperties andPredicate:^BOOL(SwrveCampaign *campaign) {
        return [campaign isKindOfClass:[SwrveEmbeddedCampaign class]];
    }];
    NSMutableArray *embeddedMessages = [NSMutableArray new];
    for (SwrveEmbeddedCampaign *campaign in embeddedCampaigns) {
        [embeddedMessages addObject:campaign.message];
    }
    return embeddedMessages;
}

- (NSArray<SwrveCampaign *> *)messageCenterCampaignsWithPersonalization:(NSDictionary *)personalization {
    NSDictionary *personalizationProperties = [self includeRealTimeUserProperties:personalization];
    return [self messageCenterCampaignsWithPersonalization:personalizationProperties andPredicate:nil];
}

- (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign {
    return [self showMessageCenterCampaign:campaign withPersonalization:nil];
}

- (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign withPersonalization:(NSDictionary *)personalization {
    if (analyticsSDK == nil) {
        return NO;
    }
    
    NSDictionary *personalizationProperties = [self includeRealTimeUserProperties:personalization];
    
    if (![campaign isActiveAt:[self.analyticsSDK getNow] withReasons:[NSMutableDictionary new]]) {
        return NO;
    }
    
    if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
        SwrveInAppCampaign *swrveCampaign = (SwrveInAppCampaign *) campaign;
        SwrveMessage *message = swrveCampaign.message;

        if (![self canDisplaySwrveMessage:message withPersonalization:personalizationProperties]) {
            return NO;
        }
        
        // Show the message if it exists
        if (message != nil) {
            dispatch_block_t showMessageBlock = ^{
                [self showMessage:message withPersonalization:personalizationProperties];
            };
            if ([NSThread isMainThread]) {
                showMessageBlock();
            } else {
                // Run in the main thread as we have been called from other thread
                dispatch_async(dispatch_get_main_queue(), showMessageBlock);
            }
        }
        
        return YES;
    } else if ([campaign isKindOfClass:[SwrveEmbeddedCampaign class]]) {
        SwrveEmbeddedMessage *message = ((SwrveEmbeddedCampaign *) campaign).message;
        if (message != nil && self.embeddedMessageConfig.embeddedCallback != nil) {
            self.embeddedMessageConfig.embeddedCallback(message, personalizationProperties, message.control);
        }
        
        return YES;
    }
    
    return NO;
}

- (void)removeMessageCenterCampaign:(SwrveCampaign *)campaign {
    if (analyticsSDK == nil) {
        return;
    }
    if (campaign != nil && campaign.messageCenter) {
        [campaign.state setStatus:SwrveCampaignStatusDeleted];
        [self saveCampaignsState];
    }
}

- (void)removeMessageCenterCampaignWithID:(NSUInteger)campaignID {
    if (analyticsSDK == nil) {
        return;
    }
    for (SwrveCampaign *campaign in self.campaigns) {
        if(campaign.ID == campaignID) {
            [self removeMessageCenterCampaign:campaign];
            break;
        }
    }
}

- (void)markMessageCenterCampaignAsSeen:(SwrveCampaign *)campaign {
    if (analyticsSDK == nil) {
        return;
    }
    if (campaign != nil && campaign.messageCenter) {
        [campaign.state setStatus:SwrveCampaignStatusSeen];
        [self saveCampaignsState];
    }
}

- (void)markMessageCenterCampaignAsSeenWithID:(NSUInteger)campaignID {
    if (analyticsSDK == nil) {
        return;
    }
    for (SwrveCampaign *campaign in self.campaigns) {
        if(campaign.ID == campaignID) {
            [self markMessageCenterCampaignAsSeen:campaign];
            break;
        }
    }
}

- (NSDictionary *)processRealTimeUserProperties:(NSDictionary *)realTimeUserProperties {
    
    if (realTimeUserProperties == nil) {
        return nil;
    }
    
    NSArray *rtupsKeys = [realTimeUserProperties allKeys];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in rtupsKeys) {
        NSString *modifiedKey = [NSString stringWithFormat:@"user.%@", key];
        [result setValue:realTimeUserProperties[key] forKey:modifiedKey];
        NSString *recipientKey = [NSString stringWithFormat:@"Recipient.%@", key];
        [result setValue:realTimeUserProperties[key] forKey:recipientKey];
    }
    
    return result;
}

- (NSDictionary *)retrievePersonalizationProperties:(NSDictionary *)payload {
    NSDictionary *resultProperties = nil;
    NSDictionary *realTimeUserProperties = [self processRealTimeUserProperties:[[self analyticsSDK] internalRealTimeUserProperties]];
    
    if (self.personalizationCallback != nil) {
        NSDictionary *callbackPersonalization = self.personalizationCallback(payload);
        resultProperties = [SwrveUtils combineDictionary:realTimeUserProperties withDictionary:callbackPersonalization];
    } else {
        resultProperties = realTimeUserProperties;
    }
    
    return resultProperties;
}

- (NSDictionary *)includeRealTimeUserProperties:(NSDictionary *)personalization {
    NSDictionary *realTimeUserProperties = [self processRealTimeUserProperties:[[self analyticsSDK] internalRealTimeUserProperties]];
    return [SwrveUtils combineDictionary:realTimeUserProperties withDictionary:personalization];
}

- (void)startSwrveGeoSDK {
    Class geoSDK = NSClassFromString(@"SwrveGeoSDK");
    SEL selector = NSSelectorFromString(@"start");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([geoSDK respondsToSelector:selector]) {
        [geoSDK performSelector:selector];
    }
#pragma clang diagnostic pop
}

- (bool)shouldStartSwrveGeoSDK {
    bool shouldStart = false; // default to false as the SwrveGeoSDK might not be integrated
    Class geoSDK = NSClassFromString(@"SwrveGeoSDK");
    SEL selector = NSSelectorFromString(@"isStarted");
    if ([geoSDK respondsToSelector:selector]) {
        NSMethodSignature *methodSignature = [geoSDK methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setSelector:selector];
        [invocation setTarget:geoSDK];
        [invocation invoke];
        bool isStarted = false;
        [invocation getReturnValue:&isStarted];
        shouldStart = !isStarted; // if its started (true) then shouldStart must be false
    }
    return shouldStart;
}

- (BOOL) canDisplaySwrveMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization {
    
    if (![message canResolvePersonalization:personalization]) {
        return NO;
    }
    
    CGSize windowSize = [self windowSize];
    if (windowSize.width > windowSize.height) {
        if (![message supportsSwrveOrientation:SWRVE_ORIENTATION_LANDSCAPE]) {
            [SwrveLogger warning:@"This campaign does not support landscape orientation."];
            return NO;
        }
    } else {
        if (![message supportsSwrveOrientation:SWRVE_ORIENTATION_PORTRAIT]) {
            [SwrveLogger warning:@"This campaign does not support portrait orientation."];
            return NO;
        }
    }
    
    return YES;
}

- (CGSize)windowSize NS_EXTENSION_UNAVAILABLE_IOS("") {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13, *)) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = [[UIApplication sharedApplication] keyWindow];
#pragma clang diagnostic pop
    }
    CGSize screenSize = [keyWindow bounds].size;
    if (screenSize.width == 0.0 || screenSize.height == 0) {
        screenSize = [UIScreen mainScreen].bounds.size;
    }
    return screenSize;
}

@end
