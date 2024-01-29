#import "SwrveThemedUIButton.h"
#import "SwrveSDKUtils.h"

#if __has_include(<SwrveSDKCommon/SwrveUtils.h>)
#import <SwrveSDKCommon/SwrveUtils.h>
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#import <SwrveSDKCommon/SwrveLogger.h>
#else
#import "SwrveUtils.h"
#import "SwrveLocalStorage.h"
#import "SwrveLogger.h"
#endif

@interface SwrveThemedUIButton ()

@property(atomic, retain) SwrveButtonTheme *theme;
@property(atomic, retain) SwrveCalibration *calibration;
@property(atomic) CGFloat renderScale;

@end

@implementation SwrveThemedUIButton

@synthesize theme;
@synthesize calibration;
@synthesize renderScale;

- (id)initWithTheme:(SwrveButtonTheme *)buttonTheme
               text:(NSString *)text
              frame:(CGRect)frameRect
        calabration:(SwrveCalibration *)swrveCalibration
        renderScale:(CGFloat)scale {

    if (self = [super init]) {
        self.theme = buttonTheme;
        self.frame = frameRect;
        self.calibration = swrveCalibration;
        self.renderScale = scale;

        [self setTitle:text forState:UIControlStateNormal];
        [self applyTextAlignment];
        [self applyPadding];
        [self applyFont];
        [self applyFontColor];
        [self applyCornerRadius];
        [self applyBorder];
        [self applyBackground];

        self.clipsToBounds = true;
    }

    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        if (theme.pressedState.bgColor) {
            self.backgroundColor = [SwrveUtils processHexColorValue:theme.pressedState.bgColor];
        }
        if (theme.pressedState.borderColor) {
            UIColor *borderColor = [SwrveUtils processHexColorValue:theme.pressedState.borderColor];
            self.layer.borderColor = [borderColor CGColor];
        }
    } else {
        if (theme.bgColor) {
            self.backgroundColor = [SwrveUtils processHexColorValue:theme.bgColor];
        }
        if (theme.borderColor) {
            UIColor *borderColor = [SwrveUtils processHexColorValue:theme.borderColor];
            self.layer.borderColor = [borderColor CGColor];
        }
    }
}

- (void)applyTextAlignment {
    if (!theme.hAlign) {
        return;
    }
    if ([theme.hAlign isEqualToString:@"LEFT"]) {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    } else if ([theme.hAlign isEqualToString:@"CENTER"]) {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    } else if ([theme.hAlign isEqualToString:@"RIGHT"]) {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
}

- (void)applyFont {
    UIFont *defaultFont = [UIFont systemFontOfSize:theme.fontSize.floatValue];
    UIFont *titleFont = [SwrveSDKUtils fontFromFile:theme.fontFile
                                      postscriptName:theme.fontPostscriptName
                                                size:theme.fontSize.floatValue
                                               style:theme.fontNativeStyle
                                        withFallback:defaultFont];

    CGFloat scaledPointSize = theme.fontSize.floatValue;
    if (self.calibration) {
        scaledPointSize = [SwrveSDKUtils scaleFont:titleFont
                                        calibration:self.calibration
                                      swrveFontSize:theme.fontSize.floatValue
                                        renderScale:self.renderScale];
    }
    self.titleLabel.font = [titleFont fontWithSize:scaledPointSize];

    if (theme.truncate) {
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    } else {
        self.titleLabel.numberOfLines = 1;
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [SwrveLogger debug:@"SwrveThemedUIButton scaled size: %f", self.titleLabel.font.pointSize];
        [self scaleDownTextWithBeginSize:scaledPointSize];
        [SwrveLogger debug:@"SwrveThemedUIButton fitted size: %f", self.titleLabel.font.pointSize];
        self.titleLabel.adjustsFontSizeToFitWidth = true;
    }
}

- (void)scaleDownTextWithBeginSize:(CGFloat)fontSize {
    NSString *text = self.titleLabel.text;
    if (text.length == 0 || CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        return;
    }

    CGFloat widthPaddingOffset = ([theme.leftPadding intValue] + [theme.rightPadding intValue] + [theme.borderWidth floatValue]) * renderScale;
    CGFloat heightPaddingOffset = ([theme.topPadding intValue] + [theme.bottomPadding intValue] + [theme.borderWidth floatValue]) * renderScale;

    CGFloat width = self.frame.size.width - widthPaddingOffset;
    CGFloat height = self.frame.size.height - heightPaddingOffset;

    CGSize constraintSize = CGSizeMake(width, height);
    while (fontSize > 1) {
        CGSize textRect = [self.titleLabel sizeThatFits:constraintSize];
        if (ceilf((float) textRect.height) <= height && ceilf((float) textRect.width) <= width) {
            break;
        }
        fontSize -= 1.0f; // Decrease the font size and try again
        self.titleLabel.font = [self.titleLabel.font fontWithSize:fontSize];
    }
}

- (void)applyFontColor {
    UIColor *titleColor = [SwrveUtils processHexColorValue:theme.fontColor];
    [self setTitleColor:titleColor forState:UIControlStateNormal];
    UIColor *titleColorPressed = [SwrveUtils processHexColorValue:theme.pressedState.fontColor];
    [self setTitleColor:titleColorPressed forState:UIControlStateHighlighted];
    if (theme.focusedState) {
        UIColor *titleColorFocused = [SwrveUtils processHexColorValue:theme.focusedState.fontColor];
        [self setTitleColor:titleColorFocused forState:UIControlStateFocused];
    }
}

- (void)applyCornerRadius {
    CGFloat cornerRadius = theme.cornerRadius.floatValue * self.renderScale;
    // check if radius is larger than half the width or half the height - if it is then use that
    if (cornerRadius >= self.frame.size.height / 2) {
        cornerRadius = self.frame.size.height / 2;
    }
    if (cornerRadius >= self.frame.size.width / 2) {
        cornerRadius = self.frame.size.width / 2;
    }
    self.layer.cornerRadius = cornerRadius;
}

- (void)applyBorder {
    if ([theme.borderWidth floatValue] > 0) {
        UIColor *borderColor = [SwrveUtils processHexColorValue:theme.borderColor];
        self.layer.borderColor = [borderColor CGColor];
        self.layer.borderWidth = [theme.borderWidth floatValue] * self.renderScale;
    }
}

- (void)applyBackground {
    if (theme.bgColor && [theme.bgColor length] > 0) {
        UIColor *bgDefault = [SwrveUtils processHexColorValue:theme.bgColor];
        self.backgroundColor = bgDefault;
    } else {
        UIImage *bgDefault = [self createUIImage:theme.bgImage];
        [self setBackgroundImage:bgDefault forState:UIControlStateNormal];
        UIImage *bgPressed = [self createUIImage:theme.pressedState.bgImage];
        [self setBackgroundImage:bgPressed forState:UIControlStateHighlighted];
        if (theme.focusedState) {
            UIImage *bgFocused = [self createUIImage:theme.focusedState.bgImage];
            [self setBackgroundImage:bgFocused forState:UIControlStateFocused];
        }
    }
}

- (UIImage *)createUIImage:(NSString *)assetName {
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSString *target = [cacheFolder stringByAppendingPathComponent:assetName];
    NSURL *fileImageURL = [NSURL fileURLWithPath:target];
    NSData *fileImageData = [NSData dataWithContentsOfURL:fileImageURL];
    return [UIImage imageWithData:fileImageData];
}

- (void)applyPadding {
    CGFloat topPadding = ([theme.topPadding floatValue] + [theme.borderWidth floatValue]) * self.renderScale;
    CGFloat leftPadding = ([theme.leftPadding floatValue] + [theme.borderWidth floatValue]) * self.renderScale;
    CGFloat bottomPadding = ([theme.bottomPadding floatValue] + [theme.borderWidth floatValue]) * self.renderScale;
    CGFloat rightPadding = ([theme.rightPadding floatValue] + [theme.borderWidth floatValue]) * self.renderScale;
    self.contentEdgeInsets = UIEdgeInsetsMake(topPadding, leftPadding, bottomPadding, rightPadding);
}

@end
