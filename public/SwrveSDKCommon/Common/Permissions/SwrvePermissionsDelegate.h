#import "SwrvePermissionState.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*! If you want to track user permission information, or use the status
 * of certain permissions as message actions, implement the following methods.
 * Push notification permissions are managed by the Swrve SDK.
 */
@protocol SwrvePermissionsDelegate <NSObject>

@optional

/*! Status of the Ad Tracking permission.
 *
 * \returns SwrvePermissionState State of the Ad trackimng  permission.
 */
- (SwrvePermissionState)adTrackingPermissionState;

/*! Request the Ad Tracking  permission
 *
 * \param callback Call this callback when the permission has been processed (after dialog or other).
 */
- (void)requestAdTrackingPermission:(void (^)(BOOL processed))callback;

/*! Status of the Contact permission.
 *
 * \returns SwrvePermissionState State of the contacts permission.
 */
- (SwrvePermissionState)contactPermissionState;

/*! Request the Contact permission
 *
 * \param callback Call this callback when the permission has been processed (after dialog or other).
 */
- (void) requestContactsPermission:(void (^)(BOOL processed))callback;

/*! Status of the Camera permission.
 *
 * \returns SwrvePermissionState State of the camera permission.
 */
- (SwrvePermissionState)cameraPermissionState;

/*! Request the Camera permission */
- (void) requestCameraPermission:(void (^)(BOOL processed))callback;

/*! Status of the Photo Library permission.
 *
 * \returns SwrvePermissionState State of the photo library permission.
 */
- (SwrvePermissionState)photoLibraryPermissionState;

/*! Request the Photo Library permission */
- (void) requestPhotoLibraryPermission:(void (^)(BOOL processed))callback;

/*! Status of the Location Always permission.
 *
 * \returns SwrvePermissionState State of the location always permission.
 */
- (SwrvePermissionState)locationAlwaysPermissionState;

/*! Request the Contact permission */
- (void) requestLocationAlwaysPermission:(void (^)(BOOL processed))callback;

/*! Status of the Location When In Use permission.
 *
 * \returns SwrvePermissionState State of the location when in use permission.
 */
- (SwrvePermissionState)locationWhenInUsePermissionState;

/*! Request the Location When In Use permission */
- (void) requestLocationWhenInUsePermission:(void (^)(BOOL processed))callback;

@end
NS_ASSUME_NONNULL_END
