#import "TestPermissionsDelegate.h"

@implementation TestPermissionsDelegate

@synthesize mockContactPermissionState;
@synthesize mockNextContactPermissionState;
@synthesize mockCameraPermissionState;
@synthesize mockNextCameraPermissionState;
@synthesize mockPhotoLibraryPermissionState;
@synthesize mockNextPhotoLibraryPermissionState;
@synthesize mockLocationAlwaysPermissionState;
@synthesize mockNextLocationAlwaysPermissionState;
@synthesize mockLocationWhenInUsePermissionState;
@synthesize mockNextLocationWhenInUsePermissionState;
@synthesize mockAdTrackingPermissionState;
@synthesize mockNextAdTrackingPermissionState;

- (id)init {
    id result = [super init];
    if (result) {
        self.mockContactPermissionState = SwrvePermissionStateAuthorized;
        self.mockNextContactPermissionState = SwrvePermissionStateAuthorized;
        self.mockCameraPermissionState = SwrvePermissionStateAuthorized;
        self.mockNextCameraPermissionState = SwrvePermissionStateAuthorized;
        self.mockPhotoLibraryPermissionState = SwrvePermissionStateAuthorized;
        self.mockNextPhotoLibraryPermissionState = SwrvePermissionStateAuthorized;
        self.mockLocationAlwaysPermissionState = SwrvePermissionStateAuthorized;
        self.mockNextLocationAlwaysPermissionState = SwrvePermissionStateAuthorized;
        self.mockLocationWhenInUsePermissionState = SwrvePermissionStateAuthorized;
        self.mockNextLocationWhenInUsePermissionState = SwrvePermissionStateAuthorized;
        self.mockAdTrackingPermissionState = SwrvePermissionStateAuthorized;
        self.mockNextAdTrackingPermissionState = SwrvePermissionStateAuthorized;
    }
    return result;
}

- (SwrvePermissionState)contactPermissionState {
    return self.mockContactPermissionState;
}

- (void) requestContactsPermission:(void (^)(BOOL processed))callback {
    self.mockContactPermissionState = self.mockNextContactPermissionState;
    callback(TRUE);
}

- (SwrvePermissionState)cameraPermissionState {
    return self.mockCameraPermissionState;
}

- (void) requestCameraPermission:(void (^)(BOOL processed))callback {
    self.mockCameraPermissionState = self.mockNextCameraPermissionState;
    callback(TRUE);
}

- (SwrvePermissionState)photoLibraryPermissionState {
    return self.mockPhotoLibraryPermissionState;
}

- (void) requestPhotoLibraryPermission:(void (^)(BOOL processed))callback {
    self.mockPhotoLibraryPermissionState = self.mockNextPhotoLibraryPermissionState;
    callback(TRUE);
}

- (SwrvePermissionState)locationAlwaysPermissionState {
    return self.mockLocationAlwaysPermissionState;
}

- (void) requestLocationAlwaysPermission:(void (^)(BOOL processed))callback {
    self.mockLocationAlwaysPermissionState = self.mockNextLocationAlwaysPermissionState;
    callback(TRUE);
}

- (SwrvePermissionState)locationWhenInUsePermissionState {
    return self.mockLocationWhenInUsePermissionState;
}

- (void) requestLocationWhenInUsePermission:(void (^)(BOOL processed))callback {
    self.mockLocationWhenInUsePermissionState = self.mockNextLocationWhenInUsePermissionState;
    callback(TRUE);
}

- (SwrvePermissionState)adTrackingPermissionState {
    return self.mockAdTrackingPermissionState;
}

- (void) requestAdTrackingPermission:(void (^)(BOOL processed))callback {
    self.mockAdTrackingPermissionState = self.mockNextAdTrackingPermissionState;
    callback(TRUE);
}


@end
