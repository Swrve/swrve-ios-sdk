#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveButtonThemeState : NSObject

@property(nonatomic, retain, nullable) NSString *fontColor;
@property(nonatomic, retain, nullable) NSString *bgColor;
@property(nonatomic, retain, nullable) NSString *borderColor;
@property(nonatomic, retain, nullable) NSString *bgImage;

- (id)initWithDictionary:(NSDictionary *)themeState;

@end

NS_ASSUME_NONNULL_END
