#import <UIKit/UIKit.h>
#import "SwrveMessageFormat.h"
#import "SwrveInAppStorySegmentDelegate.h"

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
