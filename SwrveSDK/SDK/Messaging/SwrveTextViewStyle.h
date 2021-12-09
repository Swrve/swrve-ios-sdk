#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveTextViewStyle : NSObject

// populated from mulitline text object
@property (nonatomic) CGFloat fontsize;
@property (nonatomic) NSString *text;
@property (nonatomic) NSTextAlignment textAlignment;
@property (nonatomic, assign) BOOL scrollable;

// populated from in app config
@property (nonatomic) UIFont *font;
@property (nonatomic) UIColor *foregroundColor;
@property (nonatomic) UIColor *backgroundColor;

- (instancetype)initWithDictionary:(NSDictionary *)style;

@end

NS_ASSUME_NONNULL_END
