#import <Foundation/Foundation.h>
#import "Swrve.h"
#import "ISHPermissionRequest.h"

static NSString* swrve_permission_status_unknown = @"unknown";
static NSString* swrve_permission_status_unsupported = @"unsupported";
static NSString* swrve_permission_status_denied = @"denied";
static NSString* swrve_permission_status_authorized = @"authorized";

/*! Used internally to offer permission request support */
@interface SwrvePermissions : NSObject

+ (BOOL)processPermissionRequest:(NSString*)action withSDK:(Swrve*)swrve;
+ (NSDictionary*) currentStatus;
+ (void)compareStatusAndQueueEventsWithSDK:(Swrve*)swrve;

+ (ISHPermissionState)checkLocationAlways;
+ (void)requestLocationAlways:(Swrve*)swrve;

+ (ISHPermissionState)checkPhotoLibrary;
+ (void)requestPhotoLibrary:(Swrve*)swrve;

+ (ISHPermissionState)checkCamera;
+ (void)requestCamera:(Swrve*)swrve;

+ (ISHPermissionState)checkContacts;
+ (void)requestContacts:(Swrve*)swrve;

+ (ISHPermissionState)checkPushNotifications;
+ (void)requestPushNotifications:(Swrve*)swrve withCallback:(BOOL)callback;

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