//
//  SVModalWebViewController.m
//
//  Created by Oliver Letterer on 13.08.11.
//  Copyright 2011 Home. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "Swrve_SVModalWebViewController.h"
#import "Swrve_SVWebViewController.h"

@interface Swrve_SVModalWebViewController ()

@property (nonatomic, strong) Swrve_SVWebViewController *webViewController;

@end


@implementation Swrve_SVModalWebViewController

@synthesize barsTintColor, availableActions, webViewController;

#pragma mark - Initialization


- (id)initWithAddress:(NSString*)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL *)URL {
    self.webViewController = [[Swrve_SVWebViewController alloc] initWithURL:URL];
    if (self = [super initWithRootViewController:self.webViewController]) {
        self.webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:webViewController action:@selector(doneButtonClicked:)];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
#pragma unused (animated)
    
    [super viewWillAppear:NO];
    
    self.navigationBar.tintColor = self.barsTintColor;
}

- (void)setAvailableActions:(Swrve_SVWebViewControllerAvailableActions)newAvailableActions {
    self.webViewController.availableActions = newAvailableActions;
}

- (void)doneButtonClicked:(id)sender {
#pragma unused (sender)
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
