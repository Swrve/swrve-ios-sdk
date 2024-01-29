#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveStoryDismissButton : NSObject

@property(nonatomic) NSNumber *buttonId;
@property(nonatomic) NSString *name;
@property(nonatomic) NSString *color;
@property(nonatomic) NSString *pressedColor;
@property(nonatomic) NSString *focusedColor;
@property(nonatomic) NSNumber *size;
@property(nonatomic) NSNumber *marginTop;
@property(nonatomic) NSString *accessibilityText;

- (instancetype)initWithDictionary:(NSDictionary *)storySettings;

@end

NS_ASSUME_NONNULL_END
