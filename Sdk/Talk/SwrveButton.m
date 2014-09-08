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

#import "SwrveButton.h"

@interface SwrveButton()

@end

@implementation SwrveButton

@synthesize image;
@synthesize actionString;
@synthesize controller;
@synthesize message;
@synthesize center;
@synthesize size;
@synthesize messageID;
@synthesize appID;
@synthesize actionType;

static CGPoint scaled(CGPoint point, float scale)
{
    return CGPointMake(point.x * scale, point.y * scale);
}

-(id)init
{
    self = [super init];
    self.image        = @"buttonup.png";
    self.actionString = @"";
    self.appID       = 0;
    self.actionType   = kSwrveActionDismiss;
    self.center   = CGPointMake(100, 100);
    self.size     = CGSizeMake(100, 20);
    return self;
}

-(UIButton*)createButtonWithOrientation:(UIInterfaceOrientation)orientation
                            andDelegate:(id)delegate
                            andSelector:(SEL)selector
                               andScale:(float)scale
                             andCenterX:(float)cx
                             andCenterY:(float)cy
{
    (void)orientation;
            
    NSString* cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString* swrve_folder = @"com.ngt.msgs";
    
    NSURL* url_up = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cache, swrve_folder, image, nil]];
    UIImage* up   = [UIImage imageWithData:[NSData dataWithContentsOfURL:url_up]];

    UIButton* result;
    if (up) {
        result = [UIButton buttonWithType:UIButtonTypeCustom];
        [result setBackgroundImage:up   forState:UIControlStateNormal];
    }
    else {
        result = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    }
    
    [result  addTarget:delegate action:selector forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat width  = self.size.width;
    CGFloat height = self.size.height;

    if (up) {
        width  = [up size].width;
        height = [up size].height;
    }

    CGPoint position = scaled(self.center, scale);
    [result setFrame:CGRectMake(0, 0, width * scale, height * scale)];
    [result setCenter: CGPointMake(position.x + cx, position.y + cy)];

    return result;
}

-(void)wasPressedByUser
{
    [self.controller buttonWasPressedByUser:self];
}

@end
