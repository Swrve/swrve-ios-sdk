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
        self.textContainerInset = UIEdgeInsetsMake(style.topPadding * calibration.renderScale,
                                                   style.leftPadding * calibration.renderScale,
                                                   style.bottomPadding * calibration.renderScale,
                                                   style.rightPadding * calibration.renderScale);

        self.textContainer.lineFragmentPadding = 0;
        self.textAlignment = style.textAlignment;
            
        self.backgroundColor = style.backgroundColor;

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
            [self styleAttributedText:style];
        } else {
            self.font = [style.font fontWithSize:scaledPointSize];
            [SwrveLogger debug:@"SwrveTextview scaled size: %f", self.font.pointSize];
            [self scaleDownFontSize:style calibration:calibration];
            [SwrveLogger debug:@"SwrveTextview fitted size: %f", self.font.pointSize];
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

- (void)scaleDownFontSize:(SwrveTextViewStyle *)style calibration:(SwrveCalibration *)calibration {
    if (style.text.length == 0 || CGSizeEqualToSize(self.bounds.size, CGSizeZero)) return;
    
    CGFloat widthPaddingOfset = (style.leftPadding + style.rightPadding) * calibration.renderScale;
    CGFloat heightPaddingOfset = (style.topPadding + style.bottomPadding) * calibration.renderScale;
    
    // use boundingRectWithSize to take line spacing into account while scaling.
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.lineBreakStrategy = NSLineBreakStrategyPushOut;
    paragraphStyle.alignment = style.textAlignment;
 
    CGFloat width = self.frame.size.width - widthPaddingOfset;
    CGFloat height = self.frame.size.height - heightPaddingOfset;

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

- (CGFloat)scaleFont:(SwrveCalibration *)calibration style:(SwrveTextViewStyle *)style {
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
