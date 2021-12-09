#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveCalibration : NSObject

@property (nonatomic) CGFloat renderScale;
@property (nonatomic) CGFloat calibrationWidth;
@property (nonatomic) CGFloat calibrationHeight;
@property (nonatomic) CGFloat calibrationFontSize;
@property (nonatomic) NSString *calibrationText;

- (instancetype)initWithDictionary:(NSDictionary *)calibration;

@end

NS_ASSUME_NONNULL_END
