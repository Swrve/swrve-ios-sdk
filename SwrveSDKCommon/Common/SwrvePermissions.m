#import "SwrvePermissions.h"
#import "ISHPermissionRequest+All.h"
#import "ISHPermissionRequestNotificationsRemote.h"
#if !defined(SWRVE_NO_PUSH)
#import "SwrvePushInternalAccess.h"
#import <UserNotifications/UserNotifications.h>
#endif //!defined(SWRVE_NO_PUSH)

#if defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
static ISHPermissionRequest *_locationAlwaysRequest = nil;
static ISHPermissionRequest *_locationWhenInUseRequest = nil;
#endif //defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
#if defined(SWRVE_PHOTO_LIBRARY)
static ISHPermissionRequest *_photoLibraryRequest = nil;
#endif //defined(SWRVE_PHOTO_LIBRARY)
#if defined(SWRVE_PHOTO_CAMERA)
static ISHPermissionRequest *_cameraRequest = nil;
#endif //defined(SWRVE_PHOTO_CAMERA)
#if defined(SWRVE_ADDRESS_BOOK)
static ISHPermissionRequest *_contactsRequest = nil;
#endif //defined(SWRVE_ADDRESS_BOOK)
#if !defined(SWRVE_NO_PUSH)
static ISHPermissionRequest *_remoteNotifications = nil;
#endif //!defined(SWRVE_NO_PUSH)

static NSString* asked_for_push_flag_key = @"swrve.asked_for_push_permission";

@implementation SwrvePermissions

+ (NSMutableDictionary*)permissionsStatusCache {
    static NSMutableDictionary *dic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dic = [NSMutableDictionary new];
    });
    return dic;
}

+(BOOL) processPermissionRequest:(NSString*)action withSDK:(id<SwrveCommonDelegate>)sdk {
#if !defined(SWRVE_NO_PUSH)
    if([action caseInsensitiveCompare:@"swrve.request_permission.ios.push_notifications"] == NSOrderedSame) {
        [SwrvePermissions requestPushNotifications:sdk withCallback:YES];
        return YES;
    }
#else
#pragma unused(sdk)
#endif //!defined(SWRVE_NO_PUSH)
#if defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
    if([action caseInsensitiveCompare:@"swrve.request_permission.ios.location.always"] == NSOrderedSame) {
        [SwrvePermissions requestLocationAlways:sdk];
        return YES;
    }
    else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.location.when_in_use"] == NSOrderedSame) {
        [SwrvePermissions requestLocationWhenInUse:sdk];
        return YES;
    }
#endif //defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
#if defined(SWRVE_ADDRESS_BOOK)
    if([action caseInsensitiveCompare:@"swrve.request_permission.ios.contacts"] == NSOrderedSame) {
        [SwrvePermissions requestContacts:sdk];
        return YES;
    }
#endif //defined(SWRVE_ADDRESS_BOOK)
#if defined(SWRVE_PHOTO_LIBRARY)
    if([action caseInsensitiveCompare:@"swrve.request_permission.ios.photos"] == NSOrderedSame) {
        [SwrvePermissions requestPhotoLibrary:sdk];
        return YES;
    }
#endif //defined(SWRVE_PHOTO_LIBRARY)
#if defined(SWRVE_PHOTO_CAMERA)
    if([action caseInsensitiveCompare:@"swrve.request_permission.ios.camera"] == NSOrderedSame) {
        [SwrvePermissions requestCamera:sdk];
        return YES;
    }
#endif //defined(SWRVE_PHOTO_CAMERA)
    return NO;
}

+(NSDictionary*)currentStatusWithSDK:(id<SwrveCommonDelegate>)sdk {
    NSMutableDictionary* permissionsStatus = [[NSMutableDictionary alloc] init];
#if defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkLocationAlways]) forKey:swrve_permission_location_always];
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkLocationWhenInUse]) forKey:swrve_permission_location_when_in_use];
#endif //defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
#if defined(SWRVE_PHOTO_LIBRARY)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkPhotoLibrary]) forKey:swrve_permission_photos];
#endif //defined(SWRVE_PHOTO_LIBRARY)
#if defined(SWRVE_PHOTO_CAMERA)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkCamera]) forKey:swrve_permission_camera];
#endif //defined(SWRVE_PHOTO_CAMERA)
#if defined(SWRVE_ADDRESS_BOOK)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkContacts]) forKey:swrve_permission_contacts];
#endif //defined(SWRVE_ADDRESS_BOOK)
#if !defined(SWRVE_NO_PUSH)
    NSString *pushAuthorization = [SwrvePermissions pushAuthorizationWithSDK:sdk];
    if (pushAuthorization) {
        [permissionsStatus setValue:pushAuthorization forKey:swrve_permission_push_notifications];
    }
    [SwrvePermissions bgRefreshStatusToDictionary: permissionsStatus];
#else
#pragma unused(sdk)
#endif //!defined(SWRVE_NO_PUSH)

    [SwrvePermissions updatePermissionsStatusCache:permissionsStatus];

    return permissionsStatus;
}

+ (void)updatePermissionsStatusCache:(NSMutableDictionary *)permissionsStatus {
    NSMutableDictionary * permissionsStatusCache = [SwrvePermissions permissionsStatusCache];

    @synchronized (permissionsStatusCache) {
        [permissionsStatusCache addEntriesFromDictionary:permissionsStatus];
    }
}

#if !defined(SWRVE_NO_PUSH)
+ (NSString*) pushAuthorizationWithSDK: (id<SwrveCommonDelegate>)sdk {
    NSString *pushAuthorization = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {

            NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
            NSString *pushAuthorizationFromSettings = swrve_permission_status_unknown;
            if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                pushAuthorizationFromSettings = swrve_permission_status_authorized;
            } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                pushAuthorizationFromSettings = swrve_permission_status_denied;
            } else if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                pushAuthorizationFromSettings = swrve_permission_status_unknown;
            }
            [dictionary setValue:pushAuthorizationFromSettings forKey:swrve_permission_push_notifications];
            [sdk userUpdate:dictionary]; // send now

            [SwrvePermissions updatePermissionsStatusCache:dictionary];
        }];
    } else {

        UIUserNotificationType uiUserNotificationType = [[[SwrveCommon sharedUIApplication] currentUserNotificationSettings] types];
        if (uiUserNotificationType  & UIUserNotificationTypeAlert){
            // best guess is that user can receive notifications. No api available for lockscreen and notification center
            pushAuthorization = swrve_permission_status_authorized;
        } else {
            pushAuthorization = swrve_permission_status_denied;
        }
    }
    return pushAuthorization;
}

+ (void)bgRefreshStatusToDictionary:(NSMutableDictionary *)permissionsStatus {
    NSString *backgroundRefreshStatus = swrve_permission_status_unknown;
    UIBackgroundRefreshStatus uiBackgroundRefreshStatus = [[SwrveCommon sharedUIApplication] backgroundRefreshStatus];
    if (uiBackgroundRefreshStatus == UIBackgroundRefreshStatusAvailable) {
        backgroundRefreshStatus = swrve_permission_status_authorized;
    } else if (uiBackgroundRefreshStatus == UIBackgroundRefreshStatusDenied) {
        backgroundRefreshStatus = swrve_permission_status_denied;
    } else if (uiBackgroundRefreshStatus == UIBackgroundRefreshStatusRestricted) {
        backgroundRefreshStatus = swrve_permission_status_unknown;
    }
    [permissionsStatus setValue:backgroundRefreshStatus forKey:swrve_permission_push_bg_refresh];
}

#endif //!defined(SWRVE_NO_PUSH)

+(void)compareStatusAndQueueEventsWithSDK:(id<SwrveCommonDelegate>)sdk {
    NSDictionary* lastStatus = [[NSUserDefaults standardUserDefaults] dictionaryForKey:swrve_permission_status];
    NSDictionary* currentStatus = [self currentStatusWithSDK:sdk];
    if (lastStatus != nil) {
        [self compareStatusAndQueueEvent:swrve_permission_location_always lastStatus:lastStatus currentStatus:currentStatus withSDK:sdk];
        [self compareStatusAndQueueEvent:swrve_permission_location_when_in_use lastStatus:lastStatus currentStatus:currentStatus withSDK:sdk];
        [self compareStatusAndQueueEvent:swrve_permission_photos lastStatus:lastStatus currentStatus:currentStatus withSDK:sdk];
        [self compareStatusAndQueueEvent:swrve_permission_camera lastStatus:lastStatus currentStatus:currentStatus withSDK:sdk];
        [self compareStatusAndQueueEvent:swrve_permission_contacts lastStatus:lastStatus currentStatus:currentStatus withSDK:sdk];
        [self compareStatusAndQueueEvent:swrve_permission_push_notifications lastStatus:lastStatus currentStatus:currentStatus withSDK:sdk];
    }
    [[NSUserDefaults standardUserDefaults] setObject:currentStatus forKey:swrve_permission_status];
}

+(NSArray*)currentPermissionFilters {

    NSMutableArray* filters = [[NSMutableArray alloc] init];
    NSMutableDictionary * permissionsStatusCache = [SwrvePermissions permissionsStatusCache];
    if(permissionsStatusCache == nil) {
        return filters;
    }
    @synchronized (permissionsStatusCache) {
        [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_location_always to:filters withCurrentStatus:permissionsStatusCache];
        [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_location_when_in_use to:filters withCurrentStatus:permissionsStatusCache];
        [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_photos to:filters withCurrentStatus:permissionsStatusCache];
        [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_camera to:filters withCurrentStatus:permissionsStatusCache];
        [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_contacts to:filters withCurrentStatus:permissionsStatusCache];

        // Check that we haven't already asked for push permissions
        if (![SwrvePermissions didWeAskForPushPermissionsAlready]) {
            NSString *currentPushPermission = [permissionsStatusCache objectForKey:swrve_permission_push_notifications];
            NSString *acceptedStatus = swrve_permission_status_denied;
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
                acceptedStatus = swrve_permission_status_unknown;
            }

            if ([currentPushPermission isEqualToString:acceptedStatus]) {
                [filters addObject:[[swrve_permission_push_notifications lowercaseString] stringByAppendingString:swrve_permission_requestable]];
            }
        }
    }
    return filters;
}

+(BOOL)didWeAskForPushPermissionsAlready {
    return [[NSUserDefaults standardUserDefaults] boolForKey:asked_for_push_flag_key];
}

+(void)checkPermissionNameAndAddFilters:(NSString*)permissionName to:(NSMutableArray*)filters withCurrentStatus:(NSDictionary*)currentStatus {

    if(currentStatus == nil){
        return;
    }

    if ([[currentStatus objectForKey:permissionName] isEqualToString:swrve_permission_status_unknown]) {
        [filters addObject:[[permissionName lowercaseString] stringByAppendingString:swrve_permission_requestable]];
    }
}

+(void)compareStatusAndQueueEvent:(NSString*)permissioName lastStatus:(NSDictionary*)lastStatus currentStatus:(NSDictionary*)currentStatus withSDK:(id<SwrveCommonDelegate>)sdk {
    NSString* lastStatusString = [lastStatus objectForKey:permissioName];
    NSString* currentStatusString = [currentStatus objectForKey:permissioName];
    if (![lastStatusString isEqualToString:swrve_permission_status_authorized] && [currentStatusString isEqualToString:swrve_permission_status_authorized]) {
        // Send event as the permission has been granted
        [SwrvePermissions sendPermissionEvent:permissioName withState:ISHPermissionStateAuthorized withSDK:sdk];
    } else if (![lastStatusString isEqualToString:swrve_permission_status_denied] && [currentStatusString isEqualToString:swrve_permission_status_denied]) {
        // Send event as the permission has been denied
        [SwrvePermissions sendPermissionEvent:permissioName withState:ISHPermissionStateDenied withSDK:sdk];
    }
}

#if defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
+(ISHPermissionRequest*)locationAlwaysRequest {
    if (!_locationAlwaysRequest) {
        _locationAlwaysRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryLocationAlways];
    }
    return _locationAlwaysRequest;
}

+(ISHPermissionState)checkLocationAlways {
    ISHPermissionRequest *r = [SwrvePermissions locationAlwaysRequest];
    return [r permissionState];
}

+(void)requestLocationAlways:(id<SwrveCommonDelegate>)sdk {
    ISHPermissionRequest *r = [SwrvePermissions locationAlwaysRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}

+(ISHPermissionRequest*)locationWhenInUseRequest {
    if (!_locationWhenInUseRequest) {
        _locationWhenInUseRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryLocationWhenInUse];
    }
    return _locationWhenInUseRequest;
}

+(ISHPermissionState)checkLocationWhenInUse {
    ISHPermissionRequest *r = [SwrvePermissions locationWhenInUseRequest];
    return [r permissionState];
}

+(void)requestLocationWhenInUse:(id<SwrveCommonDelegate>)sdk {
    ISHPermissionRequest *r = [SwrvePermissions locationWhenInUseRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}
#endif //defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)

#if defined(SWRVE_PHOTO_LIBRARY)
+(ISHPermissionRequest*)photoLibraryRequest {
    if (!_photoLibraryRequest) {
        _photoLibraryRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryPhotoLibrary];
    }
    return _photoLibraryRequest;
}

+(ISHPermissionState)checkPhotoLibrary {
    ISHPermissionRequest *r = [SwrvePermissions photoLibraryRequest];
    return [r permissionState];
}

+(void)requestPhotoLibrary:(id<SwrveCommonDelegate>)sdk {
    ISHPermissionRequest *r = [SwrvePermissions photoLibraryRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}
#endif //defined(SWRVE_PHOTO_LIBRARY)

#if defined(SWRVE_PHOTO_CAMERA)
+(ISHPermissionRequest*)cameraRequest {
    if (!_cameraRequest) {
        _cameraRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryPhotoCamera];
    }
    return _cameraRequest;
}

+(ISHPermissionState)checkCamera {
    ISHPermissionRequest *r = [SwrvePermissions cameraRequest];
    return [r permissionState];
}

+(void)requestCamera:(id<SwrveCommonDelegate>)sdk {
    ISHPermissionRequest *r = [SwrvePermissions cameraRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}
#endif //defined(SWRVE_PHOTO_CAMERA)

#if defined(SWRVE_ADDRESS_BOOK)
+(ISHPermissionRequest*)contactsRequest {
    if (!_contactsRequest) {
        _contactsRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryAddressBook];
    }
    return _contactsRequest;
}

+(ISHPermissionState)checkContacts {
    ISHPermissionRequest *r = [SwrvePermissions contactsRequest];
    return [r permissionState];
}

+(void)requestContacts:(id<SwrveCommonDelegate>)sdk {
    ISHPermissionRequest *r = [SwrvePermissions contactsRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}
#endif //defined(SWRVE_ADDRESS_BOOK)

#if !defined(SWRVE_NO_PUSH)
+(ISHPermissionRequest*)pushNotificationsRequest {
    if (!_remoteNotifications) {
        _remoteNotifications = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryNotificationRemote];
    }
    return _remoteNotifications;
}

+ (ISHPermissionState)checkPushNotificationsWithSDK:(id<SwrveCommonDelegate>)sdk {
    NSString* deviceToken = sdk.deviceToken;
    if (deviceToken != nil && deviceToken.length > 0) {
        // We have a token, at some point the user said yes. We still have to check
        // that the user hasn't disabled push notifications in the settings.
        __block bool pushSettingsEnabled = YES;

        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                [SwrvePermissions updatePushNotificationSettingsStatus:settings andSDK:sdk];
            }];
        }

        UIApplication* app = [SwrveCommon sharedUIApplication];
        if (pushSettingsEnabled && [app respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
            pushSettingsEnabled = [app isRegisteredForRemoteNotifications];
        }

        if (pushSettingsEnabled) {
            return ISHPermissionStateAuthorized;
        } else {
            return ISHPermissionStateDenied;
        }
    }
    return ISHPermissionStateUnknown;
}


+ (void) updatePushNotificationSettingsStatus:(UNNotificationSettings *)settings andSDK:(id<SwrveCommonDelegate>)sdk {
    NSMutableDictionary* pushPermissionsStatus = [[NSMutableDictionary alloc] init];
    ISHPermissionState permissionState = ISHPermissionStateUnknown;

    if (settings.alertSetting == UNNotificationSettingEnabled) {
        permissionState = ISHPermissionStateAuthorized;
    } else {
        permissionState = ISHPermissionStateDenied;
    }

    [pushPermissionsStatus setValue:stringFromPermissionState(permissionState) forKey:swrve_permission_push_notifications];
    [sdk userUpdate:pushPermissionsStatus];
}

+(void)requestPushNotifications:(id<SwrveCommonDelegate>)sdk withCallback:(BOOL)callback {
    ISHPermissionRequest *r = [SwrvePermissions pushNotificationsRequest];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        ((ISHPermissionRequestNotificationsRemote*)r).notificationAuthOptions = (UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge);
        ((ISHPermissionRequestNotificationsRemote*)r).notificationCategories = sdk.notificationCategories;
    }

    ((ISHPermissionRequestNotificationsRemote*)r).notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:sdk.pushCategories];

    if (callback) {
        [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
            // Either the user responded or we can't request again
            [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
        }];
    } else {
        [(ISHPermissionRequestNotificationsRemote*)r requestUserPermissionWithoutCompleteBlock];
    }

    // Remember we asked for push permissions
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:asked_for_push_flag_key];
}
#endif //!defined(SWRVE_NO_PUSH)

+(void)sendPermissionEvent:(NSString*)eventName withState:(ISHPermissionState)state withSDK:(id<SwrveCommonDelegate>)sdk {
    NSString *eventNameWithState = [eventName stringByAppendingString:((state == ISHPermissionStateAuthorized)? @".on" : @".off")];
    [sdk eventInternal:eventNameWithState payload:nil triggerCallback:false];
}

@end
