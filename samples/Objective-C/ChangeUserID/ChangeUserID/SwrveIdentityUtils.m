//  A utility to manage user identity with the Swrve SDK. This utility gives you the ability
//  to (a) initialize Swrve if you don't have a user ID yet (i.e. first session or before the
//  user has logged in), set the identity of the user once you have it and (c) change the
//  identity in case the user logs out an another logs in.

#import "SwrveIdentityUtils.h"
#import "SwrveFileManagement.h"
#import <UIKit/UIKit.h>

@interface SwrveIdentityUtils()
- (void) appendUserIDToCacheFiles;
@end

@implementation SwrveIdentityUtils {

int _appID;
NSString * _apiKey;
SwrveConfig * _config;
NSString* _eventsUrl;
NSString* _contentUrl;
    
}

//  Call this method to initialize the Swrve SDK.  After you call this method you no longer
//  need to call SwrveSDK.createInstance.  You must call this method before you can call
//  changeUserID.
- (void) createSDKInstance:(int) appID apiKey:(NSString*)apiKey config:(SwrveConfig*)config userID:(NSString*) userID launchOptions:(NSDictionary*) launchOptions
{
    _appID = appID;
    _apiKey = apiKey;
    _config = config;
    _eventsUrl = _config.eventsServer;
    _contentUrl = _config.contentServer;
    
//  Method Swizzling must be turned off for this solution to work. For instructions on how to
//  do this go to the "Disabling Push Notification Method Swizzling" section of our iOS
//  implementation guide: https://docs.swrve.com/developer-documentation/integration/ios#Push_Notifications
    if( config.pushEnabled == YES && config.autoCollectDeviceToken == YES ) {
        NSException* myException = [NSException
                                    exceptionWithName:@"SwrveIdentityUtilsException"
                                    reason:@"You must disable method swizzling for this solution to work. Please see our documentation on disabling method swizzling."
                                    userInfo:nil];
        @throw myException;
    }
    
    [self initializeSDK:userID launchOptions:launchOptions];
}

//  Call this method to change the user ID referenced in the Swrve SDK. Calling this method
//  will do several things.  First it will attempt to send all events for the current user
//  to Swrve's servers.  If this fails the events will be saved to disk and be sent the next
//  time the Swrve SDK is initialized with the user ID.  Next, the Swrve SDK will be shut down
//  and it will detach from the current ActivityContext.  As a result, in-app messages or
//  conversations will be dismissed.  Next, the Swrve SDK will be re-initialized and it will
//  reattach itself to the activity provided.
- (void) changeUserID:(NSString *) userID {
    [self initializeSDK:userID launchOptions:nil];
}

- (void) initializeSDK:(NSString*) userID launchOptions:(NSDictionary*) launchOptions

{
    // Destory old instance, if it exists
    if( [Swrve sharedInstance] != nil )
    {
        // Session has ended for the current user
        NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
        [[Swrve sharedInstance] queueEvent:@"session_end" data:json triggerCallback:false];
        
        // Save events to disk.
        [[Swrve sharedInstance] saveEventsToDisk];
        
        // Try to send the events to Swrves servers.  If this fails the events won't be sent
        // until the SDK is initialized with the old user's ID again.
        [[Swrve sharedInstance] sendQueuedEvents];
        
        // Shutdown the SDK
        [[Swrve class] performSelector:@selector(resetSwrveSharedInstance)];
    }
    
    // Add the user id to the name of the local DB for the SDK.  This will 'namespace'
    // all of the events raised and content to the user ID.
    _config.userId = (userID == nil) ? @"invalid_user_id" : userID;
    [self appendUserIDToCacheFiles];
    
    
    // Don't send any data to Swrve servers if userID is nil
    if(userID == nil){
        _config.eventsServer = @"";
        _config.contentServer = @"";
    } else {
        _config.eventsServer = _eventsUrl;
        _config.contentServer = _contentUrl;
    }
    
    // Initialize the sdk
    [Swrve sharedInstanceWithAppID:_appID apiKey:_apiKey config:_config launchOptions:launchOptions];
}

//  Call this method to append the correct user_id to the cache files.  This will ensure
//  that events which can't be sent for a user are saved. They will be sent the next time
//  the user logs on to the device
- (void) appendUserIDToCacheFiles
{
    NSString* caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* applicationSupport = [SwrveFileManagement applicationSupportPath];
    
    _config.eventCacheFile = [applicationSupport stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"swrve_events.txt", nil] componentsJoinedByString:@"."]];
    _config.eventCacheSecondaryFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"swrve_events.txt", nil] componentsJoinedByString:@"."]];
    _config.locationCampaignCacheFile = [applicationSupport stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"lc.txt", nil] componentsJoinedByString:@"."]];
    _config.locationCampaignCacheSecondaryFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"lc.txt", nil] componentsJoinedByString:@"."]];
    _config.locationCampaignCacheSignatureFile = [applicationSupport stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"lcsgt.txt", nil] componentsJoinedByString:@"."]];
    _config.locationCampaignCacheSignatureSecondaryFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"lcsgt.txt", nil] componentsJoinedByString:@"."]];
    _config.userResourcesCacheFile = [applicationSupport stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"srcngt2.txt", nil] componentsJoinedByString:@"."]];
    _config.userResourcesCacheSecondaryFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"srcngt2.txt", nil] componentsJoinedByString:@"."]];
    _config.userResourcesCacheSignatureFile = [applicationSupport stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"srcngtsgt2.txt", nil] componentsJoinedByString:@"."]];
    _config.userResourcesCacheSignatureSecondaryFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"srcngtsgt2.txt", nil] componentsJoinedByString:@"."]];
    _config.userResourcesDiffCacheFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"rsdfngtsgt2.txt", nil] componentsJoinedByString:@"."]];
    _config.userResourcesDiffCacheSignatureFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"rsdfngtsgt2.txt", nil] componentsJoinedByString:@"."]];
    _config.installTimeCacheFile = [documents stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"swrve_install.txt", nil] componentsJoinedByString:@"."]];
    _config.installTimeCacheSecondaryFile = [caches stringByAppendingPathComponent: [[NSArray arrayWithObjects:_config.userId, @"swrve_install.txt", nil] componentsJoinedByString:@"."]];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
}
@end
