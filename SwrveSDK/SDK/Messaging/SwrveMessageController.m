#import "SwrveMessageController.h"
#import "SwrveMessageController+Private.h"
#import "SwrveButton.h"
#import "SwrveInAppCampaign.h"
#import "SwrveConversationCampaign.h"

#import "Swrve+Private.h"

#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)

#import <SwrveSDKCommon/SwrveAssetsManager.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#import <SwrveSDKCommon/SwrveQA.h>
#import <SwrveSDKCommon/TextTemplating.h>

#if TARGET_OS_IOS /** exclude tvOS **/

#import <SwrveSDKCommon/SwrvePermissions.h>

#endif //TARGET_OS_IOS
#else
#import "SwrveLocalStorage.h"
#import "SwrveAssetsManager.h"
#import "SwrveUtils.h"
#import "SwrveQA.h"
#import "TextTemplating.h"
#if TARGET_OS_IOS /** exclude tvOS **/
#import "SwrvePermissions.h"
#endif //TARGET_OS_IOS
#endif

#import "SwrveCampaign+Private.h"
#import "SwrveMessagePage.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSArray *SUPPORTED_DEVICE_FILTERS;
static NSArray *SUPPORTED_STATIC_DEVICE_FILTERS;
static NSArray *ALL_SUPPORTED_DYNAMIC_DEVICE_FILTERS;

const static int DEFAULT_DELAY_FIRST_MESSAGE = 150;
const static int DEFAULT_MAX_SHOWS = 99999;
const static int DEFAULT_MIN_DELAY = 55;

#if TARGET_OS_IOS

@interface SwrvePush (SwrvePushInternalAccess)
- (void)registerForPushNotifications:(BOOL)provisional;
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
@property(nonatomic, retain) NSMutableDictionary *appStoreURLs;
@property(nonatomic, retain) NSMutableArray *notifications;
@property(nonatomic, retain) NSString *campaignsStateFilePath;
@property(nonatomic, retain) NSDate *initialisedTime; // SDK init time
@property(nonatomic, retain) NSDate *showMessagesAfterLaunch; // Only show messages after this time.
@property(nonatomic, retain) NSDate *showMessagesAfterDelay; // Only show messages after this time.
#if TARGET_OS_IOS
@property(nonatomic) bool pushEnabled; // Decide if push notification is enabled
@property(nonatomic, retain) NSSet *provisionalPushNotificationEvents; // Events that trigger the provisional push permission request
@property(nonatomic, retain) NSSet *pushNotificationEvents; // Events that trigger the push notification dialog
#endif //TARGET_OS_IOS
@property(nonatomic) bool autoShowMessagesEnabled;
@property(nonatomic, retain) UIWindow *inAppMessageWindow;
@property(nonatomic, retain) UIWindow *conversationWindow;
@property(nonatomic) SwrveActionType inAppMessageActionType;
@property(nonatomic, retain) NSString *inAppMessageAction;
@property(nonatomic, retain) NSString *inAppButtonPressedName;
@property(nonatomic) bool prefersConversationsStatusBarHidden;

// Current Device Properties
@property(nonatomic) int device_width;
@property(nonatomic) int device_height;
@property(nonatomic) SwrveInterfaceOrientation orientation;

// Only ever show this many messages. This number is decremented each time a message is shown.
@property(atomic) long messagesLeftToShow;
@property(atomic) NSTimeInterval minDelayBetweenMessage;

@property(nonatomic, retain) NSMutableArray *conversationsMessageQueue;

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
@synthesize appStoreURLs;
#if TARGET_OS_IOS
@synthesize pushEnabled;
@synthesize provisionalPushNotificationEvents;
@synthesize pushNotificationEvents;
#endif //TARGET_OS_IOS
@synthesize inAppMessageWindow;
@synthesize conversationWindow;
@synthesize inAppMessageActionType;
@synthesize inAppMessageAction;
@synthesize inAppButtonPressedName;
@synthesize device_width;
@synthesize device_height;
@synthesize orientation;
@synthesize autoShowMessagesEnabled;
@synthesize analyticsSDK;
@synthesize minDelayBetweenMessage;
@synthesize customButtonCallback;
@synthesize dismissButtonCallback;
@synthesize clipboardButtonCallback;
@synthesize personalizationCallback;
@synthesize swrveConversationItemViewController;
@synthesize prefersConversationsStatusBarHidden;
@synthesize conversationsMessageQueue;

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
    self.prefersConversationsStatusBarHidden = sdk.config.prefersConversationsStatusBarHidden;
    self.language = sdk.config.language;
    self.user = [sdk userID];
    self.apiKey = sdk.apiKey;
    self.server = sdk.config.contentServer;
    self.analyticsSDK = sdk;
#if TARGET_OS_IOS
    self.pushEnabled = sdk.config.pushEnabled;
    self.provisionalPushNotificationEvents = sdk.config.provisionalPushNotificationEvents;
    self.pushNotificationEvents = sdk.config.pushNotificationEvents;
#endif //TARGET_OS_IOS
    self.appStoreURLs = [NSMutableDictionary new];

    self.inAppMessageConfig = sdk.config.inAppMessageConfig;

    if (self.inAppMessageConfig.personalizationCallback != nil) {
        self.personalizationCallback = self.inAppMessageConfig.personalizationCallback;
    }

    self.embeddedMessageConfig = sdk.config.embeddedMessageConfig;

    // Link previously public properties from the new inAppMessage
    self.customButtonCallback = self.inAppMessageConfig.customButtonCallback;
    self.dismissButtonCallback = self.inAppMessageConfig.dismissButtonCallback;
    self.clipboardButtonCallback = self.inAppMessageConfig.clipboardButtonCallback;
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
    self.conversationsMessageQueue = [NSMutableArray new];

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
                SwrveCampaignState *state = [[SwrveCampaignState alloc] initWithJSON:dicState];
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
                SwrveCampaignState *state = [[SwrveCampaignState alloc] initWithJSON:dicState];
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
            [self updateCampaigns:jsonDict withLoadingPreviousCampaignState:isLoadingPreviousCampaignState];
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

- (NSString *)supportsDeviceFilters:(NSArray *)filters {
    // Update device filters to the current status
    NSArray *currentFilters = [self currentlySupportedDeviceFilters];

    // Used to check the current enabled filters
    if (filters != nil) {
        for (NSString *filter in filters) {
            NSString *lowercaseFilter = [filter lowercaseString];
            if (![currentFilters containsObject:lowercaseFilter]) {
                return lowercaseFilter;
            }
        }
    }
    return nil;
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

- (void)updateCampaigns:(NSDictionary *)campaignDic withLoadingPreviousCampaignState:(BOOL)isLoadingPreviousCampaignState {

    if (campaignDic == nil) {
        [SwrveLogger error:@"Error parsing campaign JSON", nil];
        return;
    }

    if ([campaignDic count] == 0) {
        [SwrveLogger debug:@"Campaign JSON empty, no campaigns downloaded", nil];
        self.campaigns = [NSArray new];
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

    // Game Data
    NSDictionary *gameData = [campaignDic objectForKey:@"game_data"];
    if (gameData) {
        for (NSString *game  in gameData) {
            NSString *url = [(NSDictionary *) [gameData objectForKey:game] objectForKey:@"app_store_url"];
            [self.appStoreURLs setValue:url forKey:game];
            [SwrveLogger debug:@"App Store link %@: %@", game, url];
        }
    }

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
        BOOL conversationCampaign = ([dict objectForKey:@"conversation"] != nil);
        SwrveCampaign *campaign = nil;
        if (conversationCampaign) {
            // Check device filters (permission requests, platform)
            NSArray *filters = [dict objectForKey:@"filters"];
            BOOL passesAllFilters = TRUE;
            NSString *lastCheckedFilter = nil;
            if (filters != nil) {
                for (NSString *filter in filters) {
                    lastCheckedFilter = filter;
                    if (![self canSupportDeviceFilter:filter]) {
                        passesAllFilters = NO;
                        break;
                    }
                }
            }

            if (passesAllFilters) {
                // Conversation version check
                NSNumber *conversationVersion = [dict objectForKey:@"conversation_version"];
                if (conversationVersion == nil || [conversationVersion integerValue] <= CONVERSATION_VERSION) {
                    campaign = [[SwrveConversationCampaign alloc] initAtTime:self.initialisedTime fromDictionary:dict withAssetsQueue:assetsQueue forController:self];
                } else {
                    [SwrveLogger warning:@"Conversation version %@ cannot be loaded with this SDK.", conversationVersion];
                }
            } else {
                [SwrveLogger warning:@"Not all requirements were satisfied for this campaign: %@", lastCheckedFilter];
            }
        } else if ([dict objectForKey:@"message"] != nil) {
            campaign = [[SwrveInAppCampaign alloc] initAtTime:self.initialisedTime fromDictionary:dict withAssetsQueue:assetsQueue forController:self withPersonalization:personalizationProperties];
        } else if ([dict objectForKey:@"embedded_message"] != nil) {
            campaign = [[SwrveEmbeddedCampaign alloc] initAtTime:self.initialisedTime fromDictionary:dict forController:self];
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

    // Obtain assets we don't have yet
    [assetsManager downloadAssets:assetsQueue withCompletionHandler:^{
        [self autoShowMessages];
    }];

    self.campaigns = [result copy];
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
        // do nothing, we're just refreshing
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
        } else if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
            SwrveConversationCampaign *swrveConversationCampaign = (SwrveConversationCampaign *) campaign;
            [swrveConversationCampaign addAssetsToQueue:assetsQ];
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

        } else if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
            SwrveConversationCampaign *specificCampaign = (SwrveConversationCampaign *) campaign;
            if ([specificCampaign hasConversationForEvent:AUTOSHOW_AT_SESSION_START_TRIGGER withPayload:nil]) {
                @synchronized (self) {
                    if ([self autoShowMessagesEnabled]) {
                        NSDictionary *event = @{@"type": @"event", @"name": AUTOSHOW_AT_SESSION_START_TRIGGER};
                        if ([self eventRaised:event]) {
                            // If a conversation was shown we want to disable autoshow
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
    if (analyticsSDK == nil) {
        return nil;
    }

    NSDate *now = [self.analyticsSDK getNow];
    SwrveBaseMessage *result = nil;
    SwrveCampaign *campaign = nil;
    BOOL isQALogging = [[SwrveQA sharedInstance] isQALogging];

    NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:payload];

    if (self.campaigns != nil) {

        if (![self checkGlobalRulesForCampaignType:SWRVE_CAMPAIGN_IAM withEventName:eventName withEventPayload:payload withDate:now]
                && ![self checkGlobalRulesForCampaignType:SWRVE_CAMPAIGN_EMBEDDED withEventName:eventName withEventPayload:payload withDate:now]) {
            return nil;
        }

        NSMutableArray<SwrveQACampaignInfo *> *qaCampaignInfoArray = nil;
        NSMutableDictionary *campaignReasons = nil;
        NSMutableDictionary *campaignMessages = nil;

        if (isQALogging) {
            qaCampaignInfoArray = [NSMutableArray new];
            campaignReasons = [NSMutableDictionary new];
            campaignMessages = [NSMutableDictionary new];
        }


        NSMutableArray *availableMessages = [NSMutableArray new];
        // Select messages with higher priority that have the current orientation
        NSNumber *minPriority = [NSNumber numberWithInteger:INT_MAX];
        NSMutableArray *candidateMessages = [NSMutableArray new];
        for (SwrveCampaign *baseCampaignIt in self.campaigns) {
            SwrveBaseMessage *nextMessage;
            if ([baseCampaignIt isKindOfClass:[SwrveInAppCampaign class]]) {
                SwrveInAppCampaign *campaignIt = (SwrveInAppCampaign *) baseCampaignIt;
                NSSet *assetsOnDisk = [assetsManager assetsOnDisk];
                nextMessage = [campaignIt messageForEvent:eventName withPayload:payload withAssets:assetsOnDisk withPersonalization:personalizationProperties atTime:now withReasons:campaignReasons];
            } else if ([baseCampaignIt isKindOfClass:[SwrveEmbeddedCampaign class]]) {
                SwrveEmbeddedCampaign *campaignIt = (SwrveEmbeddedCampaign *) baseCampaignIt;
                nextMessage = [campaignIt messageForEvent:eventName withPayload:payload atTime:now withReasons:campaignReasons];
            }

            if (nextMessage != nil) {
                // Add to list of returned messages
                [availableMessages addObject:nextMessage];
                // Check if it is a candidate to be shown
                long nextMessagePriorityLong = [nextMessage.priority longValue];
                long minPriorityLong = [minPriority longValue];
                if (nextMessagePriorityLong <= minPriorityLong) {
                    if (nextMessagePriorityLong < minPriorityLong) {
                        // If it is lower than any of the previous ones
                        // remove those from being candidates
                        [candidateMessages removeAllObjects];
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
            // Filter out campaign if it has buttons requesting capabilities and canRequestCapability delegate returns false + qa log
            id <SwrveInAppCapabilitiesDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppCapabilitiesDelegate;
            bool filterMessage = [self filterMessage:(SwrveMessage *) result withCapabilityDelegate:delegate];
            result = (filterMessage) ? nil : result;
            if (isQALogging && filterMessage) {
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
    }

    if (result == nil) {
        [SwrveLogger debug:@"Not showing message: no candidate base message for %@", eventName];
    }
    return result;
}

- (BOOL)filterMessage:(SwrveMessage *)message withCapabilityDelegate:(id <SwrveInAppCapabilitiesDelegate>)delegate {
    NSDictionary *capabilites = [self capabilities:message withCapabilityDelegate:delegate];
    return [capabilites count] != 0 && ![self checkCanRequestAllCapabilties:capabilites];
}

- (BOOL)checkCanRequestAllCapabilties:(NSDictionary *)capabilities {
    // if any can't be requested we will filter message.
    for (NSString *key in [capabilities allKeys]) {
        if ([capabilities objectForKey:key] == [NSNumber numberWithBool:false]) {
            return false;
        }
    }
    return true;
}

- (NSMutableDictionary *)capabilities:(SwrveMessage *)swrveMessage withCapabilityDelegate:(id <SwrveInAppCapabilitiesDelegate>)delegate {
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (SwrveMessageFormat *format in swrveMessage.formats) {
        NSDictionary *pages = [format pages];
        for (id key in pages) {
            SwrveMessagePage *page = [pages objectForKey:key];
            for (SwrveButton *button in page.buttons) {
                if (button.actionType == kSwrveActionCapability && [button.actionString isEqualToString:@"swrve.push"]) {
                    bool requestable = false;
#if TARGET_OS_IOS
                    if (self.pushEnabled) {
                        requestable = ![SwrvePermissions didWeAskForPushPermissionsAlready];
                    } else {
                        [SwrveLogger error:@"Push is not enabled"];
                    }
#endif
                    [result setObject:[NSNumber numberWithBool:requestable] forKey:button.actionString];
                } else if (button.actionType == kSwrveActionCapability && button.actionString != nil) {
                    bool requestable = false;
                    if (delegate != nil && [delegate respondsToSelector:@selector(canRequestCapability:)]) {
                        requestable = [delegate canRequestCapability:button.actionString];
                    }
                    [result setObject:[NSNumber numberWithBool:requestable] forKey:button.actionString];
                }
            }
        }
    }
    return result;
}

- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)event {
    // By default does a simple by name look up.
    return [self baseMessageForEvent:event withPayload:nil];
}

- (SwrveConversation *)conversationForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload {

    if (analyticsSDK == nil) {
        return nil;
    }

    if ([SwrveUtils supportsConversations] == NO) {
        return nil;
    }

    NSDate *now = [self.analyticsSDK getNow];
    SwrveConversation *result = nil;
    SwrveConversationCampaign *campaign = nil;
    BOOL isQALogging = [[SwrveQA sharedInstance] isQALogging];

    if (self.campaigns != nil) {
        if (![self checkGlobalRulesForCampaignType:SWRVE_CAMPAIGN_CONVERSATION withEventName:eventName withEventPayload:payload withDate:now]) {
            return nil;
        }

        NSMutableArray<SwrveQACampaignInfo *> *qaCampaignInfoArray = nil;
        NSMutableDictionary *campaignReasons = nil;
        NSMutableDictionary *campaignMessages = nil;

        if (isQALogging) {
            qaCampaignInfoArray = [NSMutableArray new];
            campaignReasons = [NSMutableDictionary new];
            campaignMessages = [NSMutableDictionary new];
        }

        NSMutableArray *availableConversations = [NSMutableArray new];
        // Select conversations with higher priority
        NSNumber *minPriority = [NSNumber numberWithInteger:INT_MAX];
        NSMutableArray *candidateConversations = [NSMutableArray new];
        for (SwrveCampaign *baseCampaignIt in self.campaigns) {
            if ([baseCampaignIt isKindOfClass:[SwrveConversationCampaign class]]) {
                SwrveConversationCampaign *campaignIt = (SwrveConversationCampaign *) baseCampaignIt;
                NSSet *assetsOnDisk = [assetsManager assetsOnDisk];
                SwrveConversation *nextConversation = [campaignIt conversationForEvent:eventName withPayload:payload withAssets:assetsOnDisk atTime:now withReasons:campaignReasons];
                if (nextConversation != nil) {
                    [availableConversations addObject:nextConversation];
                    // Check if it is a candidate to be shown
                    long nextMessagePriorityLong = [nextConversation.priority longValue];
                    long minPriorityLong = [minPriority longValue];
                    if (nextMessagePriorityLong <= minPriorityLong) {
                        if (nextMessagePriorityLong < minPriorityLong) {
                            // If it is lower than any of the previous ones
                            // remove those from being candidates
                            [candidateConversations removeAllObjects];
                        }
                        minPriority = nextConversation.priority;
                        [candidateConversations addObject:nextConversation];
                    }
                } else {
                    // If we are a QA user and it's an invalid campaign we do save it as part of this loop.
                    if (isQALogging && [campaignIt conversation] != nil) {
                        SwrveConversation *conversations = [campaignIt conversation];
                        NSString *reason = [campaignReasons objectForKey:[NSString stringWithFormat:@"%ld", (long) [campaignIt ID]]];
                        [qaCampaignInfoArray addObject:[[SwrveQACampaignInfo alloc] initWithCampaignID:campaignIt.ID variantID:[conversations.conversationID unsignedLongValue] type:SWRVE_CAMPAIGN_CONVERSATION displayed:NO reason:reason]];
                    }
                }

            }
        }

        NSArray *shuffledCandidates = [SwrveMessageController shuffled:candidateConversations];
        if ([shuffledCandidates count] > 0) {
            result = [shuffledCandidates objectAtIndex:0];
            campaign = result.campaign;
        }

        if (isQALogging && campaign != nil && result != nil) {
            // A message was chosen, set the reason for the others
            for (SwrveConversation *otherConversation in availableConversations) {
                if (result != otherConversation) {
                    SwrveConversationCampaign *c = otherConversation.campaign;
                    if (c != nil) {
                        NSString *reason = [NSString stringWithFormat:@"Campaign %ld was selected for display ahead of this campaign", (long) campaign.ID];
                        SwrveQACampaignInfo *campaignInfo = [[SwrveQACampaignInfo alloc] initWithCampaignID:c.ID variantID:[otherConversation.conversationID unsignedLongValue] type:SWRVE_CAMPAIGN_CONVERSATION displayed:NO reason:reason];
                        [qaCampaignInfoArray addObject:campaignInfo];
                    }
                }
            }
            // Add the chosen conversation as well into qaCampaignInfoArray.
            [qaCampaignInfoArray addObject:[[SwrveQACampaignInfo alloc] initWithCampaignID:campaign.ID variantID:[result.conversationID unsignedLongValue] type:SWRVE_CAMPAIGN_CONVERSATION displayed:YES reason:@""]];
        }
        [SwrveQA conversationCampaignTriggered:eventName eventPayload:payload displayed:(result != nil) campaignInfoDict:qaCampaignInfoArray];
    }

    if (result == nil) {
        [SwrveLogger debug:@"Not showing conversation: no candidate conversations for %@", eventName];
    }
    return result;
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
    [self baseMessageWasShownToUser:message embedded:@"false"];
}

- (void)embeddedMessageWasShownToUser:(SwrveEmbeddedMessage *)message {
    [self baseMessageWasShownToUser:message embedded:@"true"];
}

- (void)baseMessageWasShownToUser:(SwrveBaseMessage *)message embedded:(NSString *)embedded {
    // The message was shown. Take the current time so that we can throttle messages from being shown too quickly.
    [self setMessageMinDelayThrottle];
    [self setMessagesLeftToShow:self.messagesLeftToShow - 1];

    SwrveCampaign *campaign = message.campaign;
    if (campaign != nil) {
        NSDate *now = [self.analyticsSDK getNow];
        [campaign wasShownToUserAt:now];
    }
    [self saveCampaignsState];

    NSString *viewEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%d.impression", [message.messageID intValue]];
    NSDictionary *payload = @{@"embedded": embedded};
    [SwrveLogger debug:@"Queuing message impression event: %@", viewEvent];
    [self.analyticsSDK eventInternal:viewEvent payload:payload triggerCallback:false];
}

- (void)conversationWasShownToUser:(SwrveConversation *)conversation {
    // The message was shown. Take the current time so that we can throttle messages from being shown too quickly.
    [self setMessageMinDelayThrottle];
    [self setMessagesLeftToShow:self.messagesLeftToShow - 1];

    SwrveConversationCampaign *c = conversation.campaign;
    if (c != nil) {
        NSDate *now = [self.analyticsSDK getNow];
        [c conversationWasShownToUser:conversation at:now];
    }
    [self saveCampaignsState];
}

- (void)queueMessageClickEvent:(SwrveButton *)button page:(SwrveMessagePage *)page {
    if (button.actionType != kSwrveActionDismiss) {
        NSString *clickEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%ld.click", button.messageId];
        [SwrveLogger debug:@"Sending click event: %@", clickEvent];
        NSMutableDictionary *payload = [NSMutableDictionary new];
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
        NSError *error;
        NSString *resolvedMessageData = nil;

        if (message.type == kSwrveEmbeddedDataTypeJson) {
            resolvedMessageData = [TextTemplating templatedTextFromJSONString:message.data withProperties:personalizationProperties andError:&error];
        } else {
            resolvedMessageData = [TextTemplating templatedTextFromString:message.data withProperties:personalizationProperties andError:&error];
        }

        if (error != nil || resolvedMessageData == nil) {
            SwrveEmbeddedCampaign *campaign = (SwrveEmbeddedCampaign *) message.campaign;
            [SwrveLogger debug:@"For campaign id: %ld. Could not resolve personalization: %@", campaign.ID, message.data];
            [SwrveQA embeddedPersonalizationFailed:[NSNumber numberWithUnsignedInteger:message.campaign.ID] variantId:message.messageID unresolvedData:message.data reason:@"Failed to resolve personalization"];
            return nil;
        } else {
            return resolvedMessageData;
        }
    }

    return nil;
}

- (NSString *)personalizeText:(NSString *)text withPersonalization:(NSDictionary *)personalizationProperties {
    if (text != nil) {
        NSError *error;
        NSString *resolvedText = [TextTemplating templatedTextFromString:text withProperties:personalizationProperties andError:&error];
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

- (void)showMessage:(SwrveMessage *)message {
    [self showMessage:message queue:false withPersonalization:nil];
}

- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization {
    [self showMessage:message queue:false withPersonalization:personalization];
}

- (void)showMessage:(SwrveMessage *)message queue:(bool)isQueued withPersonalization:(NSDictionary *)personalization {
    if (message == nil) {
        return;
    }
    @synchronized (self) {
        if (self.inAppMessageWindow == nil && self.conversationWindow == nil) {
            SwrveMessageViewController *messageViewController = [[SwrveMessageViewController alloc]
                    initWithMessageController:self
                                      message:message
                              personalization:personalization];
            [self showMessageWindow:messageViewController];
        } else if (isQueued && ![self.conversationsMessageQueue containsObject:message]) {
            [self.conversationsMessageQueue addObject:message];
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

- (void)showConversation:(SwrveConversation *)conversation queue:(bool)isQueued {
    @synchronized (self) {
        if (conversation && self.inAppMessageWindow == nil && self.conversationWindow == nil) {
            self.conversationWindow = [self createUIWindow];
            self.conversationWindow.frame = [[UIScreen mainScreen] bounds];
            self.conversationWindow.backgroundColor = [UIColor clearColor]; // Define transparent color.
            self.swrveConversationItemViewController = [SwrveConversationItemViewController initConversation];
            bool success = [SwrveConversationItemViewController showConversation:conversation
                                                              withItemController:self.swrveConversationItemViewController
                                                                withEventHandler:(id <SwrveMessageEventHandler>) self
                                                                        inWindow:self.conversationWindow
                                                             withStatusBarHidden:self.analyticsSDK.config.prefersConversationsStatusBarHidden];
            if (!success) {
                self.conversationWindow = nil;
            }
        } else if (isQueued && ![self.conversationsMessageQueue containsObject:conversation]) {
            [self.conversationsMessageQueue addObject:conversation];
        }
    }
}

- (void)cleanupConversationUI {
    if (self.swrveConversationItemViewController != nil) {
        [self.swrveConversationItemViewController dismiss];
    }
}

- (void)conversationClosed {
    if (self.conversationWindow != nil) {
        self.conversationWindow.hidden = YES;
        self.conversationWindow = nil;
    }
    self.swrveConversationItemViewController = nil;

    if ([SwrveLocalStorage trackingState] != STOPPED) {
        [self handleNextConversation:self.conversationsMessageQueue];
    }
}

- (void)handleNextConversation:(NSMutableArray *)queue {
    if ([queue count] > 0) {
        id messageOrConversation = [queue objectAtIndex:0];
        [messageOrConversation isKindOfClass:[SwrveConversation class]] ? [self showConversation:messageOrConversation queue:false] : [self showMessage:messageOrConversation queue:false withPersonalization:nil];
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
    self.inAppMessageWindow.rootViewController = messageViewController;
    self.inAppMessageWindow.windowLevel = UIWindowLevelAlert + 1;
    [self.inAppMessageWindow makeKeyAndVisible];
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
        case kSwrveActionDismiss:
            if (self.dismissButtonCallback != nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                self.dismissButtonCallback(dismissedCampaign.subject, inAppButtonPressedName, message.name);
#pragma clang diagnostic pop
            }
            actionTypeString = @"dismiss";
            break;
        case kSwrveActionInstall: {
            nonProcessedAction = action;
            actionTypeString = @"install";
        }
            break;
        case kSwrveActionCustom: {

            if (self.customButtonCallback != nil) {
                self.customButtonCallback(action, message.name);
            } else {
                nonProcessedAction = action;
            }
            actionTypeString = @"deeplink";
        }
            break;
        case kSwrveActionClipboard: {
#if TARGET_OS_IOS /** exclude tvOS **/
            if (action != nil) {
                UIPasteboard *pb = [UIPasteboard generalPasteboard];
                [pb setString:action];
            }
#endif /*TARGET_OS_IOS*/

            if (self.clipboardButtonCallback != nil) {
                self.clipboardButtonCallback(action);
            }

            actionTypeString = @"clipboard";
        }
        case kSwrveActionCapability: {
            actionTypeString = @"request_capability";
            // action is the capability type eg @"swrve.camera" @"swrve.photo" etc.
            // special case for "swrve.push", we do that internally and not through a client delegate
            if ([action isEqualToString:@"swrve.push"]) {
#if TARGET_OS_IOS
                if (self.pushEnabled) {
                    [self.analyticsSDK.push registerForPushNotifications:NO];
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
    }

    // QA logging
    [SwrveQA campaignButtonClicked:[NSNumber numberWithUnsignedLong:dismissedCampaign.ID] variantId:message.messageID buttonName:inAppButtonPressedName actionType:actionTypeString actionValue:action];

    if (nonProcessedAction != nil) {
        NSURL *url = [NSURL URLWithString:nonProcessedAction];
        if (url != nil) {
            if (@available(iOS 10.0, *)) {
                [SwrveLogger debug:@"Action - %@ - handled.  Sending to application as URL", nonProcessedAction];
                id <SwrveDeeplinkDelegate> del = self.analyticsSDK.config.deeplinkDelegate;
                if (del != nil && [del respondsToSelector:@selector(handleDeeplink:)]) {
                    [del handleDeeplink:url];
                    [SwrveLogger debug:@"Passing url to deeplink delegate for processing [%@]", url];
                } else {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                        [SwrveLogger debug:@"Opening url [%@] successfully: %d", url, success];
                    }];
                }
            } else {
                [SwrveLogger error:@"Action not handled, not supported (should not reach this code)", nil];
            }
        } else {
            [SwrveLogger error:@"Action - %@ -  not handled. Override the customButtonCallback to customize message actions", nonProcessedAction];
        }
    }

    self.inAppMessageWindow.hidden = YES;
    self.inAppMessageWindow = nil;
    self.inAppMessageAction = nil;
    self.inAppButtonPressedName = nil;

    if ([SwrveLocalStorage trackingState] != STOPPED) {
        [self handleNextConversation:self.conversationsMessageQueue];
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
    NSDictionary *personalizationProperties = [self retrievePersonalizationProperties:payload];

    // Find a message that should be displayed
    SwrveBaseMessage *message = [self baseMessageForEvent:eventName withPayload:payload];

    // Show if the returned message is of type SwrveMessage
    if (message != nil && [message isKindOfClass:[SwrveMessage class]]) {
        SwrveMessage *messageToBeDisplayed = (SwrveMessage *) message;

        if (![messageToBeDisplayed canResolvePersonalization:personalizationProperties]) {
            [SwrveLogger warning:@"Personalization options are not available for this message.", nil];
            return campaignShown;
        }

        NSSet *assets = [assetsManager assetsOnDisk];
        if (![messageToBeDisplayed assetsReady:assets withPersonalization:personalizationProperties]) {
            [SwrveLogger warning:@"Url Personalization could not be resolved for this message.", nil];
            return campaignShown;
        }

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
    }

    // Embedded callback if it is an embedded message
    if (message != nil && [message isKindOfClass:[SwrveEmbeddedMessage class]]) {
        SwrveEmbeddedMessage *messageToBeDisplayed = (SwrveEmbeddedMessage *) message;

        if (self.embeddedMessageConfig.embeddedMessageCallbackWithPersonalization != nil) {
            self.embeddedMessageConfig.embeddedMessageCallbackWithPersonalization(messageToBeDisplayed, personalizationProperties);
        } else if (self.embeddedMessageConfig.embeddedMessageCallback != nil) {
            self.embeddedMessageConfig.embeddedMessageCallback(messageToBeDisplayed);
        }

        campaignShown = YES;
    }

    // If message shown then return
    if (campaignShown) {
        [SwrveQA conversationCampaignTriggeredNoDisplay:eventName eventPayload:payload];
        return campaignShown;
    }

    if ([SwrveUtils supportsConversations] == NO) {
        [SwrveLogger error:@"Conversations are not supported on this platform.", nil];
        return campaignShown;
    }

    // Find a conversation that should be displayed
    SwrveConversation *conversation = [self conversationForEvent:eventName withPayload:payload];
    if (conversation != nil && campaignShown == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showConversation:conversation queue:false];
        });
    }

    return (conversation != nil);
}

- (void)registerForPushNotificationsWithEvent:(NSString *)eventName {
#if TARGET_OS_IOS
    if (self.pushEnabled) {
        if (self.pushNotificationEvents != nil && [self.pushNotificationEvents containsObject:eventName]) {
            // Ask for push notification permission (can display a dialog to the user)
            [analyticsSDK.push registerForPushNotifications:NO];
        } else if (self.provisionalPushNotificationEvents != nil && [self.provisionalPushNotificationEvents containsObject:eventName]) {
            // Ask for provisioanl push notification permission
            [analyticsSDK.push registerForPushNotifications:YES];
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

- (NSString *)campaignQueryString API_AVAILABLE(ios(7.0)) {
    const NSString *orientationName = [self orientationName];
    UIDevice *device = [UIDevice currentDevice];
    NSString *encodedDeviceName = [[device model] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *encodedSystemVersion = [[device systemVersion] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *systemName = [[device systemName] lowercaseString];
    NSString *deviceType = [SwrveUtils platformDeviceType];

    return [NSString stringWithFormat:@"version=%d&orientation=%@&language=%@&app_store=%@&device_width=%d&device_height=%d&os_version=%@&device_name=%@&conversation_version=%d&os=%@&device_type=%@&embedded_campaign_version=%d&in_app_version=%d",
                                      CAMPAIGN_VERSION, orientationName, self.language, @"apple", self.device_width, self.device_height, encodedSystemVersion, encodedDeviceName, CONVERSATION_VERSION, systemName, deviceType, EMBEDDED_CAMPAIGN_VERSION, IN_APP_CAMPAIGN_VERSION];
}

- (UIImage *)imageFromCache:(NSString *)sha {
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSURL *localImageFileUrl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, sha, nil]];
    return [UIImage imageWithData:[NSData dataWithContentsOfURL:localImageFileUrl]];
}

- (SwrveMessageCenterDetails *)personalizeMessageCenterDetails:(SwrveMessageCenterDetails *)rawMessageCenterDetails withPersonalization:(NSDictionary *)personalization {
    if (rawMessageCenterDetails == nil) return nil;

    NSString *subject = rawMessageCenterDetails.subject;
    if (subject != nil) {
        subject = [self personalizeText:subject withPersonalization:personalization];
    }

    NSString *description = rawMessageCenterDetails.description;
    if (description != nil) {
        description = [self personalizeText:description withPersonalization:personalization];
    }

    NSString *imageAccessibilityText = rawMessageCenterDetails.imageAccessibilityText;
    if (imageAccessibilityText != nil) {
        imageAccessibilityText = [self personalizeText:imageAccessibilityText withPersonalization:personalization];
    }

    NSString *imageUrl = rawMessageCenterDetails.imageUrl;
    if (imageUrl != nil) {
        imageUrl = [self personalizeText:imageUrl withPersonalization:personalization];
    }

    NSString *imageSha = rawMessageCenterDetails.imageSha; // imageSha is not personalized
    UIImage *image = [self loadMessageCenterAssetsFromCache:imageUrl imageSha:imageSha];

    return [[SwrveMessageCenterDetails alloc] initWith:subject
                                           description:description
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

- (NSArray *)messageCenterCampaignsWithPersonalization:(NSDictionary *)personalization andPredicate:(BOOL (^)(SwrveCampaign *))predicate {
    NSMutableArray *result = [NSMutableArray new];
    if (analyticsSDK == nil) {
        return result;
    }

    NSDate *now = [self.analyticsSDK getNow];
    for (SwrveCampaign *campaign in self.campaigns) {
        
        if (predicate != nil && !predicate(campaign)) {
            continue;
        }
        
#if TARGET_OS_TV /** filter conversations for TV**/
        if (![campaign isKindOfClass:[SwrveInAppCampaign class]] && ![campaign isKindOfClass:[SwrveEmbeddedCampaign class]]) continue;
#endif

        if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
            // Filter out campaign if it has buttons requesting capabilities and canRequestCapability delegate returns false;
            SwrveInAppCampaign *swrveInAppCampaign = (SwrveInAppCampaign *) campaign;
            SwrveMessage *message = swrveInAppCampaign.message;
            id <SwrveInAppCapabilitiesDelegate> delegate = self.analyticsSDK.config.inAppMessageConfig.inAppCapabilitiesDelegate;
            bool filterMessage = [self filterMessage:message withCapabilityDelegate:delegate];
            if (filterMessage) {
                continue;
            } else if (![message canResolvePersonalization:personalization]) {
                continue;
            } else {
                campaign.priority = message.priority;
                campaign.messageCenterDetails = [self personalizeMessageCenterDetails:message.messageCenterDetails withPersonalization:personalization];
            }
        } else if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
            SwrveConversationCampaign *swrveConversationCampaign = (SwrveConversationCampaign *) campaign;
            campaign.priority = swrveConversationCampaign.conversation.priority;
        } else if ([campaign isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            SwrveEmbeddedCampaign *swrveEmbeddedCampaign = (SwrveEmbeddedCampaign *) campaign;
            campaign.priority = swrveEmbeddedCampaign.message.priority;
        }

        NSSet *assetsOnDisk = [assetsManager assetsOnDisk];
        if (campaign.messageCenter && campaign.state.status != SWRVE_CAMPAIGN_STATUS_DELETED && [campaign isActive:now withReasons:nil] && [campaign assetsReady:assetsOnDisk withPersonalization:personalization]) {
            [result addObject:campaign];
        }
    }
    return result;
}

- (NSArray *)messageCenterCampaigns {
    return [self messageCenterCampaignsWithPersonalization:[self includeRealTimeUserProperties:nil] andPredicate:nil];
}

#if TARGET_OS_IOS /** exclude tvOS **/

- (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)messageOrientation {
    return [self messageCenterCampaignsWithPersonalization:[self includeRealTimeUserProperties:nil] andPredicate:^BOOL(SwrveCampaign *campaign) {
        return [campaign supportsOrientation:messageOrientation];
    }];
}

- (NSArray *)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)messageOrientation withPersonalization:(NSDictionary *)personalization {
    NSDictionary *personalizationProperties = [self includeRealTimeUserProperties:personalization];
    return [self messageCenterCampaignsWithPersonalization:personalizationProperties andPredicate:^BOOL(SwrveCampaign *campaign) {
        BOOL supportsOrientation = [campaign supportsOrientation:messageOrientation];
        if (!supportsOrientation) {
            return NO;
        }
        return YES;
    }];
}

#endif

- (NSArray *)messageCenterCampaignsWithPersonalization:(NSDictionary *)personalization {
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

    NSSet *assetsOnDisk = [assetsManager assetsOnDisk];
    NSDictionary *personalizationProperties = [self includeRealTimeUserProperties:personalization];
    if (!campaign.messageCenter || ![campaign assetsReady:assetsOnDisk withPersonalization:personalizationProperties]) {
        return NO;
    }

    if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SwrveConversation *conversation = ((SwrveConversationCampaign *) campaign).conversation;
            [self showConversation:conversation queue:false];
        });
        return YES;
    } else if ([campaign isKindOfClass:[SwrveInAppCampaign class]]) {
        SwrveInAppCampaign *swrveCampaign = (SwrveInAppCampaign *) campaign;
        SwrveMessage *message = swrveCampaign.message;

        if (![message canResolvePersonalization:personalizationProperties]) {
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
        if (message != nil) {
            if (self.embeddedMessageConfig.embeddedMessageCallbackWithPersonalization != nil) {
                self.embeddedMessageConfig.embeddedMessageCallbackWithPersonalization(message, personalizationProperties);
            } else if (self.embeddedMessageConfig.embeddedMessageCallback != nil) {
                self.embeddedMessageConfig.embeddedMessageCallback(message);
            }
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
        [campaign.state setStatus:SWRVE_CAMPAIGN_STATUS_DELETED];
        [self saveCampaignsState];
    }
}

- (void)markMessageCenterCampaignAsSeen:(SwrveCampaign *)campaign {
    if (analyticsSDK == nil) {
        return;
    }
    if (campaign != nil && campaign.messageCenter) {
        [campaign.state setStatus:SWRVE_CAMPAIGN_STATUS_SEEN];
        [self saveCampaignsState];
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

@end
