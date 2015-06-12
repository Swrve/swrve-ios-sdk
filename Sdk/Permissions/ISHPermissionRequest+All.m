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
        case ISHPermissionCategoryLocationAlways:
        case ISHPermissionCategoryLocationWhenInUse: {
            request = [ISHPermissionRequestLocation new];
            break;
        }
            
        case ISHPermissionCategoryPhotoLibrary:
            request = [ISHPermissionRequestPhotoLibrary new];
            break;
            
        case ISHPermissionCategoryPhotoCamera:
            request = [ISHPermissionRequestPhotoCamera new];
            break;
            
        case ISHPermissionCategoryAddressBook:
            request = [ISHPermissionRequestAddressBook new];
            break;

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
