#import "SwrvePermissions.h"
#import "ISHPermissionRequest+All.h"
#import "ISHPermissionRequestNotificationsRemote.h"

static ISHPermissionRequest *_locationAlwaysRequest = nil;
static ISHPermissionRequest *_locationWhenInUseRequest = nil;
static ISHPermissionRequest *_photoLibraryRequest = nil;
static ISHPermissionRequest *_cameraRequest = nil;
static ISHPermissionRequest *_contactsRequest = nil;
static ISHPermissionRequest *_remoteNotifications = nil;

@implementation SwrvePermissions

+(BOOL) processPermissionRequest:(NSString*)action withSDK:(Swrve*)swrve {
    if([action caseInsensitiveCompare:@"swrve.request_permission.ios.push_notifications"] == NSOrderedSame) {
        [SwrvePermissions requestPushNotifications:swrve withCallback:YES];
        return YES;
    } else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.location.always"] == NSOrderedSame) {
        [SwrvePermissions requestLocationAlways:swrve];
        return YES;
    } else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.location.when_in_use"] == NSOrderedSame) {
        [SwrvePermissions requestLocationWhenInUse:swrve];
        return YES;
    } else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.contacts"] == NSOrderedSame) {
        [SwrvePermissions requestContacts:swrve];
        return YES;
    } else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.photos"] == NSOrderedSame) {
        [SwrvePermissions requestPhotoLibrary:swrve];
        return YES;
    } else if([action caseInsensitiveCompare:@"swrve.request_permission.ios.camera"] == NSOrderedSame) {
        [SwrvePermissions requestCamera:swrve];
        return YES;
    }
    
    return NO;
}

+(NSDictionary*)currentStatus {
    NSMutableDictionary* permissionsStatus = [[NSMutableDictionary alloc] init];
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkLocationAlways]) forKey:swrve_permission_location_always];
        [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkLocationWhenInUse]) forKey:swrve_permission_location_when_in_use];
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkPhotoLibrary]) forKey:swrve_permission_photos];
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkCamera]) forKey:swrve_permission_camera];
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkContacts]) forKey:swrve_permission_contacts];
    [permissionsStatus setValue:stringFromPermissionState([SwrvePermissions checkPushNotifications]) forKey:swrve_permission_push_notifications];
    return permissionsStatus;
}

+(void)compareStatusAndQueueEventsWithSDK:(Swrve*)swrve {
    NSDictionary* lastStatus = [[NSUserDefaults standardUserDefaults] dictionaryForKey:swrve_permission_status];
    NSDictionary* currentStatus = [self currentStatus];
    if (lastStatus != nil) {
        [self compareStatusAndQueueEvent:swrve_permission_location_always lastStatus:lastStatus currentStatus:currentStatus withSDK:swrve];
        [self compareStatusAndQueueEvent:swrve_permission_location_when_in_use lastStatus:lastStatus currentStatus:currentStatus withSDK:swrve];
        [self compareStatusAndQueueEvent:swrve_permission_photos lastStatus:lastStatus currentStatus:currentStatus withSDK:swrve];
        [self compareStatusAndQueueEvent:swrve_permission_camera lastStatus:lastStatus currentStatus:currentStatus withSDK:swrve];
        [self compareStatusAndQueueEvent:swrve_permission_contacts lastStatus:lastStatus currentStatus:currentStatus withSDK:swrve];
        [self compareStatusAndQueueEvent:swrve_permission_push_notifications lastStatus:lastStatus currentStatus:currentStatus withSDK:swrve];
    }
    [[NSUserDefaults standardUserDefaults] setObject:currentStatus forKey:swrve_permission_status];
}

+(NSArray*)currentPermissionFilters {
    NSMutableArray* filters = [[NSMutableArray alloc] init];
    NSDictionary* currentStatus = [SwrvePermissions currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_location_always to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_location_when_in_use to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_photos to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_camera to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_contacts to:filters withCurrentStatus:currentStatus];
    [SwrvePermissions checkPermissionNameAndAddFilters:swrve_permission_push_notifications to:filters withCurrentStatus:currentStatus];
    return filters;
}

+(void)checkPermissionNameAndAddFilters:(NSString*)permissionName to:(NSMutableArray*)filters withCurrentStatus:(NSDictionary*)currentStatus {
    if ([[currentStatus objectForKey:permissionName] isEqualToString:swrve_permission_status_unknown]) {
        [filters addObject:[permissionName stringByAppendingString:swrve_permission_requestable]];
    }
}

+(void)compareStatusAndQueueEvent:(NSString*)permissioName lastStatus:(NSDictionary*)lastStatus currentStatus:(NSDictionary*)currentStatus withSDK:(Swrve*)swrve {
    NSString* lastStatusString = [lastStatus objectForKey:permissioName];
    NSString* currentStatusString = [currentStatus objectForKey:permissioName];
    if (![lastStatusString isEqualToString:swrve_permission_status_authorized] && [currentStatusString isEqualToString:swrve_permission_status_authorized]) {
        // Send event as the permission has been granted
        [SwrvePermissions sendPermissionEvent:permissioName withState:ISHPermissionStateAuthorized withSDK:swrve];
    } else if (![lastStatusString isEqualToString:swrve_permission_status_denied] && [currentStatusString isEqualToString:swrve_permission_status_denied]) {
        // Send event as the permission has been denied
        [SwrvePermissions sendPermissionEvent:permissioName withState:ISHPermissionStateDenied withSDK:swrve];
    }
}

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

+(void)requestLocationAlways:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions locationAlwaysRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
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

+(void)requestLocationWhenInUse:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions locationWhenInUseRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
    }];
}

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

+(void)requestPhotoLibrary:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions photoLibraryRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
    }];
}

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

+(void)requestCamera:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions cameraRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
    }];
}

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

+(void)requestContacts:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions contactsRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
    }];
}

+(ISHPermissionRequest*)pushNotificationsRequest {
    if (!_remoteNotifications) {
        _remoteNotifications = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryNotificationRemote];
    }
    return _remoteNotifications;
}

+(ISHPermissionState)checkPushNotifications {
    ISHPermissionRequest *r = [SwrvePermissions pushNotificationsRequest];
    return [r permissionState];
}

+(void)requestPushNotifications:(Swrve*)swrve withCallback:(BOOL)callback {
    ISHPermissionRequest *r = [SwrvePermissions pushNotificationsRequest];
#ifdef __IPHONE_8_0
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    UIApplication* app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(registerUserNotificationSettings:)])
#endif
    {
        ((ISHPermissionRequestNotificationsRemote*)r).notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:swrve.config.pushCategories];
    }
#endif
    
    if (callback) {
        [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error, state)
            // Either the user responded or we can't request again
            [swrve userUpdate:[SwrvePermissions currentStatus]];
        }];
    } else {
        [(ISHPermissionRequestNotificationsRemote*)r requestUserPermissionWithoutCompleteBlock];
    }
}

+(void)sendPermissionEvent:(NSString*)eventName withState:(ISHPermissionState)state withSDK:(Swrve*)swrve {
    [swrve event:[eventName stringByAppendingString:((state == ISHPermissionStateAuthorized)? @".on" : @".off")]];
}

@end
