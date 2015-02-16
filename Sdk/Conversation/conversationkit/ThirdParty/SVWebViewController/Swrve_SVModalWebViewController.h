//
//  SVModalWebViewController.h
//
//  Created by Oliver Letterer on 13.08.11.
//  Copyright 2011 Home. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import <UIKit/UIKit.h>

enum {
    Swrve_SVWebViewControllerAvailableActionsNone             = 0,
    Swrve_SVWebViewControllerAvailableActionsOpenInSafari     = 1 << 0,
    Swrve_SVWebViewControllerAvailableActionsMailLink         = 1 << 1,
    Swrve_SVWebViewControllerAvailableActionsCopyLink         = 1 << 2,
    Swrve_SVWebViewControllerAvailableActionsOpenInChrome     = 1 << 3
};

typedef NSUInteger Swrve_SVWebViewControllerAvailableActions;


@class Swrve_SVWebViewController;

@interface Swrve_SVModalWebViewController : UINavigationController

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL *)URL;

@property (nonatomic, strong) UIColor *barsTintColor;
@property (nonatomic, readwrite) Swrve_SVWebViewControllerAvailableActions availableActions;

@end
