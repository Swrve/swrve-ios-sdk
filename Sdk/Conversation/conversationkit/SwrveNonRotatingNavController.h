//
//  SwrveNonRotatingNavController.h
//  SwrveConversationKit
//
//  Created by Oisin Hurley on 20/03/2013.
//  Copyright (c) 2013 Converser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwrveNonRotatingNavController : UINavigationController

@property (nonatomic, assign) BOOL landscapeEnabled;
@property (nonatomic, strong) id<UINavigationControllerDelegate> movieRotationHandling;
@end
