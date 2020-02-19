#import "SwrveButton.h"
#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#else
#import "SwrveLocalStorage.h"
#endif

#define DEFAULT_WIDTH 100
#define DEFAULT_HEIGHT 20

@interface SwrveButton()

@end

@implementation SwrveButton

@synthesize name;
@synthesize image;
@synthesize actionString;
@synthesize controller;
@synthesize message;
@synthesize center;
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
    self.name         = NULL;
    self.image        = @"buttonup.png";
    self.actionString = @"";
    self.appID       = 0;
    self.actionType   = kSwrveActionDismiss;
    self.center   = CGPointMake(100, 100);
    return self;
}

-(UIButton*)createButtonWithDelegate:(id)delegate
                            andSelector:(SEL)selector
                               andScale:(float)scale
                             andCenterX:(float)cx
                             andCenterY:(float)cy
{
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSURL* url_up = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, image, nil]];
    UIImage* up   = [UIImage imageWithData:[NSData dataWithContentsOfURL:url_up]];

    UIButton* result;
    if (up) {
        result = [UIButton buttonWithType:UIButtonTypeCustom];

#if TARGET_OS_TV
        result.imageView.adjustsImageWhenAncestorFocused = YES;
#endif
        [result setBackgroundImage:up forState:UIControlStateNormal];
    }
    else {
        result = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    }

#if TARGET_OS_IOS /** TouchUpInside is iOS only **/
    [result  addTarget:delegate action:selector forControlEvents:UIControlEventTouchUpInside];
#elif TARGET_OS_TV
    // There are no touch actions in tvOS, so Primary Action Triggered is the event to run it
    [result  addTarget:delegate action:selector forControlEvents:UIControlEventPrimaryActionTriggered];
#endif

    CGFloat width  = DEFAULT_WIDTH;
    CGFloat height = DEFAULT_HEIGHT;

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
    SwrveMessageController* c = self.controller;
    if (c != nil) {
        [c buttonWasPressedByUser:self];
    }
}

@end
