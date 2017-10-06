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
@property (nonatomic) UIUserNotificationSettings *notificationSettings;
@property (nonatomic) UNAuthorizationOptions notificationAuthOptions;
@property (nonatomic) NSSet<UNNotificationCategory *> * notificationCategories;

-(void)requestUserPermissionWithoutCompleteBlock;
+(void)registerForRemoteNotifications:(UIUserNotificationSettings*)notificationSettings;
+(void)registerForRemoteNotifications:(UNAuthorizationOptions)notificationAuthOptions withCategories:(NSSet<UNNotificationCategory *> *)notificationCategories andBackwardsCompatibility:(UIUserNotificationSettings *)notificationSettings;

@end
