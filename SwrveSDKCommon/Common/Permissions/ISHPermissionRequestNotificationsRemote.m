//
//  ISHPermissionRequestNotificationsRemote.m
//  ISHPermissionKit
//
//  Created by Sergio Mira on 21.04.15.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "ISHPermissionRequestNotificationsRemote.h"
#import "ISHPermissionRequest+Private.h"
#import "SwrveCommon.h"

@interface ISHPermissionRequestNotificationsRemote ()
@property (atomic, copy) ISHPermissionRequestCompletionBlock completionBlock;
@end

@implementation ISHPermissionRequestNotificationsRemote

@synthesize notificationSettings;
@synthesize notificationAuthOptions;
@synthesize notificationCategories;
@synthesize completionBlock;

- (BOOL)allowsConfiguration {
    return YES;
}

- (ISHPermissionState)permissionState {
    return ISHPermissionStateUnknown;
}

- (void)requestUserPermissionWithCompletionBlock:(ISHPermissionRequestCompletionBlock)completion {
    NSAssert(completion, @"requestUserPermissionWithCompletionBlock requires a completion block", nil);
    ISHPermissionState currentState = self.permissionState;
    if (!ISHPermissionStateAllowsUserPrompt(currentState)) {
        if (completion != nil) {
            completion(self, currentState, nil);
        }
        return;
    }

    self.completionBlock = completion;
    [ISHPermissionRequestNotificationsRemote registerForRemoteNotifications:self.notificationAuthOptions withCategories:self.notificationCategories andBackwardsCompatibility:self.notificationSettings];
}

- (void)requestUserPermissionWithoutCompleteBlock {

    [ISHPermissionRequestNotificationsRemote registerForRemoteNotifications:self.notificationAuthOptions withCategories:self.notificationCategories andBackwardsCompatibility:self.notificationSettings];
}

+ (void)registerForRemoteNotifications:(UIUserNotificationSettings*)notificationSettings {
    [ISHPermissionRequestNotificationsRemote registerForRemoteNotifications:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge) withCategories:nil andBackwardsCompatibility:notificationSettings];
}

+(void)registerForRemoteNotifications:(UNAuthorizationOptions)notificationAuthOptions withCategories:(NSSet<UNNotificationCategory *> *)notificationCategories andBackwardsCompatibility:(UIUserNotificationSettings *)notificationSettings {
#pragma unused (notificationCategories)

    UIApplication* app = [SwrveCommon sharedUIApplication];
#if defined(__IPHONE_10_0)
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(notificationAuthOptions)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (granted) {
                                      /** Add sdk-defined categories **/
                                      [center setNotificationCategories:notificationCategories];
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [app registerForRemoteNotifications];
                                      });
                                  }

                                  if (error) {
                                      DebugLog(@"Error obtaining permission for notification center: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                                  }
                              }];
    }
#endif

#if defined(__IPHONE_8_0)
    if(SYSTEM_VERSION_LESS_THAN(@"10.0")){
        NSAssert(notificationSettings, @"Requested notification settings should be set for request before requesting user permission", nil);
        // UIApplication calls must be performed on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [app registerUserNotificationSettings:notificationSettings];
            [app registerForRemoteNotifications];
        });
    }
#else
    // Since we no longer support pre-iOS8 builds, this has to be excluded from compilation, here in case
    [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeNewsstandContentAvailability];
    }
#endif //defined(__IPHONE_8_0)
}
@end
