#import "SwrvePermissions.h"
#import "ISHPermissionRequest+All.h"
#import "ISHPermissionRequestNotificationsRemote.h"
#import "SwrveInternalAccess.h"

static ISHPermissionRequest *_locationAlwaysRequest = nil;
static ISHPermissionRequest *_locationWhenInUseRequest = nil;
#if !defined(SWRVE_NO_PHOTO_LIBRARY)
static ISHPermissionRequest *_photoLibraryRequest = nil;
#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)
static ISHPermissionRequest *_cameraRequest = nil;
#if !defined(SWRVE_NO_ADDRESS_BOOK)
static ISHPermissionRequest *_contactsRequest = nil;
#endif //!defined(SWRVE_NO_ADDRESS_BOOK)
static ISHPermissionRequest *_remoteNotifications = nil;

static NSString* asked_for_push_flag_key = @"swrve.asked_for_push_permission";

@implementation SwrvePermissions

+(BOOL) processPermissionRequest:(NSString*)action withSDK:(Swrve*)sdk {
    if([action caseInsensitiveCompare:@"swrve.request_permission.ios.push_notifications"] == NSOrderedSame) {
        [SwrvePermissions requestPushNotifications:sdk withCallback:YES];
        return YES;
    }
#if !defined(SWRVE_NO_LOCATION)
    else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.location.always"] == NSOrderedSame) {
        [SwrvePermissions requestLocationAlways:sdk];
        return YES;
    }
    else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.location.when_in_use"] == NSOrderedSame) {
        [SwrvePermissions requestLocationWhenInUse:sdk];
        return YES;
    }
#endif //!defined(SWRVE_NO_LOCATION)
#if !defined(SWRVE_NO_ADDRESS_BOOK)
    else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.contacts"] == NSOrderedSame) {
        [SwrvePermissions requestContacts:sdk];
        return YES;
    }
#endif //!defined(SWRVE_NO_ADDRESS_BOOK)
#if !defined(SWRVE_NO_PHOTO_LIBRARY)
    else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.photos"] == NSOrderedSame) {
        [SwrvePermissions requestPhotoLibrary:sdk];
        return YES;
    }
#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)
    else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.camera"] == NSOrderedSame) {
        [SwrvePermissions requestCamera:sdk];
        return YES;
    }
    
    return NO;
}

+(NSDictionary*)currentStatusWithSDK:(Swrve*)sdk {
    NSMutableDictionary* permissionsStatus = [[NSMutableDictionary alloc] init];
#if !defined(SWRVE_NO_LOCATION)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkLocationAlways]) forKey:swrve_permission_location_always];
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkLocationWhenInUse]) forKey:swrve_permission_location_when_in_use];
#endif //!defined(SWRVE_NO_LOCATION)
#if !defined(SWRVE_NO_PHOTO_LIBRARY)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkPhotoLibrary]) forKey:swrve_permission_photos];
#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkCamera]) forKey:swrve_permission_camera];
#if !defined(SWRVE_NO_ADDRESS_BOOK)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkContacts]) forKey:swrve_permission_contacts];
#endif //!defined(SWRVE_NO_ADDRESS_BOOK)
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkPushNotificationsWithSDK:sdk]) forKey:swrve_permission_push_notifications];
    return permissionsStatus;
}

+(void)compareStatusAndQueueEventsWithSDK:(Swrve*)sdk {
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

+(NSArray*)currentPermissionFiltersWithSDK:sdk {
    NSMutableArray* filters = [[NSMutableArray alloc] init];
    NSDictionary* currentStatus = [SwrvePermissions currentStatusWithSDK:sdk];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_location_always to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_location_when_in_use to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_photos to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_camera to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_contacts to:filters withCurrentStatus:currentStatus];
    
    // Check that we haven't already asked for push permissions
    if (![SwrvePermissions didWeAskForPushPermissionsAlready]) {
        [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_push_notifications to:filters withCurrentStatus:currentStatus];
    }

    return filters;
}

+(BOOL)didWeAskForPushPermissionsAlready {
    return [[NSUserDefaults standardUserDefaults] boolForKey:asked_for_push_flag_key];
}

+(void)checkPermissionNameAndAddFilters:(NSString*)permissionName to:(NSMutableArray*)filters withCurrentStatus:(NSDictionary*)currentStatus {
    if ([[currentStatus objectForKey:permissionName] isEqualToString:swrve_permission_status_unknown]) {
        [filters addObject:[[permissionName lowercaseString] stringByAppendingString:swrve_permission_requestable]];
    }
}

+(void)compareStatusAndQueueEvent:(NSString*)permissioName lastStatus:(NSDictionary*)lastStatus currentStatus:(NSDictionary*)currentStatus withSDK:(Swrve*)sdk {
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

#if !defined(SWRVE_NO_LOCATION)
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

+(void)requestLocationAlways:(Swrve*)sdk {
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

+(void)requestLocationWhenInUse:(Swrve*)sdk {
    ISHPermissionRequest *r = [SwrvePermissions locationWhenInUseRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}
#endif //!defined(SWRVE_NO_LOCATION)

#if !defined(SWRVE_NO_PHOTO_LIBRARY)
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

+(void)requestPhotoLibrary:(Swrve*)sdk {
    ISHPermissionRequest *r = [SwrvePermissions photoLibraryRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}
#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)

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

+(void)requestCamera:(Swrve*)sdk {
    ISHPermissionRequest *r = [SwrvePermissions cameraRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}

#if !defined(SWRVE_NO_ADDRESS_BOOK)
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

+(void)requestContacts:(Swrve*)sdk {
    ISHPermissionRequest *r = [SwrvePermissions contactsRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [sdk userUpdate:[SwrvePermissions currentStatusWithSDK:sdk]];
    }];
}
#endif //!defined(SWRVE_NO_ADDRESS_BOOK)

+(ISHPermissionRequest*)pushNotificationsRequest {
    if (!_remoteNotifications) {
        _remoteNotifications = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryNotificationRemote];
    }
    return _remoteNotifications;
}

+(ISHPermissionState)checkPushNotificationsWithSDK:(Swrve*)sdk {
    NSString* deviceToken = sdk.deviceToken;
    if (deviceToken != nil && deviceToken.length > 0) {
        return ISHPermissionStateAuthorized;
    }
    return ISHPermissionStateUnknown;
}

+(void)requestPushNotifications:(Swrve*)sdk withCallback:(BOOL)callback {
    ISHPermissionRequest *r = [SwrvePermissions pushNotificationsRequest];
#if defined(__IPHONE_8_0)
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    UIApplication* app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(registerUserNotificationSettings:)])
#endif //__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    {
        ((ISHPermissionRequestNotificationsRemote*)r).notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:sdk.config.pushCategories];
    }
#endif //defined(__IPHONE_8_0)
    
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

+(void)sendPermissionEvent:(NSString*)eventName withState:(ISHPermissionState)state withSDK:(Swrve*)sdk {
    NSString *eventNameWithState = [eventName stringByAppendingString:((state == ISHPermissionStateAuthorized)? @".on" : @".off")];
    [sdk eventInternal:eventNameWithState payload:nil triggerCallback:true];
}

@end
