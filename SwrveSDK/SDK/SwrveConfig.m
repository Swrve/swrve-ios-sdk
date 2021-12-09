#import "SwrveConfig.h"

@implementation SwrveConfig

@synthesize orientation;
@synthesize prefersConversationsStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize contentServer;
@synthesize identityServer;
@synthesize language;
@synthesize appVersion;
@synthesize autoDownloadCampaignsAndResources;
@synthesize inAppMessageConfig;
@synthesize embeddedMessageConfig;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if TARGET_OS_IOS
@synthesize pushEnabled;
@synthesize provisionalPushNotificationEvents;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize notificationCategories;
@synthesize pushResponseDelegate;
#endif //TARGET_OS_IOS
@synthesize appGroupIdentifier;
@synthesize autoShowMessagesMaxDelay;
@synthesize stack;
@synthesize initMode;
@synthesize autoStartLastUser;
@synthesize abTestDetailsEnabled;
@synthesize permissionsDelegate;
@synthesize deeplinkDelegate;
@synthesize autoCollectIDFV;
@synthesize urlSessionDelegate;


-(id) init
{
    if ( self = [super init] ) {
        httpTimeoutSeconds = 60;
        autoDownloadCampaignsAndResources = YES;
        orientation = SWRVE_ORIENTATION_BOTH;
        prefersConversationsStatusBarHidden = NO;
        language = [[NSLocale preferredLanguages] objectAtIndex:0];
        newSessionInterval = 30;
        
        self.autoSendEventsOnResume = YES;
        self.autoSaveEventsOnResign = YES;
#if TARGET_OS_IOS
        self.pushEnabled = NO;
        self.provisionalPushNotificationEvents = nil;
        self.pushNotificationEvents = [NSSet setWithObject:@"Swrve.session.start"];
        self.autoCollectDeviceToken = YES;
#endif //TARGET_OS_IOS
        self.autoShowMessagesMaxDelay = 5000;
        self.resourcesUpdatedCallback = ^() {
            // Do nothing by default.
        };
        self.stack = SWRVE_STACK_US;
        self.initMode = SWRVE_INIT_MODE_AUTO;
        self.autoStartLastUser = true;
        self.inAppMessageConfig = [SwrveInAppMessageConfig new];
        self.embeddedMessageConfig = [SwrveEmbeddedMessageConfig new];
        self.autoCollectIDFV = NO;
    }
    return self;
}

@end

@implementation ImmutableSwrveConfig

@synthesize orientation;
@synthesize prefersConversationsStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize contentServer;
@synthesize identityServer;
@synthesize language;
@synthesize appVersion;
@synthesize autoDownloadCampaignsAndResources;
@synthesize inAppMessageConfig;
@synthesize embeddedMessageConfig;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if TARGET_OS_IOS
@synthesize pushEnabled;
@synthesize provisionalPushNotificationEvents;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize notificationCategories;
@synthesize pushResponseDelegate;
#endif //TARGET_OS_IOS
@synthesize appGroupIdentifier;
@synthesize autoShowMessagesMaxDelay;
@synthesize stack;
@synthesize initMode;
@synthesize autoStartLastUser;
@synthesize abTestDetailsEnabled;
@synthesize permissionsDelegate;
@synthesize deeplinkDelegate;
@synthesize autoCollectIDFV;
@synthesize urlSessionDelegate;

- (id)initWithMutableConfig:(SwrveConfig*)config
{
    if (self = [super init]) {
        orientation = config.orientation;
        prefersConversationsStatusBarHidden = config.prefersConversationsStatusBarHidden;
        httpTimeoutSeconds = config.httpTimeoutSeconds;
        eventsServer = config.eventsServer;
        contentServer = config.contentServer;
        identityServer = config.identityServer;
        language = config.language;
        appVersion = config.appVersion;
        autoDownloadCampaignsAndResources = config.autoDownloadCampaignsAndResources;
        inAppMessageConfig = config.inAppMessageConfig;
        embeddedMessageConfig = config.embeddedMessageConfig;
        newSessionInterval = config.newSessionInterval;
        resourcesUpdatedCallback = config.resourcesUpdatedCallback;
        autoSendEventsOnResume = config.autoSendEventsOnResume;
        autoSaveEventsOnResign = config.autoSaveEventsOnResign;
#if TARGET_OS_IOS
        pushEnabled = config.pushEnabled;
        provisionalPushNotificationEvents = config.provisionalPushNotificationEvents;
        pushNotificationEvents = config.pushNotificationEvents;
        autoCollectDeviceToken = config.autoCollectDeviceToken;
        notificationCategories = config.notificationCategories;
        pushResponseDelegate = config.pushResponseDelegate;
#endif //TARGET_OS_IOS
        appGroupIdentifier = config.appGroupIdentifier;
        autoShowMessagesMaxDelay = config.autoShowMessagesMaxDelay;
        stack = config.stack;
        initMode = config.initMode;
        autoStartLastUser = config.autoStartLastUser;
        abTestDetailsEnabled = config.abTestDetailsEnabled;
        permissionsDelegate = config.permissionsDelegate;
        deeplinkDelegate = config.deeplinkDelegate;
        autoCollectIDFV = config.autoCollectIDFV;
        urlSessionDelegate = config.urlSessionDelegate;
    }

    return self;
}

@end
