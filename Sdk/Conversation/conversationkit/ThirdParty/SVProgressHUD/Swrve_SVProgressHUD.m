//
//  Swrve_SVProgressHUD.m
//
//  Created by Sam Vermette on 27.03.11.
//  Copyright 2011 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVProgressHUD
//

#if !__has_feature(objc_arc)
#error Swrve_SVProgressHUD is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "SwrveSetup.h"
#import "Swrve_SVProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "SwrveConversationResource.h"

NSString * const Swrve_SVProgressHUDDidReceiveTouchEventNotification = @"Swrve_SVProgressHUDDidReceiveTouchEventNotification";
NSString * const Swrve_SVProgressHUDWillDisappearNotification = @"Swrve_SVProgressHUDWillDisappearNotification";
NSString * const Swrve_SVProgressHUDDidDisappearNotification = @"Swrve_SVProgressHUDDidDisappearNotification";
NSString * const Swrve_SVProgressHUDWillAppearNotification = @"Swrve_SVProgressHUDWillAppearNotification";
NSString * const Swrve_SVProgressHUDDidAppearNotification = @"Swrve_SVProgressHUDDidAppearNotification";

NSString * const Swrve_SVProgressHUDStatusUserInfoKey = @"Swrve_SVProgressHUDStatusUserInfoKey";

static UIColor *Swrve_SVProgressHUDBackgroundColor;
static UIColor *Swrve_SVProgressHUDForegroundColor;
static CGFloat Swrve_SVProgressHUDRingThickness;
static UIFont *Swrve_SVProgressHUDFont;
static UIImage *Swrve_SVProgressHUDSuccessImage;
static UIImage *Swrve_SVProgressHUDErrorImage;

static const CGFloat Swrve_SVProgressHUDRingRadius = 18;
static const CGFloat Swrve_SVProgressHUDRingNoTextRadius = 24;
static const CGFloat Swrve_SVProgressHUDParallaxDepthPoints = 10;

@interface Swrve_SVProgressHUD ()

@property (nonatomic, readwrite) Swrve_SVProgressHUDMaskType maskType;
@property (nonatomic, strong, readonly) NSTimer *fadeOutTimer;
@property (nonatomic, readonly, getter = isClear) BOOL clear;

@property (nonatomic, strong) UIControl *overlayView;
@property (nonatomic, strong) UIView *hudView;
@property (nonatomic, strong) UILabel *stringLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) Swrve_SVIndefiniteAnimatedView *indefiniteAnimatedView;

@property (nonatomic, readwrite) CGFloat progress;
@property (nonatomic, readwrite) NSUInteger activityCount;
@property (nonatomic, strong) CAShapeLayer *backgroundRingLayer;
@property (nonatomic, strong) CAShapeLayer *ringLayer;

@property (nonatomic, readonly) CGFloat visibleKeyboardHeight;
@property (nonatomic, assign) UIOffset offsetFromCenter;


- (void)showProgress:(float)progress
              status:(NSString*)string
            maskType:(Swrve_SVProgressHUDMaskType)hudMaskType;

- (void)showImage:(UIImage*)image
           status:(NSString*)status
         duration:(NSTimeInterval)duration;

- (void)dismiss;

- (void)setStatus:(NSString*)string;
- (void)registerNotifications;
- (NSDictionary *)notificationUserInfo;
- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle;
- (void)positionHUD:(NSNotification*)notification;
- (NSTimeInterval)displayDurationForString:(NSString*)string;

@end


@implementation Swrve_SVProgressHUD

@synthesize maskType;
@synthesize fadeOutTimer;
@synthesize clear;
@synthesize overlayView;
@synthesize hudView;
@synthesize stringLabel;
@synthesize imageView;
@synthesize indefiniteAnimatedView;
@synthesize progress;
@synthesize activityCount;
@synthesize backgroundRingLayer;
@synthesize ringLayer;
@synthesize visibleKeyboardHeight;
@synthesize offsetFromCenter;

+ (Swrve_SVProgressHUD*)sharedView {
    static dispatch_once_t once;
    static Swrve_SVProgressHUD *sharedView;
    dispatch_once(&once, ^ { sharedView = [[self alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; });
    return sharedView;
}

#pragma mark - Setters

+ (void)setStatus:(NSString *)string {
	[[self sharedView] setStatus:string];
}

+ (void)setBackgroundColor:(UIColor *)color {
    [self sharedView].hudView.backgroundColor = color;
    Swrve_SVProgressHUDBackgroundColor = color;
}

+ (void)setForegroundColor:(UIColor *)color {
    [self sharedView];
    Swrve_SVProgressHUDForegroundColor = color;
}

+ (void)setFont:(UIFont *)font {
    [self sharedView];
    Swrve_SVProgressHUDFont = font;
}

+ (void)setRingThickness:(CGFloat)width {
    [self sharedView];
    Swrve_SVProgressHUDRingThickness = width;
}

+ (void)setSuccessImage:(UIImage *)image {
    [self sharedView];
    Swrve_SVProgressHUDSuccessImage = image;
}

+ (void)setErrorImage:(UIImage *)image {
    [self sharedView];
    Swrve_SVProgressHUDErrorImage = image;
}

#pragma mark - Show Methods

+ (void)show {
    [[self sharedView] showProgress:-1 status:nil maskType:Swrve_SVProgressHUDMaskTypeNone];
}

+ (void)showWithStatus:(NSString *)status {
    [[self sharedView] showProgress:-1 status:status maskType:Swrve_SVProgressHUDMaskTypeNone];
}

+ (void)showWithMaskType:(Swrve_SVProgressHUDMaskType)maskType {
    [[self sharedView] showProgress:-1 status:nil maskType:maskType];
}

+ (void)showWithStatus:(NSString*)status maskType:(Swrve_SVProgressHUDMaskType)maskType {
    [[self sharedView] showProgress:-1 status:status maskType:maskType];
}

+ (void)showProgress:(float)progress {
    [[self sharedView] showProgress:progress status:nil maskType:Swrve_SVProgressHUDMaskTypeNone];
}

+ (void)showProgress:(float)progress status:(NSString *)status {
    [[self sharedView] showProgress:progress status:status maskType:Swrve_SVProgressHUDMaskTypeNone];
}

+ (void)showProgress:(float)progress status:(NSString *)status maskType:(Swrve_SVProgressHUDMaskType)maskType {
    [[self sharedView] showProgress:progress status:status maskType:maskType];
}

#pragma mark - Show then dismiss methods

+ (void)showSuccessWithStatus:(NSString *)string {
    [self sharedView];
    [self showImage:Swrve_SVProgressHUDSuccessImage status:string];
}

+ (void)showErrorWithStatus:(NSString *)string {
    [self sharedView];
    [self showImage:Swrve_SVProgressHUDErrorImage status:string];
}

+ (void)showImage:(UIImage *)image status:(NSString *)string {
    NSTimeInterval displayInterval = [[Swrve_SVProgressHUD sharedView] displayDurationForString:string];
    [[self sharedView] showImage:image status:string duration:displayInterval];
}


#pragma mark - Dismiss Methods

+ (void)popActivity {
    [self sharedView].activityCount--;
    if([self sharedView].activityCount == 0)
        [[self sharedView] dismiss];
}

+ (void)dismiss {
    if ([self isVisible]) {
        [[self sharedView] dismiss];
    }
}

+ (void)setOffsetFromCenter:(UIOffset)offset {
    [self sharedView].offsetFromCenter = offset;
}

+ (void)resetOffsetFromCenter {
    [self setOffsetFromCenter:UIOffsetZero];
}

// http://stackoverflow.com/questions/20664918/xcode-spurious-warnings-for-creating-selector-for-nonexistent-method-compare
- (id)initWithFrame:(CGRect)frame {

    if ((self = [super initWithFrame:frame])) {
		self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
		self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.activityCount = 0;

        Swrve_SVProgressHUDBackgroundColor = [UIColor whiteColor];
        Swrve_SVProgressHUDForegroundColor = [UIColor blackColor];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
        if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)]) {
#pragma clang diagnostic pop
            Swrve_SVProgressHUDFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        } else {
            Swrve_SVProgressHUDFont = [UIFont systemFontOfSize:14.0];
            Swrve_SVProgressHUDBackgroundColor = [UIColor colorWithWhite:0 alpha:0.8f];
            Swrve_SVProgressHUDForegroundColor = [UIColor whiteColor];
        }
        
        // omh extension
        NSString *success, *error;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            success = @"success-black";
            error = @"error-black";
        } else {
            success = @"success";
            error = @"error";
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
        if ([[UIImage class] instancesRespondToSelector:@selector(imageWithRenderingMode:)]) {
          Swrve_SVProgressHUDSuccessImage = [[SwrveConversationResource imageFromBundleNamed:success] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
          Swrve_SVProgressHUDErrorImage = [[SwrveConversationResource imageFromBundleNamed:error] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        } else {
          Swrve_SVProgressHUDSuccessImage = [SwrveConversationResource imageFromBundleNamed:success];
          Swrve_SVProgressHUDErrorImage = [SwrveConversationResource imageFromBundleNamed:error];
        }
        Swrve_SVProgressHUDRingThickness = 4;
#pragma clang diagnostic pop
    }

    return self;
}

- (void)drawRect:(CGRect)rect {
#pragma unused (rect)
    CGContextRef context = UIGraphicsGetCurrentContext();

    switch (self.maskType) {

        case Swrve_SVProgressHUDMaskTypeBlack: {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }

        case Swrve_SVProgressHUDMaskTypeGradient: {

            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);

            CGFloat freeHeight = self.bounds.size.height - self.visibleKeyboardHeight;

            CGPoint center = CGPointMake(self.bounds.size.width/2, freeHeight/2);
            CGFloat radius = (float)fmin(self.bounds.size.width , self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);

            break;
        }
    }
}

- (void)updatePosition {

    CGFloat hudWidth = 100;
    CGFloat hudHeight = 100;
    CGFloat stringHeightBuffer = 20;
    CGFloat stringAndImageHeightBuffer = 80;

    CGFloat stringWidth = 0;
    CGFloat stringHeight = 0;
    CGRect labelRect = CGRectZero;

    NSString *string = self.stringLabel.text;
    // False if it's text-only
    BOOL imageUsed = (self.imageView.image) || (self.imageView.hidden);

    if(string) {
        CGSize constraintSize = CGSizeMake(200, 300);
        CGRect stringRect;
        if ([string respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
          stringRect = [string boundingRectWithSize:constraintSize
                                            options:(NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin)
                                         attributes:@{NSFontAttributeName: self.stringLabel.font}
                                            context:NULL];
        } else {
          CGSize stringSize = [string sizeWithFont:self.stringLabel.font constrainedToSize:CGSizeMake(200, 300)];
          stringRect = CGRectMake(0.0f, 0.0f, stringSize.width, stringSize.height);
        }
        stringWidth = stringRect.size.width;
        stringHeight = (float)ceil(stringRect.size.height);

        if (imageUsed)
            hudHeight = stringAndImageHeightBuffer + stringHeight;
        else
            hudHeight = stringHeightBuffer + stringHeight;

        if(stringWidth > hudWidth)
            hudWidth = (float)ceil(stringWidth/2)*2;

        CGFloat labelRectY = imageUsed ? 68 : 9;

        if(hudHeight > 100) {
            labelRect = CGRectMake(12, labelRectY, hudWidth, stringHeight);
            hudWidth+=24;
        } else {
            hudWidth+=24;
            labelRect = CGRectMake(0, labelRectY, hudWidth, stringHeight);
        }
    }

	self.hudView.bounds = CGRectMake(0, 0, hudWidth, hudHeight);

    if(string)
        self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds)/2, 36);
	else
       	self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds)/2, CGRectGetHeight(self.hudView.bounds)/2);

	self.stringLabel.hidden = NO;
	self.stringLabel.frame = labelRect;

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

	if(string) {
        self.indefiniteAnimatedView.radius = Swrve_SVProgressHUDRingRadius;
        [self.indefiniteAnimatedView sizeToFit];

        CGPoint center = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), 36);
        self.indefiniteAnimatedView.center = center;

        if(self.progress != -1)
            self.backgroundRingLayer.position = self.ringLayer.position = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), 36);
	}
    else {
        self.indefiniteAnimatedView.radius = Swrve_SVProgressHUDRingNoTextRadius;
        [self.indefiniteAnimatedView sizeToFit];

        CGPoint center = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), CGRectGetHeight(self.hudView.bounds)/2);
        self.indefiniteAnimatedView.center = center;

        if(self.progress != -1)
            self.backgroundRingLayer.position = self.ringLayer.position = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), CGRectGetHeight(self.hudView.bounds)/2);
    }

    [CATransaction commit];
}

- (void)setStatus:(NSString *)string {

	self.stringLabel.text = string;
    [self updatePosition];

}

- (void)setFadeOutTimer:(NSTimer *)newTimer {

    if(fadeOutTimer) {
        [fadeOutTimer invalidate], fadeOutTimer = nil;
    }

    if(newTimer) {
        fadeOutTimer = newTimer;
    }
}


- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}


- (NSDictionary *)notificationUserInfo
{
    return (self.stringLabel.text ? @{Swrve_SVProgressHUDStatusUserInfoKey : self.stringLabel.text} : nil);
}


- (void)positionHUD:(NSNotification*)notification {

    CGFloat keyboardHeight;
    double animationDuration;

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    // no transforms applied to window in iOS 8
    BOOL ignoreOrientation = [[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)];

    if(notification) {
        NSDictionary* keyboardInfo = [notification userInfo];
        CGRect keyboardFrame = [[keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        animationDuration = [[keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

        if(notification.name == UIKeyboardWillShowNotification || notification.name == UIKeyboardDidShowNotification) {
            if(ignoreOrientation || UIInterfaceOrientationIsPortrait(orientation))
                keyboardHeight = keyboardFrame.size.height;
            else
                keyboardHeight = keyboardFrame.size.width;
        } else
            keyboardHeight = 0;
    } else {
        keyboardHeight = self.visibleKeyboardHeight;
    }

    CGRect orientationFrame = self.window.bounds;
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;

    if(!ignoreOrientation && UIInterfaceOrientationIsLandscape(orientation)) {
        CGFloat temp = orientationFrame.size.width;
        orientationFrame.size.width = orientationFrame.size.height;
        orientationFrame.size.height = temp;

        temp = statusBarFrame.size.width;
        statusBarFrame.size.width = statusBarFrame.size.height;
        statusBarFrame.size.height = temp;
    }

    CGFloat activeHeight = orientationFrame.size.height;

    if(keyboardHeight > 0)
        activeHeight += statusBarFrame.size.height*2;

    activeHeight -= keyboardHeight;
    CGFloat posY = (float)floor(activeHeight*0.45);
    CGFloat posX = orientationFrame.size.width/2;

    CGPoint newCenter;
    CGFloat rotateAngle;

    if (ignoreOrientation) {
        rotateAngle = 0.0;
        newCenter = CGPointMake(posX, posY);
    } else {
        switch (orientation) {
            case UIInterfaceOrientationPortraitUpsideDown:
                rotateAngle = (float)M_PI;
                newCenter = CGPointMake(posX, orientationFrame.size.height-posY);
                break;
            case UIInterfaceOrientationLandscapeLeft:
                rotateAngle = (float)(-M_PI/2.0f);
                newCenter = CGPointMake(posY, posX);
                break;
            case UIInterfaceOrientationLandscapeRight:
                rotateAngle = (float)(M_PI/2.0f);
                newCenter = CGPointMake(orientationFrame.size.height-posY, posX);
                break;
            default: // as UIInterfaceOrientationPortrait
                rotateAngle = 0.0;
                newCenter = CGPointMake(posX, posY);
                break;
        }
    }

    if(notification) {
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [self moveToPoint:newCenter rotateAngle:rotateAngle];
                         } completion:NULL];
    }

    else {
        [self moveToPoint:newCenter rotateAngle:rotateAngle];
    }

}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle {
    self.hudView.transform = CGAffineTransformMakeRotation(angle);
    self.hudView.center = CGPointMake(newCenter.x + self.offsetFromCenter.horizontal, newCenter.y + self.offsetFromCenter.vertical);
}

- (void)overlayViewDidReceiveTouchEvent:(id)sender forEvent:(UIEvent *)event {
#pragma unused (sender)
    [[NSNotificationCenter defaultCenter] postNotificationName:Swrve_SVProgressHUDDidReceiveTouchEventNotification object:event];
}

#pragma mark - Master show/dismiss methods

- (void)showProgress:(float)prog status:(NSString*)string maskType:(Swrve_SVProgressHUDMaskType)hudMaskType {

    if(!self.overlayView.superview){
        NSEnumerator *frontToBackWindows = [[[UIApplication sharedApplication]windows]reverseObjectEnumerator];

        for (UIWindow *window in frontToBackWindows)
            if (window.windowLevel == UIWindowLevelNormal) {
                [window addSubview:self.overlayView];
                break;
            }
    }

    if(!self.superview)
        [self.overlayView addSubview:self];

    self.fadeOutTimer = nil;
    self.imageView.hidden = YES;
    self.maskType = hudMaskType;
    self.progress = prog;

    self.stringLabel.text = string;
    [self updatePosition];

    if(prog >= 0) {
        self.imageView.image = nil;
        self.imageView.hidden = NO;
        [self.indefiniteAnimatedView removeFromSuperview];

        self.ringLayer.strokeEnd = prog;

        if(prog == 0)
            self.activityCount++;
    }
    else {
        self.activityCount++;
        [self cancelRingLayerAnimation];
        [self.hudView addSubview:self.indefiniteAnimatedView];
    }

    if(self.maskType != Swrve_SVProgressHUDMaskTypeNone) {
        self.overlayView.userInteractionEnabled = YES;
        self.accessibilityLabel = string;
        self.isAccessibilityElement = YES;
    }
    else {
        self.overlayView.userInteractionEnabled = NO;
        self.hudView.accessibilityLabel = string;
        self.hudView.isAccessibilityElement = YES;
    }

    [self.overlayView setHidden:NO];
    self.overlayView.backgroundColor = [UIColor clearColor];
    [self positionHUD:nil];

    if(self.alpha != 1) {
        NSDictionary *userInfo = [self notificationUserInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:Swrve_SVProgressHUDWillAppearNotification
                                                            object:nil
                                                          userInfo:userInfo];

        [self registerNotifications];
        self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1.3f, 1.3f);

        if(self.isClear) {
            self.alpha = 1;
            self.hudView.alpha = 0;
        }

        [UIView animateWithDuration:0.15
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1/1.3f, 1/1.3f);

                             if(self.isClear) // handle iOS 7 UIToolbar not answer well to hierarchy opacity change
                                 self.hudView.alpha = 1;
                             else
                                 self.alpha = 1;
                         }
                         completion:^(BOOL finished){
#pragma unused (finished)
                             [[NSNotificationCenter defaultCenter] postNotificationName:Swrve_SVProgressHUDDidAppearNotification
                                                                                 object:nil
                                                                               userInfo:userInfo];
                             UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                             UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
                         }];

        [self setNeedsDisplay];
    }
}

- (UIImage *)image:(UIImage *)image withTintColor:(UIColor *)color
{
  CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
  CGContextRef c = UIGraphicsGetCurrentContext();
  [image drawInRect:rect];
  CGContextSetFillColorWithColor(c, [color CGColor]);
  CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
  CGContextFillRect(c, rect);
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return tintedImage;
}

- (void)showImage:(UIImage *)image status:(NSString *)string duration:(NSTimeInterval)duration {
    self.progress = -1;
    [self cancelRingLayerAnimation];

    if(![self.class isVisible])
        [self.class show];

    if ([self.imageView respondsToSelector:@selector(setTintColor:)]) {
      self.imageView.tintColor = Swrve_SVProgressHUDForegroundColor;
    } else {
      image = [self image:image withTintColor:Swrve_SVProgressHUDForegroundColor];
    }
    self.imageView.image = image;
    self.imageView.hidden = NO;

    self.stringLabel.text = string;
    [self updatePosition];
    [self.indefiniteAnimatedView removeFromSuperview];

    if(self.maskType != Swrve_SVProgressHUDMaskTypeNone) {
        self.accessibilityLabel = string;
        self.isAccessibilityElement = YES;
    } else {
        self.hudView.accessibilityLabel = string;
        self.hudView.isAccessibilityElement = YES;
    }

    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);

    self.fadeOutTimer = [NSTimer timerWithTimeInterval:duration target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.fadeOutTimer forMode:NSRunLoopCommonModes];
}

- (void)dismiss {
    NSDictionary *userInfo = [self notificationUserInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:Swrve_SVProgressHUDWillDisappearNotification
                                                        object:nil
                                                      userInfo:userInfo];

    self.activityCount = 0;
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 0.8f, 0.8f);
                         if(self.isClear) // handle iOS 7 UIToolbar not answer well to hierarchy opacity change
                             self.hudView.alpha = 0;
                         else
                             self.alpha = 0;
                     }
                     completion:^(BOOL finished){
#pragma unused (finished)
                         if(self.alpha == 0 || self.hudView.alpha == 0) {
                             self.alpha = 0;
                             self.hudView.alpha = 0;

                             [[NSNotificationCenter defaultCenter] removeObserver:self];
                             [self cancelRingLayerAnimation];
                             [self->hudView removeFromSuperview];
                             self->hudView = nil;

                             [self->overlayView removeFromSuperview];
                             self->overlayView = nil;

                             [self->indefiniteAnimatedView removeFromSuperview];
                             self->indefiniteAnimatedView = nil;

                             UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);

                             [[NSNotificationCenter defaultCenter] postNotificationName:Swrve_SVProgressHUDDidDisappearNotification
                                                                                 object:nil
                                                                               userInfo:userInfo];

                             // Tell the rootViewController to update the StatusBar appearance
                             UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
                             if ([rootController respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
                                 [rootController setNeedsStatusBarAppearanceUpdate];
                             }
                             // uncomment to make sure UIWindow is gone from app.windows
                             //NSLog(@"%@", [UIApplication sharedApplication].windows);
                             //NSLog(@"keyWindow = %@", [UIApplication sharedApplication].keyWindow);
                         }
                     }];
}


#pragma mark - Ring progress animation

- (Swrve_SVIndefiniteAnimatedView *)indefiniteAnimatedView {
    if (indefiniteAnimatedView == nil) {
        indefiniteAnimatedView = [[Swrve_SVIndefiniteAnimatedView alloc] initWithFrame:CGRectZero];
        indefiniteAnimatedView.radius = self.stringLabel.text ? Swrve_SVProgressHUDRingRadius : Swrve_SVProgressHUDRingNoTextRadius;
        [indefiniteAnimatedView sizeToFit];
    }
    return indefiniteAnimatedView;
}

- (CAShapeLayer *)ringLayer {
    if(!ringLayer) {
        CGPoint center = CGPointMake(CGRectGetWidth(hudView.frame)/2, CGRectGetHeight(hudView.frame)/2);
        ringLayer = [self createRingLayerWithCenter:center
                                              radius:Swrve_SVProgressHUDRingRadius
                                           lineWidth:Swrve_SVProgressHUDRingThickness
                                               color:Swrve_SVProgressHUDForegroundColor];
        [self.hudView.layer addSublayer:ringLayer];
    }
    return ringLayer;
}

- (CAShapeLayer *)backgroundRingLayer {
    if(!backgroundRingLayer) {
        CGPoint center = CGPointMake(CGRectGetWidth(hudView.frame)/2, CGRectGetHeight(hudView.frame)/2);
        backgroundRingLayer = [self createRingLayerWithCenter:center
                                                        radius:Swrve_SVProgressHUDRingRadius
                                                     lineWidth:Swrve_SVProgressHUDRingThickness
                                                         color:[Swrve_SVProgressHUDForegroundColor colorWithAlphaComponent:0.1f]];
        backgroundRingLayer.strokeEnd = 1;
        [self.hudView.layer addSublayer:backgroundRingLayer];
    }
    return backgroundRingLayer;
}

- (void)cancelRingLayerAnimation {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [hudView.layer removeAllAnimations];

    ringLayer.strokeEnd = 0.0f;
    if (ringLayer.superlayer) {
        [ringLayer removeFromSuperlayer];
    }
    ringLayer = nil;

    if (backgroundRingLayer.superlayer) {
        [backgroundRingLayer removeFromSuperlayer];
    }
    backgroundRingLayer = nil;

    [CATransaction commit];
}

- (CAShapeLayer *)createRingLayerWithCenter:(CGPoint)center radius:(CGFloat)radius lineWidth:(CGFloat)lineWidth color:(UIColor *)color {

    UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius) radius:radius startAngle:(float)(-M_PI_2) endAngle:(float)(M_PI + M_PI_2) clockwise:YES];

    CAShapeLayer *slice = [CAShapeLayer layer];
    slice.contentsScale = [[UIScreen mainScreen] scale];
    slice.frame = CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2);
    slice.fillColor = [UIColor clearColor].CGColor;
    slice.strokeColor = color.CGColor;
    slice.lineWidth = lineWidth;
    slice.lineCap = kCALineCapRound;
    slice.lineJoin = kCALineJoinBevel;
    slice.path = smoothedPath.CGPath;
    return slice;
}

#pragma mark - Utilities

+ (BOOL)isVisible {
    return ([self sharedView].alpha == 1);
}


#pragma mark - Getters

- (NSTimeInterval)displayDurationForString:(NSString*)string {
    return fmin((float)string.length*0.06 + 0.3, 5.0);
}

- (BOOL)isClear { // used for iOS 7
    return (self.maskType == Swrve_SVProgressHUDMaskTypeClear || self.maskType == Swrve_SVProgressHUDMaskTypeNone);
}

- (UIControl *)overlayView {
    if(!overlayView) {
        overlayView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayView.backgroundColor = [UIColor clearColor];
        [overlayView addTarget:self action:@selector(overlayViewDidReceiveTouchEvent:forEvent:) forControlEvents:UIControlEventTouchDown];
    }
    return overlayView;
}

- (UIView *)hudView {
    if(!hudView) {
        hudView = [[UIView alloc] initWithFrame:CGRectZero];
        hudView.backgroundColor = Swrve_SVProgressHUDBackgroundColor;
        hudView.layer.cornerRadius = 14;
        hudView.layer.masksToBounds = YES;

        hudView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
                                     UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);

      if ([hudView respondsToSelector:@selector(addMotionEffect:)]) {
        UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"center.x" type: UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        effectX.minimumRelativeValue = @(-Swrve_SVProgressHUDParallaxDepthPoints);
        effectX.maximumRelativeValue = @(Swrve_SVProgressHUDParallaxDepthPoints);

        UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"center.y" type: UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        effectY.minimumRelativeValue = @(-Swrve_SVProgressHUDParallaxDepthPoints);
        effectY.maximumRelativeValue = @(Swrve_SVProgressHUDParallaxDepthPoints);

        [hudView addMotionEffect: effectX];
        [hudView addMotionEffect: effectY];
      }

        [self addSubview:hudView];
    }
    return hudView;
}

- (UILabel *)stringLabel {
    if (stringLabel == nil) {
        stringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		stringLabel.backgroundColor = [UIColor clearColor];
		stringLabel.adjustsFontSizeToFitWidth = YES;
        stringLabel.textAlignment = NSTextAlignmentCenter;
		stringLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		stringLabel.textColor = Swrve_SVProgressHUDForegroundColor;
		stringLabel.font = Swrve_SVProgressHUDFont;
        stringLabel.numberOfLines = 0;
    }

    if(!stringLabel.superview)
        [self.hudView addSubview:stringLabel];

    return stringLabel;
}

- (UIImageView *)imageView {
    if (imageView == nil) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    }
    
    if(!imageView.superview) {
        [self.hudView addSubview:imageView];
    }
    
    return imageView;
}


- (CGFloat)visibleKeyboardHeight {

    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if(![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }

    for (__strong UIView *possibleKeyboard in [keyboardWindow subviews]) {
        if([possibleKeyboard isKindOfClass:NSClassFromString(@"UIPeripheralHostView")] || [possibleKeyboard isKindOfClass:NSClassFromString(@"UIKeyboard")])
            return possibleKeyboard.bounds.size.height;
    }

    return 0;
}

@end

#pragma mark Swrve_SVIndefiniteAnimatedView

@interface Swrve_SVIndefiniteAnimatedView ()

@property (nonatomic, strong) CAShapeLayer *indefiniteAnimatedLayer;

@end

@implementation Swrve_SVIndefiniteAnimatedView

@synthesize indefiniteAnimatedLayer;
@synthesize strokeThickness;
@synthesize radius;
@synthesize strokeColor;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.strokeThickness = Swrve_SVProgressHUDRingThickness;
        self.radius = Swrve_SVProgressHUDRingRadius;
        self.strokeColor = Swrve_SVProgressHUDForegroundColor;
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview != nil) {
        [self layoutAnimatedLayer];
    }
    else {
        [indefiniteAnimatedLayer removeFromSuperlayer];
        indefiniteAnimatedLayer = nil;
    }
}

- (void)layoutAnimatedLayer {
    CALayer *layer = self.indefiniteAnimatedLayer;

    [self.layer addSublayer:layer];
    layer.position = CGPointMake(self.bounds.size.width - layer.bounds.size.width / 2, self.bounds.size.height - layer.bounds.size.height / 2);
}

- (CAShapeLayer*)indefiniteAnimatedLayer {
    if(!indefiniteAnimatedLayer) {
        CGPoint arcCenter = CGPointMake(self.radius+self.strokeThickness/2+5, self.radius+self.strokeThickness/2+5);
        CGRect rect = CGRectMake(0, 0, arcCenter.x*2, arcCenter.y*2);

        UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithArcCenter:arcCenter
                                                                    radius:self.radius
                                                                startAngle:(float)(M_PI*3/2)
                                                                  endAngle:(float)(M_PI/2+M_PI*5)
                                                                 clockwise:YES];

        indefiniteAnimatedLayer = [CAShapeLayer layer];
        indefiniteAnimatedLayer.contentsScale = [[UIScreen mainScreen] scale];
        indefiniteAnimatedLayer.frame = rect;
        indefiniteAnimatedLayer.fillColor = [UIColor clearColor].CGColor;
        indefiniteAnimatedLayer.strokeColor = self.strokeColor.CGColor;
        indefiniteAnimatedLayer.lineWidth = self.strokeThickness;
        indefiniteAnimatedLayer.lineCap = kCALineCapRound;
        indefiniteAnimatedLayer.lineJoin = kCALineJoinBevel;
        indefiniteAnimatedLayer.path = smoothedPath.CGPath;

        CALayer *maskLayer = [CALayer layer];
        maskLayer.contents = (id)[[SwrveConversationResource imageFromBundleNamed:@"angle-mask"] CGImage];
        maskLayer.frame = indefiniteAnimatedLayer.bounds;
        indefiniteAnimatedLayer.mask = maskLayer;

        NSTimeInterval animationDuration = 1;
        CAMediaTimingFunction *linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.fromValue = 0;
        animation.toValue = [NSNumber numberWithDouble:M_PI*2];
        animation.duration = animationDuration;
        animation.timingFunction = linearCurve;
        animation.removedOnCompletion = NO;
        animation.repeatCount = INFINITY;
        animation.fillMode = kCAFillModeForwards;
        animation.autoreverses = NO;
        [indefiniteAnimatedLayer.mask addAnimation:animation forKey:@"rotate"];

        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = animationDuration;
        animationGroup.repeatCount = INFINITY;
        animationGroup.removedOnCompletion = NO;
        animationGroup.timingFunction = linearCurve;

        CABasicAnimation *strokeStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        strokeStartAnimation.fromValue = @0.015;
        strokeStartAnimation.toValue = @0.515;

        CABasicAnimation *strokeEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeEndAnimation.fromValue = @0.485;
        strokeEndAnimation.toValue = @0.985;

        animationGroup.animations = @[strokeStartAnimation, strokeEndAnimation];
        [indefiniteAnimatedLayer addAnimation:animationGroup forKey:@"progress"];

    }
    return indefiniteAnimatedLayer;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    if (self.superview != nil) {
        [self layoutAnimatedLayer];
    }
}

- (void)setRadius:(CGFloat)pradius {
    radius = pradius;

    [indefiniteAnimatedLayer removeFromSuperlayer];
    indefiniteAnimatedLayer = nil;

    [self layoutAnimatedLayer];
}

- (void)setStrokeColor:(UIColor *)pstrokeColor {
    strokeColor = pstrokeColor;
    indefiniteAnimatedLayer.strokeColor = pstrokeColor.CGColor;
}

- (void)setStrokeThickness:(CGFloat)pstrokeThickness {
    strokeThickness = pstrokeThickness;
    indefiniteAnimatedLayer.lineWidth = strokeThickness;
}

- (CGSize)sizeThatFits:(CGSize)size {
#pragma unused (size)
    return CGSizeMake((self.radius+self.strokeThickness/2+5)*2, (self.radius+self.strokeThickness/2+5)*2);
}

@end
