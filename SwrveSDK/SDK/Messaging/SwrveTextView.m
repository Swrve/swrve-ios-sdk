#import "SwrveTextView.h"
#import "SwrveTextImageView.h"

#if __has_include(<SwrveSDKCommon/TextTemplating.h>)
#import <SwrveSDKCommon/TextTemplating.h>
#import <SwrveSDKCommon/SwrveLogger.h>
#else
#import "TextTemplating.h"
#import "SwrveLogger.h"
#endif

@implementation SwrveTextView

- (id)initWithStyle:(SwrveTextViewStyle *)style calbration:(SwrveCalibration *)calibration frame:(CGRect)frame {
    if (self = [super init]) {
        self.frame = frame;
        self.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        self.selectable = true;
        self.scrollEnabled = false;
#if TARGET_OS_IOS /** exclude tvOS **/
        self.scrollEnabled = style.scrollable;
        self.editable = false;
        self.dataDetectorTypes = UIDataDetectorTypeLink;
#endif
        self.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.textContainer.lineFragmentPadding = 0;
        self.textAlignment = style.textAlignment;
    
        self.text = style.text;
        self.backgroundColor = style.backgroundColor;
        self.textColor = style.foregroundColor;
        
        CGFloat scaledPointSize = style.fontsize;
        
        if (calibration.calibrationFontSize != 0.0f ||
            calibration.calibrationWidth != 0.0f ||
            calibration.calibrationHeight != 0.0f ||
            (calibration.calibrationText != nil && ![calibration.calibrationText isEqualToString:@""])) {
            
            scaledPointSize = [self scaleFont:calibration style:style];
        }
        
        if (style.scrollable && TARGET_OS_IOS) {
            self.showsVerticalScrollIndicator = true;
            
            if (@available(iOS 11.0,tvOS 11.0, *)) {
                UIFontMetrics *metrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleBody];
                self.font = [metrics scaledFontForFont:[style.font fontWithSize:scaledPointSize]];
                self.adjustsFontForContentSizeCategory = true;
            } else {
                self.font = [style.font fontWithSize:scaledPointSize];
            }
        } else {
            self.font = [style.font fontWithSize:scaledPointSize];
            [SwrveLogger debug:@"SwrveTextview point size: %f", self.font.pointSize];
            [self scaleDownFontSize];
        }
    }
    return self;
}

- (void)scaleDownFontSize {
    if (self.text.length == 0 || CGSizeEqualToSize(self.bounds.size, CGSizeZero)) return;

    /*
     - Update textView font size
     If expectHeight > textViewHeight => descrease font size by 0.5 point until it reachs textViewHeight
     */
    CGSize textViewSize = self.frame.size;
    CGFloat fixedWidth = textViewSize.width;
    CGSize expectSize = [self sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
    CGFloat step = 0.5;
    UIFont *expectFont = self.font;
    if (expectSize.height > textViewSize.height) {
        while (self.font.pointSize > 1 && [self sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)].height > textViewSize.height) {
            expectFont = [self.font fontWithSize:(self.font.pointSize - step)];
            self.font = expectFont;
            [SwrveLogger debug:@"Decreasing SwrveTextView point size to %f to fit container", self.font.pointSize];
        }
    }
}

- (CGFloat)scaleFont:(SwrveCalibration *)calibration style:(SwrveTextViewStyle *)style {
    //TODO: SWRVE-29198 - Remove scaled by
    CGFloat calibrationWidth = calibration.calibrationWidth * calibration.renderScale;
    CGFloat calibrationHeight = calibration.calibrationHeight * calibration.renderScale;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    CGFloat maxFontSize = 200.0f;
    NSDictionary *baseAttributes = @{ NSFontAttributeName: [style.font fontWithSize:maxFontSize],
                                      NSParagraphStyleAttributeName:paragraphStyle};

    CGFloat osSizeForTemplate = [SwrveTextImageView fitTextSize:calibration.calibrationText withAttributes:baseAttributes maxWidth:calibrationWidth maxHeight:calibrationHeight maxFontSize:maxFontSize];
    
    CGFloat scaledFont = (style.fontsize / calibration.calibrationFontSize) * osSizeForTemplate;

    return scaledFont;
}

@end
