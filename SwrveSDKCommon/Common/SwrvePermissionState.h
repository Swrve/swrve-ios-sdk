#ifndef __swrve_permission_state_h__
#define __swrve_permission_state_h__

#import <Foundation/Foundation.h>

typedef enum {
    SwrvePermissionStateUnknown,
    SwrvePermissionStateUnsupported,
    SwrvePermissionStateAuthorized,
    SwrvePermissionStateDenied,
    SwrvePermissionStateNotImplemented
} SwrvePermissionState;

#endif
