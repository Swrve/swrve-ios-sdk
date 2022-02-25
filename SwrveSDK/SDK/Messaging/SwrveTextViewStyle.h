#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveTextViewStyle : NSObject

// populated from mulitline text object
@property (nonatomic) CGFloat fontsize;
@property (nonatomic) NSString *text;
@property (nonatomic) NSTextAlignment textAlignment;
@property (nonatomic, assign) BOOL scrollable;
@property (nonatomic) NSString *font_postscript_name;
@property (nonatomic) NSString *font_native_style;  // weight: Normal, Bold, Italic, BoldItalic if system font
@property (nonatomic) NSString *font_file; // has a value of "_system_font_" when system-font is the selected font
@property (nonatomic) NSString *font_digest;
@property (nonatomic) NSDictionary *padding;
@property (nonatomic) CGFloat line_height;
@property (nonatomic) int topPadding;
@property (nonatomic) int rightPadding;
@property (nonatomic) int bottomPadding;
@property (nonatomic) int leftPadding;

//default populated from in app config, can be overriden by server values
@property (nonatomic) UIFont *font;
@property (nonatomic) UIColor *foregroundColor;
@property (nonatomic) UIColor *backgroundColor;

- (instancetype)initWithDictionary:(NSDictionary *)style
                       defaultFont:(UIFont *)defaultFont
            defaultForegroundColor:(UIColor *)defaultForegroundColor
            defaultBackgroundColor:(UIColor *)defaultBackgroundColor;

@end

NS_ASSUME_NONNULL_END
