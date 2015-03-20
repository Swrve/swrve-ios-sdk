#import "SwrveMessageController.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveCampaign.h"
#import "SwrveImage.h"
#import "SwrveTalkQA.h"

static NSString* swrve_folder         = @"com.ngt.msgs";
static NSString* swrve_campaign_cache = @"cmcc2.json";
static NSString* swrve_campaign_cache_signature = @"cmccsgt2.txt";
static NSString* swrve_device_token_key = @"swrve_device_token";

const static int CAMPAIGN_VERSION            = 4;
const static int CAMPAIGN_RESPONSE_VERSION   = 1;
const static int DEFAULT_DELAY_FIRST_MESSAGE = 150;
const static int DEFAULT_MAX_SHOWS           = 99999;
const static int DEFAULT_MIN_DELAY           = 55;

@interface Swrve(PrivateMethodsForMessageController)
@property BOOL campaignsAndResourcesInitialized;
-(void) setPushNotificationsDeviceToken:(NSData*)deviceToken;
-(void) pushNotificationReceived:(NSDictionary*)userInfo;
-(void) invalidateETag;
-(NSDate*) getNow;
@end

@interface Swrve (SwrveHelperMethods)
- (CGRect) getDeviceScreenBounds;
- (NSString*) getSignatureKey;
- (void) sendHttpGETRequest:(NSURL*)url completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;
@end

@interface SwrveCampaign(PrivateMethodsForMessageController)
-(void)messageWasShownToUser:(SwrveMessage*)message at:(NSDate*)timeShown;
@end

@interface SwrveMessageController()

@property (nonatomic, retain) NSString*             user;
@property (nonatomic, retain) NSString*             cdnRoot;
@property (nonatomic, retain) NSString*             apiKey;
@property (nonatomic, retain) NSString*         	server;
@property (nonatomic, retain) NSMutableSet*         assetsOnDisk;
@property (nonatomic, retain) NSString*             cacheFolder;
@property (nonatomic, retain) NSString*             campaignCache;
@property (nonatomic, retain) NSString*             campaignCacheSignature;
@property (nonatomic, retain) SwrveSignatureProtectedFile* campaignFile;
@property (nonatomic, retain) NSString*             language; // ISO language code
@property (nonatomic, retain) NSFileManager*        manager;
@property (nonatomic, retain) NSMutableDictionary*  appStoreURLs;
@property (nonatomic, retain) NSMutableArray*       notifications;
@property (nonatomic, retain) NSString*             settingsPath;
@property (nonatomic, retain) NSDate*               initialisedTime; // SDK init time
@property (nonatomic, retain) NSDate*               showMessagesAfterLaunch; // Only show messages after this time.
@property (nonatomic, retain) NSDate*               showMessagesAfterDelay; // Only show messages after this time.
@property (nonatomic)         bool                  pushEnabled; // Decide if push notification is enabled
@property (nonatomic, retain) NSSet*                pushNotificationEvents; // Events that trigger the push notification dialog
@property (nonatomic, retain) NSMutableSet*         assetsCurrentlyDownloading;
@property (nonatomic)         bool                  autoShowMessagesEnabled;
@property (nonatomic, retain) UIWindow*             inAppMessageWindow;
@property (nonatomic)         SwrveActionType       inAppMessageActionType;
@property (nonatomic, retain) NSString*             inAppMessageAction;

// Current Device Properties
@property (nonatomic) int device_width;
@property (nonatomic) int device_height;
@property (nonatomic) SwrveInterfaceOrientation orientation;


// Only ever show this many messages. This number is decremented each time a
// message is shown.
@property (atomic) long messagesLeftToShow;
@property (atomic) NSTimeInterval minDelayBetweenMessage;

@property (nonatomic) Swrve* analyticsSDK;

// QA
@property (nonatomic) SwrveTalkQA* qaUser;

// Private functions
- (void) initCampaignsFromCacheFile;
@end

@implementation SwrveMessageController

@synthesize server, cdnRoot, apiKey;
@synthesize cacheFolder;
@synthesize campaignCache;
@synthesize campaignCacheSignature;
@synthesize campaignFile;
@synthesize manager;
@synthesize settingsPath;
@synthesize initialisedTime;
@synthesize showMessagesAfterLaunch;
@synthesize showMessagesAfterDelay;
@synthesize messagesLeftToShow;
@synthesize backgroundColor;
@synthesize campaigns;
@synthesize user;
@synthesize assetsOnDisk;
@synthesize notifications;
@synthesize language;
@synthesize appStoreURLs;
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize assetsCurrentlyDownloading;
@synthesize inAppMessageWindow;
@synthesize inAppMessageActionType;
@synthesize inAppMessageAction;
@synthesize device_width;
@synthesize device_height;
@synthesize orientation;
@synthesize qaUser;
@synthesize autoShowMessagesEnabled;
@synthesize analyticsSDK;
@synthesize minDelayBetweenMessage;
@synthesize showMessageDelegate;
@synthesize customButtonCallback;
@synthesize installButtonCallback;
@synthesize showMessageTransition;
@synthesize hideMessageTransition;

- (id)initWithSwrve:(Swrve*)sdk
{
    self = [super init];
    CGRect screen_bounds = [sdk getDeviceScreenBounds];
    const int side_a = (int)screen_bounds.size.width;
    const int side_b = (int)screen_bounds.size.height;
    self.device_height = (side_a > side_b)? side_a : side_b;
    self.device_width  = (side_a > side_b)? side_b : side_a;
    self.orientation   = sdk.config.orientation;

    self.language           = sdk.config.language;
    self.user               = sdk.userID;
    self.apiKey             = sdk.apiKey;
    self.server             = sdk.config.contentServer;
    self.analyticsSDK       = sdk;
    self.pushEnabled        = sdk.config.pushEnabled;
    self.pushNotificationEvents = sdk.config.pushNotificationEvents;
    self.cdnRoot            = nil;
    self.appStoreURLs       = [[NSMutableDictionary alloc] init];
    self.assetsOnDisk       = [[NSMutableSet alloc] init];
    self.backgroundColor    = sdk.config.defaultBackgroundColor;
    
    NSString* cacheRoot     = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    self.settingsPath       = [cacheRoot stringByAppendingPathComponent:@"com.swrve.messages.settings.plist"];
    self.cacheFolder        = [cacheRoot stringByAppendingPathComponent:swrve_folder];
    self.campaignCache      = [self.cacheFolder stringByAppendingPathComponent:swrve_campaign_cache];
    self.campaignCacheSignature = [self.cacheFolder stringByAppendingPathComponent:swrve_campaign_cache_signature];
    self.manager            = [NSFileManager defaultManager];
    self.notifications      = [[NSMutableArray alloc] init];
    self.assetsCurrentlyDownloading = [[NSMutableSet alloc] init];
    self.autoShowMessagesEnabled = YES;
    
    // Game rule defaults
    self.initialisedTime = [sdk getNow];
    self.showMessagesAfterLaunch  = [sdk getNow];
    self.messagesLeftToShow = LONG_MAX;
    
    DebugLog(@"Swrve Messaging System initialised: Server: %@ Game: %@",
          self.server,
          self.apiKey);

    SwrveMessageController * __weak weakSelf = self;
    [sdk setEventQueuedCallback:^(NSDictionary *eventPayload, NSString *eventsPayloadAsJSON) {
        #pragma unused(eventsPayloadAsJSON)
        SwrveMessageController * strongSelf = weakSelf;
        if (strongSelf != nil) {
            [strongSelf eventRaised:eventPayload];
        }
    }];
    
    
    NSAssert1([self.language length] > 0, @"Invalid language specified %@", self.language);
    NSAssert1([self.user     length] > 0, @"Invalid username specified %@", self.user);
    NSAssert(self.analyticsSDK != NULL,   @"Swrve Analytics SDK is null", nil);

    NSData* device_token = [[NSUserDefaults standardUserDefaults] objectForKey:swrve_device_token_key];
    if (self.pushEnabled && device_token) {
        // Once we have a device token, ask for it every time
        [self registerForPushNotifications];
        [self setDeviceToken:device_token];
    }
    
    // Initialize campaign cache file
    [self initCampaignsFromCacheFile];

    self.showMessageTransition = [CATransition animation];
    self.showMessageTransition.type = kCATransitionPush;
    self.showMessageTransition.subtype = kCATransitionFromBottom;
    self.showMessageTransition.duration = 0.25;
    self.showMessageTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    self.showMessageTransition.removedOnCompletion = YES;
    
    self.hideMessageTransition = [CATransition animation];
    self.hideMessageTransition.type = kCATransitionPush;
    self.hideMessageTransition.subtype = kCATransitionFromTop;
    self.hideMessageTransition.duration = 0.25;
    self.hideMessageTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    self.hideMessageTransition.removedOnCompletion = YES;
    self.hideMessageTransition.delegate = self;
    
    return self;
}

-(void)registerForPushNotifications
{
    UIApplication* app = [UIApplication sharedApplication];
#ifdef __IPHONE_8_0
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    if (![app respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        // Use the old API
        [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    else
#endif
    {
        [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:self.analyticsSDK.config.pushCategories]];
        [app registerForRemoteNotifications];
    }
#else
    // Not building with the latest XCode that contains iOS 8 definitions
    [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

- (NSDictionary*)getCampaignSettings
{
    NSMutableDictionary* settings = [[NSMutableDictionary alloc] init];
    NSData* data = [NSData dataWithContentsOfFile:[self settingsPath]];

    if(!data)
    {
        DebugLog(@"Error: No settings loaded. [Reading from %@]", [self settingsPath]);
        return [NSDictionary dictionaryWithDictionary:settings];
    }
    
    NSError* error = NULL;
    NSArray* loadedSettings = [NSPropertyListSerialization propertyListWithData:data
                                                                        options:NSPropertyListImmutable
                                                                         format:NULL
                                                                          error:&error];
    for (NSDictionary* setting in loadedSettings)
    {
        NSString* campaignId = [setting objectForKey:@"ID"];
        if(campaignId)
        {
            [settings setValue:setting forKey:campaignId];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:settings];
}

- (void)saveSettings
{
    NSMutableArray* newSettings = [[NSMutableArray alloc] initWithCapacity:self.campaigns.count];
    
    for (SwrveCampaign* campaign in self.campaigns)
    {
        [newSettings addObject:[campaign campaignSettings]];
    }
    
    NSError*  error = NULL;
    NSData*   data = [NSPropertyListSerialization dataWithPropertyList:newSettings
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&error];
    if(data)
    {
        BOOL success = [data writeToFile:[self settingsPath] atomically:YES];
        if (!success)
        {
            DebugLog(@"Error writing to : %@", [self settingsPath]);
        }
    }
    else
    {
        DebugLog(@"Error: %@ writing to %@", error, [self settingsPath]);
    }
}

- (void) initCampaignsFromCacheFile
{
    // Create campaign cache folder
    NSError* error;
    if (![manager createDirectoryAtPath:self.cacheFolder
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error])
    {
        DebugLog(@"Error creating %@: %@", self.cacheFolder, error);
    }

    // Create signature protected cache file
    NSURL* fileURL = [NSURL fileURLWithPath:self.campaignCache];
    NSURL* signatureURL = [NSURL fileURLWithPath:self.campaignCacheSignature];
    campaignFile = [[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:[self.analyticsSDK getSignatureKey]];

    // read content of campaigns file and update campaigns
    NSData* content = [campaignFile readFromFile];

    if (content != nil) {
        NSError* jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:0 error:&jsonError];
        if (!jsonError) {
            [self updateCampaigns:jsonDict];
        }
    } else {
        [[self analyticsSDK] invalidateETag];
    }
}

static NSNumber* numberFromJsonWithDefault(NSDictionary* json, NSString* key, int defaultValue)
{
    NSNumber* result = [json objectForKey:key];
    if (!result){
        result = [NSNumber numberWithInt:defaultValue];
    }
    return result;
}

-(void) writeToCampaignCache:(NSData*)campaignData
{
    [[self campaignFile] writeToFile:campaignData];
}

-(void) updateCampaigns:(NSDictionary*)campaignJson
{
    if (campaignJson == nil) {
        DebugLog(@"Error parsing campaign JSON", nil);
        return;
    }

    if ([campaignJson count] == 0) {
        DebugLog(@"Campaign JSON empty, no campaigns downloaded", nil);
        self.campaigns = [[NSArray alloc] init];
        return;
    }

    NSMutableSet* assetsQueue = [[NSMutableSet alloc] init];
    NSMutableArray* result    = [[NSMutableArray alloc] init];

    // Version check
    NSNumber* version = [campaignJson objectForKey:@"version"];
    if ([version integerValue] != CAMPAIGN_RESPONSE_VERSION){
        DebugLog(@"Campaign JSON has the wrong version. No campaigns loaded.", nil);
        return;
    }

    // CDN
    self.cdnRoot = [campaignJson objectForKey:@"cdn_root" ];
    DebugLog(@"CDN URL %@", self.cdnRoot);

    // Game Data
    NSDictionary* gameData = [campaignJson objectForKey:@"game_data"];
    if (gameData){
        for (NSString* game  in gameData) {
            NSString* url = [(NSDictionary*)[gameData objectForKey:game] objectForKey:@"app_store_url"];
            [self.appStoreURLs setValue:url forKey:game];
            DebugLog(@"App Store link %@: %@", game, url);
        }
    }
    
    NSDictionary* rules = [campaignJson objectForKey:@"rules"];
    {
        NSNumber* delay    = numberFromJsonWithDefault(rules, @"delay_first_message", DEFAULT_DELAY_FIRST_MESSAGE);
        NSNumber* maxShows = numberFromJsonWithDefault(rules, @"max_messages_per_session", DEFAULT_MAX_SHOWS);
        NSNumber* minDelay = numberFromJsonWithDefault(rules, @"min_delay_between_messages", DEFAULT_MIN_DELAY);
  
        self.showMessagesAfterLaunch  = [self.initialisedTime dateByAddingTimeInterval:delay.doubleValue];
        self.minDelayBetweenMessage = minDelay.doubleValue;
        self.messagesLeftToShow = maxShows.longValue;
    
        DebugLog(@"Game rules OK: Delay Seconds: %@ Max shows: %@ ", delay, maxShows);
        DebugLog(@"Time is %@ show messages after %@", [[self analyticsSDK] getNow], [self showMessagesAfterLaunch]);
    }
    
    // QA
    NSMutableDictionary* campaignsDownloaded = nil;
    
    NSDictionary* json_qa = [campaignJson objectForKey:@"qa"];
    if(json_qa) {
        DebugLog(@"You are a QA user!", nil);
        campaignsDownloaded = [[NSMutableDictionary alloc] init];
        self.qaUser = [[SwrveTalkQA alloc] initWithJSON:json_qa withAnalyticsSDK:self.analyticsSDK];
        
        NSArray* json_qa_campaigns = [json_qa objectForKey:@"campaigns"];
        if(json_qa_campaigns) {
            for (NSDictionary* json_qa_campaign in json_qa_campaigns) {
                NSNumber* campaign_id = [json_qa_campaign objectForKey:@"id"];
                NSString* campaign_reason = [json_qa_campaign objectForKey:@"reason"];
            
                DebugLog(@"Campaign %@ not downloaded because: %@", campaign_id, campaign_reason);
                
                // Add campaign for QA purposes
                [campaignsDownloaded setValue:campaign_reason forKey:[campaign_id stringValue]];
            }
        }
        
        // Process any remote notifications
        for (NSDictionary* notification in self.notifications) {
            [self.qaUser pushNotification:notification];
        }
    } else {
        self.qaUser = nil;
    }
    
    // Empty saved push notifications
    [self.notifications removeAllObjects];
    
    NSDictionary* settings = [self getCampaignSettings];

    NSArray* json_campaigns = [campaignJson objectForKey:@"campaigns"];
    for (NSDictionary* dict in json_campaigns)
    {
        SwrveCampaign* campaign = [[SwrveCampaign alloc] initAtTime:self.initialisedTime];
        
        campaign.ID   = [[dict objectForKey:@"id"] unsignedIntegerValue];
        campaign.name = [dict objectForKey:@"name"];

        DebugLog(@"Got campaign with id %ld", (long)campaign.ID);

        [campaign loadTriggersFrom:dict];
        [campaign loadRulesFrom:   dict];
        [campaign loadDatesFrom:   dict];

        NSMutableArray* messages = [[NSMutableArray alloc] init];
        NSArray* campaign_messages = [dict objectForKey:@"messages"];
        for (NSDictionary* messageDict in campaign_messages)
        {
            SwrveMessage* message = [SwrveMessage fromJSON:messageDict forCampaign:campaign forController:self];

            for (SwrveMessageFormat* format in message.formats)
            {
                // Add all images to the download queue
                for (SwrveButton* button in format.buttons)
                {
                    [assetsQueue addObject:button.image];
                }
                
                for (SwrveImage* image in format.images)
                {
                    [assetsQueue addObject:image.file];
                }
            }
            [messages addObject:message];
        }
        
        campaign.messages = [[NSArray alloc] initWithArray:messages];
        
        campaign.next = 0;
        if(!self.qaUser || !self.qaUser.resetDevice) {
            NSNumber* ID = [NSNumber numberWithUnsignedInteger:campaign.ID];
            NSDictionary* campaignSettings = [settings objectForKey:ID];
            if(campaignSettings) {
                NSNumber* next = [campaignSettings objectForKey:@"next"];
                if (next)
                {
                    campaign.next = next.unsignedIntegerValue;
                }
                NSNumber* impressions = [campaignSettings objectForKey:@"impressions"];
                if (impressions)
                {
                    campaign.impressions = impressions.unsignedIntegerValue;
                }
            }
        }
        
        [result addObject:campaign];
        
        if(self.qaUser) {
            // Add campaign for QA purposes
            [campaignsDownloaded setValue:@"" forKey:[NSString stringWithFormat:@"%ld", (long)campaign.ID]];
        }
    }
    
    // QA logging
    if (self.qaUser != nil) {
        [self.qaUser talkSession:campaignsDownloaded];
    }

    for (NSString* asset in assetsQueue) {
        #pragma unused(asset)
        DebugLog(@"Asset Set: %@", asset);
    }

    NSMutableArray* downloadQueue = [self withOutExistingFiles:assetsQueue];
    while([downloadQueue count] > 0)
    {
        [self downloadAsset: [downloadQueue lastObject]];
        [downloadQueue removeLastObject];
    }
    
    self.campaigns = [[NSArray alloc] initWithArray:result];
}

-(NSMutableArray*)withOutExistingFiles:(NSSet*)assetSet
{
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:[assetSet count]];
    
    for (NSString* file in assetSet)
    {
        NSString* target = [self.cacheFolder stringByAppendingPathComponent:file];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:target])
        {
            DebugLog(@"Adding %@ to download list" , file);
            [result addObject:file];
        }
        else
        {
            DebugLog(@"File already exists on disk %@", file);
            [self.assetsOnDisk addObject:file];
        }
    }
    
    return result;
}

-(void)downloadAsset:(NSString*)asset
{
    @synchronized([self assetsCurrentlyDownloading]) {
        [[self assetsCurrentlyDownloading] addObject:asset];
    }
    
    NSURL* url = [NSURL URLWithString: asset relativeToURL: [NSURL URLWithString:self.cdnRoot]];

    DebugLog(@"Downloading asset: %@", url);

    [self.analyticsSDK sendHttpGETRequest:url
                        completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
     {
        #pragma unused(response)
         if (error)
         {
             DebugLog(@"Asset Error: %@", error);
         }
         else
         {
             if (![SwrveMessageController verifySHA:data against:asset]){
                 DebugLog(@"Error downloading %@ – SHA1 does not match.", asset);
             } else {

                 NSURL* dst = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:self.cacheFolder, asset, nil]];

                 [data writeToURL:dst atomically:YES];

                 // Add the asset to the set of assets that we know are downloaded.
                 [self.assetsOnDisk addObject:asset];
                 DebugLog(@"Asset downloaded: %@", asset);
             }
         }
         
         // This asset has finished downloading
         // Check if all assets are finished and if so call autoShowMessage
         @synchronized([self assetsCurrentlyDownloading]) {
             [[self assetsCurrentlyDownloading] removeObject:asset];

             if ([[self assetsCurrentlyDownloading] count] == 0) {
                 [self autoShowMessages];
             }
         }
     }];
}

-(void)autoShowMessages
{
    // Don't do anything if we've already shown a message or if it is too long after session start
    if (![self autoShowMessagesEnabled]) {
        return;
    }
    
    // Only execute if at least 1 call to the /user_resources_and_campaigns api endpoint has been completed
    if (![[self analyticsSDK] campaignsAndResourcesInitialized]) {
        return;
    }
    
    for (SwrveCampaign* campaign in [self campaigns]) {
        if ([campaign hasMessageForEvent:AUTOSHOW_AT_SESSION_START_TRIGGER]) {
            @synchronized(self) {
                if ([self autoShowMessagesEnabled]) {
                    NSDictionary* event = @{@"type": @"event", @"name": AUTOSHOW_AT_SESSION_START_TRIGGER};
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

-(BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate*)now
{
    return [now compare:[self showMessagesAfterLaunch]] == NSOrderedAscending;
}

-(BOOL)isTooSoonToShowMessageAfterDelay:(NSDate*)now
{
    return [now compare:[self showMessagesAfterDelay]] == NSOrderedAscending;
}

-(BOOL)hasShowTooManyMessagesAlready
{
    return self.messagesLeftToShow <= 0;
}

-(SwrveMessage*)getMessageForEvent:(NSString *)event
{
    NSDate* now = [[self analyticsSDK] getNow];
    SwrveMessage* result = nil;
    SwrveCampaign* campaign = nil;
    
    if (self.campaigns != nil) {
        if ([self.campaigns count] == 0)
        {
            [self noMessagesWereShown:event withReason:@"No campaigns available"];
            return nil;
        }
        
        // Ignore delay after launch throttle limit for auto show messages
        if ([event caseInsensitiveCompare:AUTOSHOW_AT_SESSION_START_TRIGGER] != NSOrderedSame && [self isTooSoonToShowMessageAfterLaunch:now])
        {
            [self noMessagesWereShown:event withReason:[NSString stringWithFormat:@"{App throttle limit} Too soon after launch. Wait until %@", [[self class] getTimeFormatted:self.showMessagesAfterLaunch]]];
            return nil;
        }
        
        if ([self isTooSoonToShowMessageAfterDelay:now])
        {
            [self noMessagesWereShown:event withReason:[NSString stringWithFormat:@"{App throttle limit} Too soon after last message. Wait until %@", [[self class] getTimeFormatted:self.showMessagesAfterDelay]]];
            return nil;
        }
        
        if ([self hasShowTooManyMessagesAlready])
        {
            [self noMessagesWereShown:event withReason:@"{App throttle limit} Too many messages shown"];
            return nil;
        }
        
        NSMutableDictionary* campaignReasons = nil;
        NSMutableDictionary* campaignMessages = nil;
        if (self.qaUser != nil) {
            campaignReasons = [[NSMutableDictionary alloc] init];
            campaignMessages = [[NSMutableDictionary alloc] init];
        }

        NSMutableArray* availableMessages = [[NSMutableArray alloc] init];
        // Select messages with higher priority that have the current orientation
        NSNumber* minPriority = [NSNumber numberWithInteger:INT_MAX];
        NSMutableArray* candidateMessages = [[NSMutableArray alloc] init];
        // Get current orientation
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        for (SwrveCampaign* campaignIt in self.campaigns)
        {
            SwrveMessage* nextMessage = [campaignIt getMessageForEvent:event withAssets:self.assetsOnDisk atTime:now withReasons:campaignReasons];
            if (nextMessage != nil) {
                if ([nextMessage supportsOrientation:currentOrientation]) {
                    // Add to list of returned messages
                    [availableMessages addObject:nextMessage];
                    // Check if it is a candidate to be shown
                    long nextMessagePriorityLong = [nextMessage.priority longValue];
                    long minPriorityLong = [minPriority longValue];
                    if (nextMessagePriorityLong <= minPriorityLong) {
                        minPriority = nextMessage.priority;
                        if (nextMessagePriorityLong < minPriorityLong) {
                            [candidateMessages removeAllObjects];
                        }
                        [candidateMessages addObject:nextMessage];
                    }
                } else {
                    if (self.qaUser != nil) {
                        NSString* campaignIdString = [[NSNumber numberWithUnsignedInteger:campaignIt.ID] stringValue];
                        [campaignMessages setValue:nextMessage.messageID forKey:campaignIdString];
                        [campaignReasons setValue:@"Message didn't support the given orientation" forKey:campaignIdString];
                    }
                }
            }
        }
        
        NSArray* shuffledCandidates = [SwrveMessageController shuffled:candidateMessages];
        if ([shuffledCandidates count] > 0) {
            result = [shuffledCandidates objectAtIndex:0];
            campaign = result.campaign;
        }
        
        if (self.qaUser != nil && campaign != nil && result != nil) {
            // A message was chosen, set the reason for the others
            for (SwrveMessage* otherMessage in availableMessages)
            {
                if (result != otherMessage)
                {
                    SwrveCampaign* c = otherMessage.campaign;
                    if (c != nil)
                    {
                        NSString* campaignIdString = [[NSNumber numberWithUnsignedInteger:c.ID] stringValue];
                        [campaignMessages setValue:otherMessage.messageID forKey:campaignIdString];
                        [campaignReasons setValue:[NSString stringWithFormat:@"Campaign %ld was selected for display ahead of this campaign", (long)campaign.ID] forKey:campaignIdString];
                    }
                }
            }
        }
        
        // If QA enabled, send message selection information
        if(self.qaUser != nil) {
            [self.qaUser trigger:event withMessage:result withReason:campaignReasons withMessages:campaignMessages];
        }
    }

    if (result == nil) {
        DebugLog(@"Not showing message: no candidate messages for %@", event);
    }
    return result;
}

-(void)noMessagesWereShown:(NSString*)event withReason:(NSString*)reason
{
    DebugLog(@"Not showing message for %@: %@", event, reason);
    if (self.qaUser != nil) {
        [self.qaUser triggerFailure:event withReason:reason];
    }
}

+(NSString*)getTimeFormatted:(NSDate*)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"HH:mm:ss Z"];
    
    return [dateFormatter stringFromDate:date];
}

+(NSArray*)shuffled:(NSArray*)source;
{
    unsigned long count = [source count];
    
    // Early out if there is 0 or 1 elements.
    if (count < 2)
    {
        return source;
    }
    
    // Copy
    NSMutableArray* result = [NSMutableArray arrayWithArray:source];
    
    for (unsigned long i = 0; i < count; i++)
    {
        unsigned long remain = count - i;
        unsigned long n = (arc4random() % remain) + i;
        [result exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    
    return result;
}



+(bool)verifySHA:(NSData*)data against:(NSString*)expectedDigest
{
    const static char hex[] = {'0', '1', '2', '3',
                               '4', '5', '6', '7',
                               '8', '9', 'a', 'b',
                               'c', 'd', 'e', 'f'};

    unsigned char digest[CC_SHA1_DIGEST_LENGTH];

    // SHA-1 hash has been calculated and stored in 'digest'
    unsigned int length = (unsigned int)[data length];
    if (CC_SHA1([data bytes], length, digest)) {
        for (unsigned int i = 0; i < [expectedDigest length]; i++) {
            unichar c = [expectedDigest characterAtIndex:i];
            unsigned char e = digest[i>>1];

            if (i&1) {
                e = e & 0xF;
            } else {
                e = e >> 4;
            }

            e = (unsigned char)hex[e];

            if (c != e) {
                DebugLog(@"SHA[%d] Expected: %d Computed %d", i, e, c);
                return false;
            }
        }
    }

    DebugLog(@"SHA Check OK %@", expectedDigest);
    
    return true;
}

-(void)setMessageMinDelayThrottle
{
    NSDate* now = [[self analyticsSDK] getNow];
    [self setShowMessagesAfterDelay:[now dateByAddingTimeInterval:[self minDelayBetweenMessage]]];
}

-(void)messageWasShownToUser:(SwrveMessage*)message
{
    NSDate* now = [[self analyticsSDK] getNow];
    // The message was shown. Take the current time so that we can throttle messages
    // from being shown too quickly.
    [self setMessageMinDelayThrottle];
    [self setMessagesLeftToShow:self.messagesLeftToShow - 1];

    SwrveCampaign* c = message.campaign;
    if (c != nil) {
        [c messageWasShownToUser:message at:now];
    }
    [self saveSettings];

    NSString* viewEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%d.impression", [message.messageID intValue]];
    DebugLog(@"Sending view event: %@", viewEvent);
    
    [self.analyticsSDK eventWithNoCallback:viewEvent payload:nil];
}

-(void)buttonWasPressedByUser:(SwrveButton*)button
{
    if (button.actionType != kSwrveActionDismiss) {

        NSString* clickEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%ld.click", button.messageID];
        DebugLog(@"Sending click event: %@", clickEvent);
        [self.analyticsSDK eventWithNoCallback:clickEvent payload:nil];
    }
}

-(NSString*)getAppStoreURLForGame:(long)game
{
    return [self.appStoreURLs objectForKey:[NSString stringWithFormat:@"%ld", game]];
}

-(NSString*) getEventName:(NSDictionary*)eventParameters
{
    NSString* eventName = @"";
    
    NSString* eventType = [eventParameters objectForKey:@"type"];
    if( [eventType isEqualToString:@"session_start"])
    {
        eventName = @"Swrve.session.start";
    }
    else if( [eventType isEqualToString:@"session_end"])
    {
        eventName = @"Swrve.session.end";
    }
    else if( [eventType isEqualToString:@"buy_in"])
    {
        eventName = @"Swrve.buy_in";
    }
    else if( [eventType isEqualToString:@"iap"])
    {
        eventName = @"Swrve.iap";
    }
    else if( [eventType isEqualToString:@"event"])
    {
        eventName = [eventParameters objectForKey:@"name"];
    }
    else if( [eventType isEqualToString:@"purchase"])
    {
        eventName = @"Swrve.user_purchase";
    }
    else if( [eventType isEqualToString:@"currency_given"])
    {
        eventName = @"Swrve.currency_given";
    }
    else if( [eventType isEqualToString:@"user"])
    {
        eventName = @"Swrve.user_properties_changed	";
    }

    return eventName;
}

- (SwrveMessage*)findMessageForEvent:(NSString*) eventName withParameters:(NSDictionary *)parameters;
{
    #pragma unused(parameters)
    // By default does a simple by name look up.
    return [self getMessageForEvent:eventName];
}


-(void) showMessage:(SwrveMessage *)message
{
    if ( message && self.inAppMessageWindow == nil ) {
        SwrveMessageViewController* messageViewController = [[SwrveMessageViewController alloc] init];
        messageViewController.view.backgroundColor = self.backgroundColor;
        messageViewController.message = message;
        messageViewController.block = ^(SwrveActionType type, NSString* action, NSInteger appId) {
            #pragma unused(appId)
            // Save button type and action for processing later
            self.inAppMessageActionType = type;
            self.inAppMessageAction = action;
            
            if( [self.showMessageDelegate respondsToSelector:@selector(beginHideMessageAnimation:)]) {
                [self.showMessageDelegate beginHideMessageAnimation:(SwrveMessageViewController*)self.inAppMessageWindow.rootViewController];
            }
            else {
                [self beginHideMessageAnimation:(SwrveMessageViewController*)self.inAppMessageWindow.rootViewController];
            }
        };
        
        [self showMessageWindow:messageViewController];
    }
}

- (void) showMessageWindow:(SwrveMessageViewController*) messageViewController {
    
    if( messageViewController == nil ) {
        DebugLog(@"Cannot show a nil view.", nil);
        return;
    }
    
    if( self.inAppMessageWindow != nil ) {
        DebugLog(@"A message is already displayed, ignoring second message.", nil);
        return;
    }
    
    if( [self.showMessageDelegate respondsToSelector:@selector(messageWillBeShown:)]) {
        [self.showMessageDelegate messageWillBeShown:messageViewController];
    }
    
    self.inAppMessageWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.inAppMessageWindow.rootViewController.view.alpha = 0.0f;
    self.inAppMessageWindow.rootViewController = messageViewController;
    self.inAppMessageWindow.windowLevel = UIWindowLevelAlert + 1;
    [self.inAppMessageWindow makeKeyAndVisible];
    
    if( [self.showMessageDelegate respondsToSelector:@selector(beginShowMessageAnimation:)]) {
        [self.showMessageDelegate beginShowMessageAnimation:messageViewController];
    }
    else {
        [self beginShowMessageAnimation:messageViewController];
    }
}

- (void) dismissMessageWindow {
    if( self.inAppMessageWindow == nil ) {
        DebugLog(@"No message to dismiss.", nil);
        return;
    }
    [self setMessageMinDelayThrottle];
    NSDate* now = [[self analyticsSDK] getNow];
    SwrveCampaign* dismissedCampaign = ((SwrveMessageViewController*)self.inAppMessageWindow.rootViewController).message.campaign;
    [dismissedCampaign messageDismissed:now];
    
    if( [self.showMessageDelegate respondsToSelector:@selector(messageWillBeHidden:)]) {
        [self.showMessageDelegate messageWillBeHidden:(SwrveMessageViewController*)self.inAppMessageWindow.rootViewController];
    }
    
    NSString* action = self.inAppMessageAction;
    NSString* nonProcessedAction = nil;
    switch(self.inAppMessageActionType)
    {
        case kSwrveActionDismiss: break;
        case kSwrveActionInstall:
        {
            BOOL standardEvent = true;
            if (self.installButtonCallback != nil) {
                standardEvent = self.installButtonCallback(action);
            }
            
            if (standardEvent) {
                nonProcessedAction = action;
            }
        }
            break;
        case kSwrveActionCustom:
        {
            if (self.customButtonCallback != nil) {
                self.customButtonCallback(action);
            } else {
                nonProcessedAction = action;
            }
        }
            break;
    }
    
    if(nonProcessedAction != nil) {
        NSURL* url = [NSURL URLWithString: nonProcessedAction];
        
        if( url != nil ) {
            DebugLog(@"Action - %@ - handled.  Sending to applition as URL", nonProcessedAction);
            [[UIApplication sharedApplication] openURL:url];
        } else {
            DebugLog(@"Action - %@ -  not handled.  Override the SwrveCustomButtonPressedCallback customize message actions", nonProcessedAction);
        }
    }

    self.inAppMessageWindow.hidden = YES;
    self.inAppMessageWindow = nil;
    self.inAppMessageAction = nil;
}

- (void) beginShowMessageAnimation:(SwrveMessageViewController*) viewController {
    viewController.view.alpha = 0.0f;
    [UIView animateWithDuration:0.25
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.inAppMessageWindow.rootViewController.view.alpha = 1.0f;
                     }
                     completion:nil];
}

- (void) beginHideMessageAnimation:(SwrveMessageViewController*) viewController {
    #pragma unused(viewController)
    [UIView animateWithDuration:0.25
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.inAppMessageWindow.rootViewController.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         #pragma unused(finished)
                         [self dismissMessageWindow];
                     }];
}

-(void) userPressedButton:(SwrveActionType) actionType action:(NSString*) action {
    #pragma unused(actionType, action)
    if( self.inAppMessageWindow != nil && self.inAppMessageWindow.hidden == YES ) {
        self.inAppMessageWindow.hidden = YES;
        self.inAppMessageWindow = nil;
    }
}

-(BOOL) eventRaised:(NSDictionary*)event;
{    
    // Get event name
    NSString* eventName = [self getEventName:event];
    
    if (self.pushEnabled) {
        if ([eventName isEqualToString:@"Swrve.push_notification_permission"] || (self.pushNotificationEvents != nil && [self.pushNotificationEvents containsObject:eventName])) {
                // Ask for push notification permission
                [self registerForPushNotifications];
        }
    }
    
    // Find a message that should be fired
    SwrveMessage* message = nil;
    if( [self.showMessageDelegate respondsToSelector:@selector(findMessageForEvent: withParameters:)]) {
        message = [self.showMessageDelegate findMessageForEvent:eventName withParameters:event];
    }
    else {
        message = [self findMessageForEvent:eventName withParameters:event];
    }
    
    // Only show the message if it supports the given orientation
    if ( message != nil && ![message supportsOrientation:[[UIApplication sharedApplication] statusBarOrientation]] ) {
        DebugLog(@"The message doesn't support the current orientation", nil);
        return NO;
    }

    // Show the message if it exists
    if( message != nil ) {
        dispatch_block_t showMessageBlock = ^{
            if( [self.showMessageDelegate respondsToSelector:@selector(showMessage:)]) {
                [self.showMessageDelegate showMessage:message];
            }
            else {
                [self showMessage:message];
            }
        };

        
        if ([NSThread isMainThread]) {
            showMessageBlock();
        } else {
            // Run in the main thread as we have been called from other thread
            dispatch_async(dispatch_get_main_queue(), showMessageBlock);
        }
    }
    
    return ( message != nil );
}

- (void) setDeviceToken:(NSData*)deviceToken
{
   if (self.pushEnabled && deviceToken) {
       [self.analyticsSDK setPushNotificationsDeviceToken:deviceToken];

        if (self.qaUser) {
            // If we are a QA user then send a device info update
            [self.qaUser updateDeviceInfo];
        }
    }
}

- (void) pushNotificationReceived:(NSDictionary*)userInfo
{
    if (self.pushEnabled) {
        // Do not process the push notification if the app was on the foreground
        if ([self.analyticsSDK appInBackground]) {
            [self.analyticsSDK pushNotificationReceived:userInfo];
            if (self.qaUser) {
               [self.qaUser pushNotification:userInfo];
            } else {
                DebugLog(@"Queuing push notification for later", nil);
                [self.notifications addObject:userInfo];
            }
        }
    }
}

- (BOOL) isQaUser
{
    return self.qaUser != nil;
}

- (NSString*) orientationName
{
    switch (orientation) {
        case SWRVE_ORIENTATION_LANDSCAPE:
            return @"landscape";
        case SWRVE_ORIENTATION_PORTRAIT:
            return @"portrait";
        default:
            return @"both";
    }
}

- (NSString*) getCampaignQueryString
{
    const NSString* orientationName = [self orientationName];

    UIDevice* device   = [UIDevice currentDevice];
    NSString* encodedDeviceName = [[device model] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString* encodedSystemName = [[device systemName] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

    return [NSString stringWithFormat:@"version=%d&orientation=%@&language=%@&app_store=%@&device_width=%d&device_height=%d&os_version=%@&device_name=%@",
            CAMPAIGN_VERSION, orientationName, self.language, @"apple", self.device_width, self.device_height, encodedDeviceName, encodedSystemName];
}

@end
