//
//  ISHPermissionRequest+All.m
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 26.06.14.
//  Modified by Swrve Mobile Inc.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "ISHPermissionRequest+All.h"
#import "ISHPermissionRequestLocation.h"
#import "ISHPermissionRequestPhotoLibrary.h"
#import "ISHPermissionRequestPhotoCamera.h"
#import "ISHPermissionRequestNotificationsRemote.h"
#import "ISHPermissionRequestAddressBook.h"
#import "ISHPermissionRequest+Private.h"

@implementation ISHPermissionRequest (All)

+ (ISHPermissionRequest *)requestForCategory:(ISHPermissionCategory)category {
    ISHPermissionRequest *request = nil;
    
    switch (category) {
#if !defined(SWRVE_NO_LOCATION)

        case ISHPermissionCategoryLocationAlways:
        case ISHPermissionCategoryLocationWhenInUse: {
            request = [ISHPermissionRequestLocation new];
            break;
        }

#endif //!defined(SWRVE_NO_LOCATION)
#if !defined(SWRVE_NO_PHOTO_LIBRARY)

        case ISHPermissionCategoryPhotoLibrary:
            request = [ISHPermissionRequestPhotoLibrary new];
            break;

#endif //!defined(SWRVE_NO_PHOTO_LIBRARY)

        case ISHPermissionCategoryPhotoCamera:
            request = [ISHPermissionRequestPhotoCamera new];
            break;

#if !defined(SWRVE_NO_ADDRESS_BOOK)

        case ISHPermissionCategoryAddressBook:
            request = [ISHPermissionRequestAddressBook new];
            break;

#endif //!defined(SWRVE_NO_ADDRESS_BOOK)

        case ISHPermissionCategoryNotificationRemote:
            request = [ISHPermissionRequestNotificationsRemote new];
            break;
            
        default:
            break;
    }
    
    if (request != nil) {
        [request setPermissionCategory:category];
    }
    
    NSAssert(request, @"Request not implemented for category %@", @(category));
    return request;
}

@end
