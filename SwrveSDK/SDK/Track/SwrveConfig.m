#import "SwrveConfig.h"
#import "Swrve.h"
#import "SwrveFileManagement.h"

@implementation SwrveConfig

@synthesize userId;
@synthesize orientation;
@synthesize prefersIAMStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize useHttpsForEventServer;
@synthesize contentServer;
@synthesize useHttpsForContentServer;
@synthesize language;
@synthesize eventCacheFile;
@synthesize eventCacheSecondaryFile;
@synthesize eventCacheSignatureFile;
@synthesize locationCampaignCacheFile;
@synthesize locationCampaignCacheSecondaryFile;
@synthesize locationCampaignCacheSignatureFile;
@synthesize locationCampaignCacheSignatureSecondaryFile;
@synthesize userResourcesCacheFile;
@synthesize userResourcesCacheSecondaryFile;
@synthesize userResourcesCacheSignatureFile;
@synthesize userResourcesCacheSignatureSecondaryFile;
@synthesize userResourcesDiffCacheFile;
@synthesize userResourcesDiffCacheSignatureFile;
@synthesize installTimeCacheFile;
@synthesize installTimeCacheSecondaryFile;
@synthesize appVersion;
@synthesize receiptProvider;
@synthesize maxConcurrentDownloads;
@synthesize autoDownloadCampaignsAndResources;
@synthesize talkEnabled;
@synthesize defaultBackgroundColor;
@synthesize conversationLightBoxColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize autoShowMessagesMaxDelay;
@synthesize selectedStack;

-(id) init
{
    if ( self = [super init] ) {
        httpTimeoutSeconds = 60;
        autoDownloadCampaignsAndResources = YES;
        orientation = SWRVE_ORIENTATION_BOTH;
        prefersIAMStatusBarHidden = YES;
        language = [[NSLocale preferredLanguages] objectAtIndex:0];
        newSessionInterval = 30;
        
        NSString* caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* applicationSupport = [SwrveFileManagement applicationSupportPath];
        eventCacheFile = [applicationSupport stringByAppendingPathComponent: @"swrve_events.txt"];
        eventCacheSecondaryFile = [caches stringByAppendingPathComponent: @"swrve_events.txt"];
        
        locationCampaignCacheFile = [applicationSupport stringByAppendingPathComponent: @"lc.txt"];
        locationCampaignCacheSecondaryFile = [caches stringByAppendingPathComponent: @"lc.txt"];
        locationCampaignCacheSignatureFile = [applicationSupport stringByAppendingPathComponent: @"lcsgt.txt"];
        locationCampaignCacheSignatureSecondaryFile = [caches stringByAppendingPathComponent: @"lcsgt.txt"];
        
        userResourcesCacheFile = [applicationSupport stringByAppendingPathComponent: @"srcngt2.txt"];
        userResourcesCacheSecondaryFile = [caches stringByAppendingPathComponent: @"srcngt2.txt"];
        userResourcesCacheSignatureFile = [applicationSupport stringByAppendingPathComponent: @"srcngtsgt2.txt"];
        userResourcesCacheSignatureSecondaryFile = [caches stringByAppendingPathComponent: @"srcngtsgt2.txt"];
        
        
        userResourcesDiffCacheFile = [caches stringByAppendingPathComponent: @"rsdfngt2.txt"];
        userResourcesDiffCacheSignatureFile = [caches stringByAppendingPathComponent:@"rsdfngtsgt2.txt"];
        
        self.useHttpsForEventServer = YES;
        self.useHttpsForContentServer = YES;
        self.installTimeCacheFile = [documents stringByAppendingPathComponent: @"swrve_install.txt"];
        self.installTimeCacheSecondaryFile = [caches stringByAppendingPathComponent: @"swrve_install.txt"];
        self.autoSendEventsOnResume = YES;
        self.autoSaveEventsOnResign = YES;
        self.talkEnabled = YES;
#if !defined(SWRVE_NO_PUSH)
        self.pushEnabled = NO;
        self.pushNotificationEvents = [NSSet setWithObject:@"Swrve.session.start"];
        self.autoCollectDeviceToken = YES;
#endif //!defined(SWRVE_NO_PUSH)
        self.autoShowMessagesMaxDelay = 5000;
        self.receiptProvider = [[SwrveReceiptProvider alloc] init];
        self.resourcesUpdatedCallback = ^() {
            // Do nothing by default.
        };
        self.selectedStack = SWRVE_STACK_US;
        
        self.conversationLightBoxColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:0.70f];
    }
    return self;
}

@end

@implementation ImmutableSwrveConfig

@synthesize userId;
@synthesize orientation;
@synthesize prefersIAMStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize useHttpsForEventServer;
@synthesize contentServer;
@synthesize useHttpsForContentServer;
@synthesize language;
@synthesize eventCacheFile;
@synthesize eventCacheSecondaryFile;
@synthesize eventCacheSignatureFile;
@synthesize locationCampaignCacheFile;
@synthesize locationCampaignCacheSecondaryFile;
@synthesize locationCampaignCacheSignatureFile;
@synthesize locationCampaignCacheSignatureSecondaryFile;
@synthesize userResourcesCacheFile;
@synthesize userResourcesCacheSecondaryFile;
@synthesize userResourcesCacheSignatureFile;
@synthesize userResourcesCacheSignatureSecondaryFile;
@synthesize userResourcesDiffCacheFile;
@synthesize userResourcesDiffCacheSignatureFile;
@synthesize installTimeCacheFile;
@synthesize installTimeCacheSecondaryFile;
@synthesize appVersion;
@synthesize receiptProvider;
@synthesize maxConcurrentDownloads;
@synthesize autoDownloadCampaignsAndResources;
@synthesize talkEnabled;
@synthesize defaultBackgroundColor;
@synthesize conversationLightBoxColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize autoShowMessagesMaxDelay;
@synthesize selectedStack;

- (id)initWithSwrveConfig:(SwrveConfig*)config
{
    if (self = [super init]) {
        userId = config.userId;
        orientation = config.orientation;
        prefersIAMStatusBarHidden = config.prefersIAMStatusBarHidden;
        httpTimeoutSeconds = config.httpTimeoutSeconds;
        eventsServer = config.eventsServer;
        useHttpsForEventServer = config.useHttpsForEventServer;
        contentServer = config.contentServer;
        useHttpsForContentServer = config.useHttpsForContentServer;
        language = config.language;
        eventCacheFile = config.eventCacheFile;
        eventCacheSecondaryFile = config.eventCacheSecondaryFile;
        locationCampaignCacheFile = config.locationCampaignCacheFile;
        locationCampaignCacheSecondaryFile = config.locationCampaignCacheSecondaryFile;
        locationCampaignCacheSignatureFile = config.locationCampaignCacheSignatureFile;
        locationCampaignCacheSignatureSecondaryFile = config.locationCampaignCacheSignatureSecondaryFile;
        userResourcesCacheFile = config.userResourcesCacheFile;
        userResourcesCacheSecondaryFile = config.userResourcesCacheSecondaryFile;
        userResourcesCacheSignatureFile = config.userResourcesCacheSignatureFile;
        userResourcesCacheSignatureSecondaryFile = config.userResourcesCacheSignatureSecondaryFile;
        userResourcesDiffCacheFile = config.userResourcesDiffCacheFile;
        userResourcesDiffCacheSignatureFile = config.userResourcesDiffCacheSignatureFile;
        installTimeCacheFile = config.installTimeCacheFile;
        installTimeCacheSecondaryFile = config.installTimeCacheSecondaryFile;
        appVersion = config.appVersion;
        receiptProvider = config.receiptProvider;
        autoDownloadCampaignsAndResources = config.autoDownloadCampaignsAndResources;
        talkEnabled = config.talkEnabled;
        defaultBackgroundColor = config.defaultBackgroundColor;
        conversationLightBoxColor = config.conversationLightBoxColor;
        newSessionInterval = config.newSessionInterval;
        resourcesUpdatedCallback = config.resourcesUpdatedCallback;
        autoSendEventsOnResume = config.autoSendEventsOnResume;
        autoSaveEventsOnResign = config.autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
        pushEnabled = config.pushEnabled;
        pushNotificationEvents = config.pushNotificationEvents;
        autoCollectDeviceToken = config.autoCollectDeviceToken;
        pushCategories = config.pushCategories;
#endif //!defined(SWRVE_NO_PUSH)
        autoShowMessagesMaxDelay = config.autoShowMessagesMaxDelay;
        selectedStack = config.selectedStack;
    }
    
    return self;
}

@end
