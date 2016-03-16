#import <Foundation/Foundation.h>
#import "Swrve.h"
#import "ISHPermissionRequest.h"

static NSString* swrve_permission_status_unknown        = @"unknown";
static NSString* swrve_permission_status_unsupported    = @"unsupported";
static NSString* swrve_permission_status_denied         = @"denied";
static NSString* swrve_permission_status_authorized     = @"authorized";
static NSString* swrve_permission_status                = @"swrve_permission_status";

static NSString* swrve_permission_location_always       = @"Swrve.permission.ios.location.always";
static NSString* swrve_permission_location_when_in_use  = @"Swrve.permission.ios.location.when_in_use";
static NSString* swrve_permission_photos                = @"Swrve.permission.ios.photos";
static NSString* swrve_permission_camera                = @"Swrve.permission.ios.camera";
static NSString* swrve_permission_contacts              = @"Swrve.permission.ios.contacts";
static NSString* swrve_permission_push_notifications    = @"Swrve.permission.ios.push_notifications";

static NSString* swrve_permission_requestable           = @".requestable";

/*! Used internally to offer permission request support */
@interface SwrvePermissions : NSObject

+ (BOOL)processPermissionRequest:(NSString*)action withSDK:(Swrve*)sdk;
+ (NSDictionary*) currentStatusWithSDK:(Swrve*)sdk;
+ (void)compareStatusAndQueueEventsWithSDK:(Swrve*)sdk;
+ (NSArray*) currentPermissionFiltersWithSDK:(Swrve*)sdk;

#if !defined(SWRVE_NO_LOCATION)
+ (ISHPermissionState)checkLocationAlways;
+ (void)requestLocationAlways:(Swrve*)sdk;
#endif //!defined(SWRVE_NO_LOCATION)

#if !defined(SWRVE_NO_PHOTO_LIBRARY)
+ (ISHPermissionState)checkPhotoLibrary;
+ (void)requestPhotoLibrary:(Swrve*)sdk;
#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)

+ (ISHPermissionState)checkCamera;
+ (void)requestCamera:(Swrve*)sdk;

#if !defined(SWRVE_NO_ADDRESS_BOOK)
+ (ISHPermissionState)checkContacts;
+ (void)requestContacts:(Swrve*)sdk;
#endif //!defined(SWRVE_NO_ADDRESS_BOOK)

+ (ISHPermissionState)checkPushNotificationsWithSDK:(Swrve*)sdk;
+ (void)requestPushNotifications:(Swrve*)sdk withCallback:(BOOL)callback;

@end

static inline NSString *stringFromPermissionState(ISHPermissionState state) {
    switch (state) {
        case ISHPermissionStateUnknown:
            return swrve_permission_status_unknown;
        case ISHPermissionStateUnsupported:
            return swrve_permission_status_unsupported;
        case ISHPermissionStateDenied:
            return swrve_permission_status_denied;
        case ISHPermissionStateAuthorized:
            return swrve_permission_status_authorized;
            
    }
}
