//
//  ISHPermissionRequestMotion.m
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 26.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

#import "ISHPermissionRequestMotion.h"
#import "ISHPermissionRequest+Private.h"

@interface ISHPermissionRequestMotion ()
@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) NSOperationQueue *motionActivityQueue;
@end

@implementation ISHPermissionRequestMotion

@synthesize activityManager;
@synthesize motionActivityQueue;

- (ISHPermissionState)permissionState {
    if (![CMMotionActivityManager isActivityAvailable]) {
        return ISHPermissionStateUnsupported;
    }
    return [self internalPermissionState];
}

- (void)requestUserPermissionWithCompletionBlock:(ISHPermissionRequestCompletionBlock)completion {
    NSAssert(completion, @"requestUserPermissionWithCompletionBlock requires a completion block");
    ISHPermissionState currentState = self.permissionState;

    if (!ISHPermissionStateAllowsUserPrompt(currentState)) {
        completion(self, currentState, nil);
        return;
    }

    [self setInternalPermissionState:ISHPermissionStateDoNotAskAgain]; // avoid asking again
    self.activityManager = [[CMMotionActivityManager alloc] init];
    self.motionActivityQueue = [[NSOperationQueue alloc] init];
    [self.activityManager queryActivityStartingFromDate:[NSDate distantPast] toDate:[NSDate date] toQueue:self.motionActivityQueue withHandler:^(NSArray *activities, NSError *error) {
        ISHPermissionState currentStateFromDate = ISHPermissionStateUnknown;
        
        if (error && (error.domain == CMErrorDomain) && (error.code == CMErrorMotionActivityNotAuthorized)) {
            currentStateFromDate = ISHPermissionStateDenied;
        } else if (activities || !error) {
            currentStateFromDate = ISHPermissionStateAuthorized;
        }
        
        [self setInternalPermissionState:currentStateFromDate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(self, currentStateFromDate, error);
        });
        
        [self setActivityManager:nil];
        [self setMotionActivityQueue:nil];
    }];
}

@end
