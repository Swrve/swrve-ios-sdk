//
//  SwrveNonRotatingNavController.m
//  SwrveConversationKit
//
//  Created by Oisin Hurley on 20/03/2013.
//  Copyright (c) 2013 Converser. All rights reserved.
//

#import "SwrveNonRotatingNavController.h"
#import "SwrveSetup.h"

@implementation SwrveNonRotatingNavController

@synthesize landscapeEnabled;
@synthesize movieRotationHandling;

-(id) initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.landscapeEnabled = YES;
    }
    return self;
}

// Rotation for iOS 6
- (BOOL)shouldAutorotate {
    return landscapeEnabled;
}

- (NSUInteger)supportedInterfaceOrientations {
    if (landscapeEnabled) {
        // iOS6 short cut is UIInterfaceOrientationMaskAll
        return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationPortraitUpsideDown);
    } else {
        // iOS6 short cut is UIInterfaceOrientationMaskPortrait
        return (1 << UIInterfaceOrientationPortrait);
    }
}

@end
