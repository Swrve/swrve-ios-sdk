#import "SwrvePermissions.h"
#import "ISHPermissionRequest+All.h"

static ISHPermissionRequest *locationAlwaysRequest = nil;
static ISHPermissionRequest *locationAlwaysRequest = nil;
static ISHPermissionRequest *locationAlwaysRequest = nil;
static ISHPermissionRequest *locationAlwaysRequest = nil;

@implementation SwrvePermissions

+(BOOL)checkLocation {
    ISHPermissionRequest *r = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryLocationAlways];
    return ([r permissionState] == ISHPermissionStateAuthorized);
}

+(void)requestLocation {
    locationAlwaysRequest = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryLocationAlways];
    [locationAlwaysRequest requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, state, error)
        // Either the user responded or we can't request again
        int j = 20;
        j++;
    }];
 }

+(void)checkPhotoLibrary {
}

+(void)requestPhotoLibrary {
    ISHPermissionRequest *r = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryPhotoLibrary];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, state, error)
        // Either the user responded or we can't request again
        int j = 20;
        j++;
    }];
}

+(void)requestCamera {
    ISHPermissionRequest *r = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryPhotoCamera];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, state, error)
        // Either the user responded or we can't request again
        int j = 20;
        j++;
    }];
}

+(void)requestPushNotifications {
}

+(void)requestContacts {
    ISHPermissionRequest *r = [ISHPermissionRequest requestForCategory:ISHPermissionCategoryAddressBook];
    [r requestUserPermissionWithCompletionBlock:^(ISHPermissionRequest *request, ISHPermissionState state, NSError *error) {
#pragma unused(request, state, error)
        // Either the user responded or we can't request again
        int j = 20;
        j++;
    }];
}

@end
