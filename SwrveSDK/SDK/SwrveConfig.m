#import "SwrveConfig.h"

@implementation SwrveConfig

@synthesize userId;
@synthesize orientation;
@synthesize prefersIAMStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize contentServer;
@synthesize language;
@synthesize appVersion;
@synthesize autoDownloadCampaignsAndResources;
@synthesize inAppMessageBackgroundColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
@synthesize notificationCategories;
@synthesize pushResponseDelegate;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize appGroupIdentifier;
@synthesize autoShowMessagesMaxDelay;
@synthesize stack;
@synthesize abTestDetailsEnabled;

-(id) init
{
    if ( self = [super init] ) {
        httpTimeoutSeconds = 60;
        autoDownloadCampaignsAndResources = YES;
        orientation = SWRVE_ORIENTATION_BOTH;
        prefersIAMStatusBarHidden = YES;
        language = [[NSLocale preferredLanguages] objectAtIndex:0];
        newSessionInterval = 30;

        self.autoSendEventsOnResume = YES;
        self.autoSaveEventsOnResign = YES;
#if !defined(SWRVE_NO_PUSH)
        self.pushEnabled = NO;
        self.pushNotificationEvents = [NSSet setWithObject:@"Swrve.session.start"];
        self.autoCollectDeviceToken = YES;
#endif //!defined(SWRVE_NO_PUSH)
        self.autoShowMessagesMaxDelay = 5000;
        self.resourcesUpdatedCallback = ^() {
            // Do nothing by default.
        };
        self.stack = SWRVE_STACK_US;
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
@synthesize contentServer;
@synthesize language;
@synthesize appVersion;
@synthesize autoDownloadCampaignsAndResources;
@synthesize inAppMessageBackgroundColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
@synthesize notificationCategories;
@synthesize pushResponseDelegate;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize appGroupIdentifier;
@synthesize autoShowMessagesMaxDelay;
@synthesize stack;
@synthesize abTestDetailsEnabled;

- (id)initWithMutableConfig:(SwrveConfig*)config
{
    if (self = [super init]) {
        userId = config.userId;
        orientation = config.orientation;
        prefersIAMStatusBarHidden = config.prefersIAMStatusBarHidden;
        httpTimeoutSeconds = config.httpTimeoutSeconds;
        eventsServer = config.eventsServer;
        contentServer = config.contentServer;
        language = config.language;
        appVersion = config.appVersion;
        autoDownloadCampaignsAndResources = config.autoDownloadCampaignsAndResources;
        inAppMessageBackgroundColor = config.inAppMessageBackgroundColor;
        newSessionInterval = config.newSessionInterval;
        resourcesUpdatedCallback = config.resourcesUpdatedCallback;
        autoSendEventsOnResume = config.autoSendEventsOnResume;
        autoSaveEventsOnResign = config.autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
        pushEnabled = config.pushEnabled;
        pushNotificationEvents = config.pushNotificationEvents;
        autoCollectDeviceToken = config.autoCollectDeviceToken;
        pushCategories = config.pushCategories;
        notificationCategories = config.notificationCategories;
        pushResponseDelegate = config.pushResponseDelegate;
#endif //!defined(SWRVE_NO_PUSH)
        appGroupIdentifier = config.appGroupIdentifier;
        autoShowMessagesMaxDelay = config.autoShowMessagesMaxDelay;
        stack = config.stack;
        abTestDetailsEnabled = config.abTestDetailsEnabled;
    }

    return self;
}

@end
