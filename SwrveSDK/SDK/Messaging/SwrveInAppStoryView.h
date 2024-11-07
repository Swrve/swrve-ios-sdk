#import <UIKit/UIKit.h>
#if __has_include(<SwrveSDK/SwrveInAppStorySegmentDelegate.h>)
#import <SwrveSDK/SwrveInAppStorySegmentDelegate.h>
#import <SwrveSDK/SwrveMessageFormat.h>
#else
#import "SwrveInAppStorySegmentDelegate.h"
#import "SwrveMessageFormat.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SwrveInAppStoryView : UIView

@property(nonatomic) int currentIndex;

- (id)initWithFrame:(CGRect)frame
           delegate:(id <SwrveInAppStorySegmentDelegate>)storySegmentDelegate
      storySettings:(SwrveStorySettings *)swrveStorySettings
   numberOfSegments:(int)numberOfSegmentsToDisplay
        renderScale:(CGFloat)renderScale
      pageDurations:(NSArray *)pageDurations;


- (void)startSegmentAtIndex:(int)index;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
