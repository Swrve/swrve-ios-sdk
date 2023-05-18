#import "SwrveUITextView.h"
#import "SwrveTextUtils.h"

#if __has_include(<SwrveSDKCommon/TextTemplating.h>)
#import <SwrveSDKCommon/TextTemplating.h>
#import <SwrveSDKCommon/SwrveLogger.h>
#else
#import "TextTemplating.h"
#import "SwrveLogger.h"
#endif

@implementation SwrveUITextView

- (id)initWithStyle:(SwrveTextViewStyle *)style
         calbration:(SwrveCalibration *)calibration
              frame:(CGRect)frame
        renderScale:(CGFloat)renderScale {
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
        self.textContainerInset = UIEdgeInsetsMake(style.topPadding * renderScale,
                                                   style.leftPadding * renderScale,
                                                   style.bottomPadding * renderScale,
                                                   style.rightPadding * renderScale);

        self.textContainer.lineFragmentPadding = 0;
        self.textAlignment = style.textAlignment;
            
        self.backgroundColor = style.backgroundColor;

        CGFloat scaledPointSize = style.fontsize;
        
        if (calibration.calibrationFontSize != 0.0f ||
            calibration.calibrationWidth != 0.0f ||
            calibration.calibrationHeight != 0.0f ||
            (calibration.calibrationText != nil && ![calibration.calibrationText isEqualToString:@""])) {

            scaledPointSize = [SwrveTextUtils scaleFont:style.font
                                        calibration:calibration
                                      swrveFontSize:style.fontsize
                                        renderScale:renderScale];
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
            [self styleAttributedText:style];
        } else {
            self.font = [style.font fontWithSize:scaledPointSize];
            [SwrveLogger debug:@"SwrveUITextView scaled size: %f", self.font.pointSize];
            [self scaleDownFontSize:style renderScale:renderScale];
            [SwrveLogger debug:@"SwrveUITextView fitted size: %f", self.font.pointSize];
            [self styleAttributedText:style];
        }
    }

    return self;
}

- (void)styleAttributedText:(SwrveTextViewStyle *)style {
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

    if (style.line_height > 0) {
        CGFloat spacing = (self.font.pointSize * style.line_height) - self.font.lineHeight;
        paragraphStyle.lineSpacing = spacing;
    }

    paragraphStyle.alignment =  style.textAlignment;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.lineBreakStrategy = NSLineBreakStrategyPushOut;
  

    NSDictionary *attributes = @{NSForegroundColorAttributeName:style.foregroundColor,
                                 NSParagraphStyleAttributeName:paragraphStyle,
                                 NSFontAttributeName: self.font
    };
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:style.text attributes:attributes];
    self.attributedText = attributedText;
}

- (void)scaleDownFontSize:(SwrveTextViewStyle *)style renderScale:(CGFloat)renderScale {
    if (style.text.length == 0 || CGSizeEqualToSize(self.bounds.size, CGSizeZero)) return;

    CGFloat widthPaddingOffset = (style.leftPadding + style.rightPadding) * renderScale;
    CGFloat heightPaddingOffset = (style.topPadding + style.bottomPadding) * renderScale;
    
    // use boundingRectWithSize to take line spacing into account while scaling.
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.lineBreakStrategy = NSLineBreakStrategyPushOut;
    paragraphStyle.alignment = style.textAlignment;
 
    CGFloat width = self.frame.size.width - widthPaddingOffset;
    CGFloat height = self.frame.size.height - heightPaddingOffset;

    CGFloat fontSize = self.font.pointSize;
    CGSize constraintSize = CGSizeMake(width, CGFLOAT_MAX);
    
    do {
        
        if (style.line_height > 0) {
            CGFloat linespacing = (self.font.pointSize * style.line_height) - self.font.lineHeight;
            paragraphStyle.lineSpacing = linespacing;
        }

        NSDictionary *baseAttributes = @{ NSFontAttributeName:[self.font fontWithSize:fontSize],
                                          NSParagraphStyleAttributeName:paragraphStyle};
        
        CGRect textRect = [style.text boundingRectWithSize:constraintSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingUsesDeviceMetrics
                                                  attributes:baseAttributes
                                                     context:nil];
        
        if(ceilf((float)textRect.size.height) <= height)
            break;

        // Decrease the font size and try again
        fontSize -= 1.0f;
        
        self.font = [self.font fontWithSize:fontSize];

    } while (fontSize > 1);
    
}

@end
