//
//  ConverserNavigationController.h
//  SwrveConversationKit
//
//  Created by Barry Scott on 21/05/2013.
//  Copyright (c) 2013 Converser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwrveConversationsNavigationController : UINavigationController

@property (nonatomic, assign) BOOL landscapeEnabled;
@property (nonatomic, strong) id<UINavigationControllerDelegate> movieRotationHandling;

@end
