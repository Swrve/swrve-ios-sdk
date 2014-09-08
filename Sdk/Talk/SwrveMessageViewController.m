/*
 * SWRVE CONFIDENTIAL
 *
 * (c) Copyright 2010-2014 Swrve New Media, Inc. and its licensors.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is and remains the property of Swrve
 * New Media, Inc or its licensors.  The intellectual property and technical
 * concepts contained herein are proprietary to Swrve New Media, Inc. or its
 * licensors and are protected by trade secret and/or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from Swrve.
 */

#import "Swrve.h"
#import "SwrveMessageViewController.h"
#import "SwrveButton.h"

@interface SwrveMessageViewController ()

@property (nonatomic, retain) SwrveMessageFormat* current_format;

@end

@implementation SwrveMessageViewController

@synthesize block;
@synthesize message;
@synthesize current_format;

- (void)viewDidLoad
{
    current_format = nil;
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateBounds];
    [self addViewForOrientation:[self interfaceOrientation]];
    [self.message wasShownToUser];
}

-(void)updateBounds
{
    // Update the bounds to the new screen size
    [self.view setFrame:[[UIScreen mainScreen] bounds]];
}

-(void)removeAllViews
{
    for (UIView *view in self.view.subviews)
    {
        [view removeFromSuperview];
    }
}

-(void)addViewForOrientation:(UIInterfaceOrientation)orientation
{
    current_format = [self.message getBestFormatFor:orientation];
    if (!current_format) {
        // Never leave the screen without a format
        current_format = [self.message.formats objectAtIndex:0];
    }
    
    if (current_format) {
        DebugLog(@"Selected message format: %@", current_format.name);
        [current_format createViewWithOrientation:orientation
                                            toFit:self.view
                                  thatDelegatesTo:self
                                         withSize:self.view.bounds.size
                                          rotated:false];
    } else {
        DebugLog(@"Couldn't find a format for message: %@", message.name);
    }
}

-(IBAction)onButtonPressed:(id)sender
{
    UIButton* button = sender;

    SwrveButton* pressed = [current_format.buttons objectAtIndex:(NSUInteger)button.tag];
    [pressed wasPressedByUser];

    self.block(pressed.actionType, pressed.actionString, pressed.appID);
}

// iOS 8
-(BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIInterfaceOrientation currentOrientation = (size.width > size.height)? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait;
    [self removeAllViews];
    
    BOOL mustRotate = false;
    current_format = [self.message getBestFormatFor:currentOrientation];
    if (!current_format) {
        // Never leave the screen without a format
        current_format = [self.message.formats objectAtIndex:0];
        mustRotate = true;
    }
    
    if (current_format) {
        DebugLog(@"Selected message format: %@", current_format.name);
        [current_format createViewWithOrientation:UIInterfaceOrientationPortrait
                                            toFit:self.view
                                  thatDelegatesTo:self
                                         withSize:size
                                          rotated:mustRotate];
    } else {
        DebugLog(@"Couldn't find a format for message: %@", message.name);
    }
}

// iOS 6 and iOS 7 (to be deprecated)
- (NSUInteger)supportedInterfaceOrientations
{
    BOOL portrait = [self.message supportsOrientation:UIInterfaceOrientationPortrait];
    BOOL landscape = [self.message supportsOrientation:UIInterfaceOrientationLandscapeLeft];
    
    if (portrait && landscape) {
        return UIInterfaceOrientationMaskAll;
    }
    
    if (landscape) {
        return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    }
    
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (BOOL)shouldAutorotate
{
    return YES;
}
// ---------------

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

@end
