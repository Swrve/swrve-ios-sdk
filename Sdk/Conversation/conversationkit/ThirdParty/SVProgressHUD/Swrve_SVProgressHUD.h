//
//  Swrve_SVProgressHUD.h
//
//  Created by Sam Vermette on 27.03.11.
//  Copyright 2011 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/Swrve_SVProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

extern NSString * const Swrve_SVProgressHUDDidReceiveTouchEventNotification;
extern NSString * const Swrve_SVProgressHUDWillDisappearNotification;
extern NSString * const Swrve_SVProgressHUDDidDisappearNotification;
extern NSString * const Swrve_SVProgressHUDWillAppearNotification;
extern NSString * const Swrve_SVProgressHUDDidAppearNotification;

extern NSString * const Swrve_SVProgressHUDStatusUserInfoKey;

enum {
    Swrve_SVProgressHUDMaskTypeNone = 1, // allow user interactions while HUD is displayed
    Swrve_SVProgressHUDMaskTypeClear, // don't allow
    Swrve_SVProgressHUDMaskTypeBlack, // don't allow and dim the UI in the back of the HUD
    Swrve_SVProgressHUDMaskTypeGradient // don't allow and dim the UI with a a-la-alert-view bg gradient
};

typedef NSUInteger Swrve_SVProgressHUDMaskType;

@interface Swrve_SVProgressHUD : UIView

#pragma mark - Customization

+ (void)setBackgroundColor:(UIColor*)color; // default is [UIColor whiteColor]
+ (void)setForegroundColor:(UIColor*)color; // default is [UIColor blackColor]
+ (void)setRingThickness:(CGFloat)width; // default is 4 pt
+ (void)setFont:(UIFont*)font; // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
+ (void)setSuccessImage:(UIImage*)image; // default is bundled success image from Glyphish
+ (void)setErrorImage:(UIImage*)image; // default is bundled error image from Glyphish

#pragma mark - Show Methods

+ (void)show;
+ (void)showWithMaskType:(Swrve_SVProgressHUDMaskType)maskType;
+ (void)showWithStatus:(NSString*)status;
+ (void)showWithStatus:(NSString*)status maskType:(Swrve_SVProgressHUDMaskType)maskType;

+ (void)showProgress:(float)progress;
+ (void)showProgress:(float)progress status:(NSString*)status;
+ (void)showProgress:(float)progress status:(NSString*)status maskType:(Swrve_SVProgressHUDMaskType)maskType;

+ (void)setStatus:(NSString*)string; // change the HUD loading status while it's showing

// stops the activity indicator, shows a glyph + status, and dismisses HUD 1s later
+ (void)showSuccessWithStatus:(NSString*)string;
+ (void)showErrorWithStatus:(NSString *)string;
+ (void)showImage:(UIImage*)image status:(NSString*)status; // use 28x28 white pngs

+ (void)setOffsetFromCenter:(UIOffset)offset;
+ (void)resetOffsetFromCenter;

+ (void)popActivity;
+ (void)dismiss;

+ (BOOL)isVisible;

@end


@interface Swrve_SVIndefiniteAnimatedView : UIView

@property (nonatomic, assign) CGFloat strokeThickness;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) UIColor *strokeColor;

@end
