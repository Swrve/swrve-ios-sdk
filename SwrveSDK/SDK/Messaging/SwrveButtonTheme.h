#import <Foundation/Foundation.h>

#import "SwrveButtonThemeState.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveButtonTheme : NSObject

@property(atomic) NSNumber *fontSize;
@property(nonatomic, retain) NSString *fontFile; // has a value of "_system_font_" when system-font is the selected font
@property(nonatomic, retain) NSString *fontDigest;
@property(nonatomic, retain) NSString *fontNativeStyle; // weight: Normal, Bold, Italic, BoldItalic if system font
@property(nonatomic, retain) NSString *fontPostscriptName;
@property(atomic) NSNumber *topPadding;
@property(atomic) NSNumber *rightPadding;
@property(atomic) NSNumber *bottomPadding;
@property(atomic) NSNumber *leftPadding;
@property(atomic) NSNumber *cornerRadius;
@property(nonatomic, retain) NSString *fontColor;
@property(nonatomic, retain) NSString *bgColor;
@property(atomic) NSNumber *borderWidth;
@property(nonatomic, retain) NSString *borderColor;
@property(nonatomic, retain) NSString *bgImage;
@property(atomic) bool truncate;
@property(nonatomic, retain) SwrveButtonThemeState *pressedState;
@property(nonatomic, retain) SwrveButtonThemeState *focusedState;
@property(nonatomic, retain) NSString *hAlign;

- (id)initWithDictionary:(NSDictionary *)themeData;

@end

NS_ASSUME_NONNULL_END
