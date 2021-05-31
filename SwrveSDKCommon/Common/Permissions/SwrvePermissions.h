#import <Foundation/Foundation.h>
#import "SwrveCommon.h"
#import "SwrvePermissionState.h"
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN
static NSString* swrve_permission_status_unknown        = @"unknown";
static NSString* swrve_permission_status_unsupported    = @"unsupported";
static NSString* swrve_permission_status_denied         = @"denied";
static NSString* swrve_permission_status_authorized     = @"authorized";
static NSString* swrve_permission_status_provisional    = @"provisional";

static NSString* swrve_permission_location_always       = @"Swrve.permission.ios.location.always";
static NSString* swrve_permission_location_when_in_use  = @"Swrve.permission.ios.location.when_in_use";
static NSString* swrve_permission_photos                = @"Swrve.permission.ios.photos";
static NSString* swrve_permission_camera                = @"Swrve.permission.ios.camera";
static NSString* swrve_permission_contacts              = @"Swrve.permission.ios.contacts";
static NSString* swrve_permission_push_notifications    = @"Swrve.permission.ios.push_notifications";
static NSString* swrve_permission_push_bg_refresh       = @"Swrve.permission.ios.push_bg_refresh";

// all new device props should be lowercase s, do not change the ones above.
static NSString* swrve_permission_ad_tracking           = @"swrve.permission.ios.ad_tracking";

static NSString* swrve_permission_requestable           = @".requestable";

/*! Used internally to offer permission request support */
@interface SwrvePermissions : NSObject

+ (BOOL)didWeAskForPushPermissionsAlready;
+ (BOOL)processPermissionRequest:(NSString*)action withSDK:(id<SwrveCommonDelegate>)sdk;
+ (NSDictionary*) currentStatusWithSDK:(id<SwrveCommonDelegate>)sdk;
+ (void)compareStatusAndQueueEventsWithSDK:(id<SwrveCommonDelegate>)sdk;
+ (NSArray*) currentPermissionFilters;

+ (SwrvePermissionState)checkLocationAlways:(id<SwrveCommonDelegate>)sdk;
+ (BOOL)requestLocationAlways:(id<SwrveCommonDelegate>)sdk;

+ (SwrvePermissionState)checkPhotoLibrary:(id<SwrveCommonDelegate>)sdk;
+ (BOOL)requestPhotoLibrary:(id<SwrveCommonDelegate>)sdk;

+ (SwrvePermissionState)checkCamera:(id<SwrveCommonDelegate>)sdk;
+ (BOOL)requestCamera:(id<SwrveCommonDelegate>)sdk;

+ (SwrvePermissionState)checkContacts:(id<SwrveCommonDelegate>)sdk;
+ (BOOL)requestContacts:(id<SwrveCommonDelegate>)sdk;

+ (SwrvePermissionState)checkAdTracking:(id<SwrveCommonDelegate>)sdk;
+ (BOOL)requestAdTracking:(id<SwrveCommonDelegate>)sdk;

#if TARGET_OS_IOS
+ (void)requestPushNotifications:(id<SwrveCommonDelegate>)sdk provisional:(BOOL)provisional;
+ (NSString*)pushAuthorizationWithSDK: (id<SwrveCommonDelegate>)sdk;
+ (NSString*)pushAuthorizationWithSDK: (id<SwrveCommonDelegate>)sdk WithCallback:(nullable void (^)(NSString * pushAuthorization)) callback;
+ (void)registerForRemoteNotifications:(UNAuthorizationOptions)notificationAuthOptions withCategories:(NSSet<UNNotificationCategory *> *)notificationCategories andSDK:(nullable id<SwrveCommonDelegate>)sdk NS_AVAILABLE_IOS(10.0);
+ (void)refreshDeviceToken:(nullable id<SwrveCommonDelegate>)sdk;
#endif //TARGET_OS_IOS

@end

static inline NSString * _Nullable stringFromPermissionState(SwrvePermissionState state) {
    switch (state) {
        case SwrvePermissionStateUnknown:
            return swrve_permission_status_unknown;
        case SwrvePermissionStateUnsupported:
            return swrve_permission_status_unsupported;
        case SwrvePermissionStateDenied:
            return swrve_permission_status_denied;
        case SwrvePermissionStateAuthorized:
            return swrve_permission_status_authorized;
        default:
            return nil;
    }
}
NS_ASSUME_NONNULL_END
