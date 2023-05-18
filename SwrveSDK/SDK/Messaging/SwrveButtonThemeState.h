#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveButtonThemeState : NSObject

@property(nonatomic, retain) NSString *fontColor;
@property(nonatomic, retain) NSString *bgColor;
@property(nonatomic, retain) NSString *borderColor;
@property(nonatomic, retain) NSString *bgImage;

- (id)initWithDictionary:(NSDictionary *)themeState;

@end

NS_ASSUME_NONNULL_END
