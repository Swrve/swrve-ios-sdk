#import <Foundation/Foundation.h>
#import "SwrvePermissionsDelegate.h"

@interface TestPermissionsDelegate : NSObject<SwrvePermissionsDelegate>

@property (nonatomic) SwrvePermissionState mockContactPermissionState;
@property (nonatomic) SwrvePermissionState mockNextContactPermissionState;

@property (nonatomic) SwrvePermissionState mockCameraPermissionState;
@property (nonatomic) SwrvePermissionState mockNextCameraPermissionState;

@property (nonatomic) SwrvePermissionState mockPhotoLibraryPermissionState;
@property (nonatomic) SwrvePermissionState mockNextPhotoLibraryPermissionState;

@property (nonatomic) SwrvePermissionState mockLocationAlwaysPermissionState;
@property (nonatomic) SwrvePermissionState mockNextLocationAlwaysPermissionState;

@property (nonatomic) SwrvePermissionState mockLocationWhenInUsePermissionState;
@property (nonatomic) SwrvePermissionState mockNextLocationWhenInUsePermissionState;

@property (nonatomic) SwrvePermissionState mockAdTrackingPermissionState;
@property (nonatomic) SwrvePermissionState mockNextAdTrackingPermissionState;

- (SwrvePermissionState)contactPermissionState;

- (void) requestContactsPermission:(void (^)(BOOL processed))callback;

- (SwrvePermissionState)cameraPermissionState;

- (void) requestCameraPermission:(void (^)(BOOL processed))callback;

- (SwrvePermissionState)photoLibraryPermissionState;

- (void) requestPhotoLibraryPermission:(void (^)(BOOL processed))callback;

- (SwrvePermissionState)locationAlwaysPermissionState;

- (void) requestLocationAlwaysPermission:(void (^)(BOOL processed))callback;

- (SwrvePermissionState)locationWhenInUsePermissionState;

- (void) requestLocationWhenInUsePermission:(void (^)(BOOL processed))callback;

- (SwrvePermissionState)adTrackingPermissionState;

- (void) requestAdTrackingPermission:(void (^)(BOOL processed))callback;

@end
