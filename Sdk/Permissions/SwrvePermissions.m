#import "SwrvePermissions.h"
#import "ISHPermissionRequest+All.h"

static ISHPermissionRequest *_locationAlwaysRequest = nil;
static ISHPermissionRequest *_photoLibraryRequest = nil;
static ISHPermissionRequest *_cameraRequest = nil;
static ISHPermissionRequest *_contactsRequest = nil;
static ISHPermissionRequest *_remoteNotifications = nil;

@implementation SwrvePermissions

+(NSDictionary*)currentStatus {
    NSMutableDictionary* permissionsStatus = [[NSMutableDictionary alloc] init];
    [permissionsStatus setValue:[NSNumber numberWithBool:[SwrvePermissions checkLocationAlways]]  forKey:@"swrve.permission.location"];
    [permissionsStatus setValue:[NSNumber numberWithBool:[SwrvePermissions checkPhotoLibrary]]  forKey:@"swrve.permission.photos"];
    [permissionsStatus setValue:[NSNumber numberWithBool:[SwrvePermissions checkCamera]]  forKey:@"swrve.permission.camera"];
    [permissionsStatus setValue:[NSNumber numberWithBool:[SwrvePermissions checkContacts]]  forKey:@"swrve.permission.contacts"];
    [permissionsStatus setValue:[NSNumber numberWithBool:[SwrvePermissions checkPushNotifications]]  forKey:@"swrve.permission.push_notifications"];
    return permissionsStatus;
}

+(ISHPermissionRequest*)locationAlwaysRequest {
    if (!_locationAlwaysRequest) {
        _locationAlwaysRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryLocationAlways];
    }
    return _locationAlwaysRequest;
}

+(BOOL)checkLocationAlways {
    ISHPermissionRequest *r = [SwrvePermissions locationAlwaysRequest];
    return ([r permissionState] == ISHPermissionStateAuthorized);
}

+(void)requestLocationAlways:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions locationAlwaysRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
        [SwrvePermissions sendPermissionEvent:@"swrve.permission.location" withState:state withSDK:swrve];
    }];
 }

+(ISHPermissionRequest*)photoLibraryRequest {
    if (!_photoLibraryRequest) {
        _photoLibraryRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryPhotoLibrary];
    }
    return _photoLibraryRequest;
}

+(BOOL)checkPhotoLibrary {
    ISHPermissionRequest *r = [SwrvePermissions photoLibraryRequest];
    return ([r permissionState] == ISHPermissionStateAuthorized);
}

+(void)requestPhotoLibrary:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions photoLibraryRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
        [SwrvePermissions sendPermissionEvent:@"swrve.permission.photos" withState:state withSDK:swrve];
    }];
}

+(ISHPermissionRequest*)cameraRequest {
    if (!_cameraRequest) {
        _cameraRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryPhotoCamera];
    }
    return _cameraRequest;
}

+(BOOL)checkCamera {
    ISHPermissionRequest *r = [SwrvePermissions cameraRequest];
    return ([r permissionState] == ISHPermissionStateAuthorized);
}

+(void)requestCamera:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions cameraRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
        [SwrvePermissions sendPermissionEvent:@"swrve.permission.camera" withState:state withSDK:swrve];
    }];
}

+(ISHPermissionRequest*)contactsRequest {
    if (!_contactsRequest) {
        _contactsRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryAddressBook];
    }
    return _contactsRequest;
}

+(BOOL)checkContacts {
    ISHPermissionRequest *r = [SwrvePermissions contactsRequest];
    return ([r permissionState] == ISHPermissionStateAuthorized);
}

+(void)requestContacts:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions contactsRequest];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
        [SwrvePermissions sendPermissionEvent:@"swrve.permission.contacts" withState:state withSDK:swrve];
    }];
}

+(ISHPermissionRequest*)pushNotificationsRequest {
    if (!_remoteNotifications) {
        _remoteNotifications = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryNotificationRemote];
    }
    return _remoteNotifications;
}

+(BOOL)checkPushNotifications {
    ISHPermissionRequest *r = [SwrvePermissions pushNotificationsRequest];
    return ([r permissionState] == ISHPermissionStateAuthorized);
}

+(void)requestPushNotifications:(Swrve*)swrve {
    ISHPermissionRequest *r = [SwrvePermissions pushNotificationsRequest];
#ifdef __IPHONE_8_0
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    if ([app respondsToSelector:@selector(registerUserNotificationSettings:)])
#endif
    {
        r.noticationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:swrve.config.pushCategories];
    }
#endif
    
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, error)
        // Either the user responded or we can't request again
        [swrve userUpdate:[SwrvePermissions currentStatus]];
        [SwrvePermissions sendPermissionEvent:@"swrve.permission.push_notifications" withState:state withSDK:swrve];
    }];
}

+(void)sendPermissionEvent:(NSString*)eventName withState:(ISHPermissionState)state withSDK:(Swrve*)swrve {
    [swrve event:[eventName stringByAppendingString:((state == ISHPermissionStateAuthorized)? @".on" : @".off")]];
}

@end
