#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwrveInAppStorySegmentDelegate <NSObject>

@optional

- (void)segmentFinishedAtIndex:(NSUInteger)segmentIndex;

@end

NS_ASSUME_NONNULL_END
