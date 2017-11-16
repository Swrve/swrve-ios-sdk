//
//  ISHPermissionRequestNotificationsRemote.h
//  ISHPermissionKit
//
//  Created by Sergio Mira on 21.04.15.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISHPermissionRequest.h"
#import <UserNotifications/UserNotifications.h>

@interface ISHPermissionRequestNotificationsRemote : ISHPermissionRequest
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
@property (nonatomic) UIUserNotificationSettings *notificationSettings;
@property (nonatomic) UNAuthorizationOptions notificationAuthOptions;
@property (nonatomic) NSSet<UNNotificationCategory *> * notificationCategories;
#pragma clang diagnostic pop
    
-(void)requestUserPermissionWithoutCompleteBlock;
+(void)registerForRemoteNotifications:(UIUserNotificationSettings*)notificationSettings NS_AVAILABLE_IOS(8.0);
+(void)registerForRemoteNotifications:(UNAuthorizationOptions)notificationAuthOptions withCategories:(NSSet<UNNotificationCategory *> *)notificationCategories andBackwardsCompatibility:(UIUserNotificationSettings *)notificationSettings NS_AVAILABLE_IOS(10.0);

@end
