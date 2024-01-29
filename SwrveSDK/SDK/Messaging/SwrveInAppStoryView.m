#import "SwrveInAppStoryView.h"

#if __has_include(<SwrveSDKCommon/SwrveUtils.h>)
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveUtils.h"
#endif

@interface SwrveInAppStoryView ()

@property(nonatomic, weak) id <SwrveInAppStorySegmentDelegate> segmentDelegate;
@property(nonatomic) SwrveStorySettings *storySettings;
@property(nonatomic, strong) NSMutableArray<UIView *> *segmentProgressViews;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic) CGFloat segmentMaxWidth;
@property(nonatomic) int numberOfSegments;
@property(nonatomic) CGFloat renderScale;
@property(nonatomic) NSArray *pageDurations;

@end

@implementation SwrveInAppStoryView

@synthesize segmentDelegate;
@synthesize storySettings;
@synthesize segmentProgressViews;
@synthesize timer;
@synthesize segmentMaxWidth;
@synthesize numberOfSegments;
@synthesize renderScale;
@synthesize currentIndex;
@synthesize pageDurations;

const int PROGRESS_SPEED = 1000;

- (id)initWithFrame:(CGRect)frame
           delegate:(id <SwrveInAppStorySegmentDelegate>)storySegmentDelegate
      storySettings:(SwrveStorySettings *)swrveStorySettings
   numberOfSegments:(int)numberOfSegmentsToDisplay
        renderScale:(CGFloat)renderScaleFloat
      pageDurations:(NSArray *)pageDurationsArray {
    self = [super initWithFrame:frame];
    if (self) {
        self.segmentDelegate = storySegmentDelegate;
        self.storySettings = swrveStorySettings;
        self.numberOfSegments = numberOfSegmentsToDisplay;
        self.renderScale = renderScaleFloat;
        self.pageDurations = pageDurationsArray;
        self.segmentProgressViews = [[NSMutableArray alloc] init];
        [self drawSegments];
    }
    return self;
}

- (void)drawSegments {
    UIColor *progressColor = [SwrveUtils processHexColorValue:self.storySettings.barColor];
    UIColor *trackColor = [SwrveUtils processHexColorValue:self.storySettings.barBgColor];
    CGFloat paddingBetweenSegments = self.storySettings.segmentGap.floatValue * self.renderScale;
    CGFloat remainingWidth = self.frame.size.width - (paddingBetweenSegments * (CGFloat) (self.numberOfSegments - 1));
    CGFloat widthOfSegment = remainingWidth / (CGFloat) self.numberOfSegments;
    CGFloat heightOfSegment = self.frame.size.height;
    CGFloat cornerRadius = heightOfSegment / 2;
    self.segmentMaxWidth = widthOfSegment;

    CGFloat originX = 0;
    CGFloat originY = 0;
    for (int index = 0; index < self.numberOfSegments; index++) {
        // Create track view
        originX = (CGFloat) index * widthOfSegment + (CGFloat) index * paddingBetweenSegments;
        CGRect frameOfTrackView = CGRectMake(originX, originY, widthOfSegment, heightOfSegment);
        UIView *trackView = [self createSegmentView:trackColor cornerRadius:cornerRadius];
        trackView.frame = frameOfTrackView;
        [self addSubview:trackView];

        // Create progress view and add as a subview of the track view
        CGRect defaultFrameOfProgressView = CGRectMake(0, 0, 0, heightOfSegment);
        UIView *progressView = [self createSegmentView:progressColor cornerRadius:cornerRadius];
        progressView.frame = defaultFrameOfProgressView;
        [trackView addSubview:progressView];

        [self.segmentProgressViews addObject:progressView]; // Keep reference to progressViews for animation later
    }
}

- (UIView *)createSegmentView:(UIColor *)backgroundColor
                 cornerRadius:(CGFloat)segmentCornerRadius {
    UIView *segment = [[UIView alloc] init];
    segment.layer.cornerRadius = segmentCornerRadius;
    segment.clipsToBounds = YES;
    segment.userInteractionEnabled = NO;
    segment.backgroundColor = backgroundColor;
    return segment;
}

- (void)animateSegment {
    if (self.currentIndex < (int) self.segmentProgressViews.count) {
        UIView *progressView = self.segmentProgressViews[(NSUInteger) self.currentIndex];
        CGFloat lastProgressWidth = progressView.frame.size.width;
        CGFloat newProgressWidth = lastProgressWidth + [self progressIntervalWidth];
        [self updateWidthForView:progressView newWidth:newProgressWidth];

        if (newProgressWidth >= self.segmentMaxWidth) {
            NSUInteger segmentFinishedIndex = (NSUInteger) self.currentIndex;
            if (self.currentIndex < self.numberOfSegments - 1) {
                self.currentIndex = self.currentIndex + 1;
                UIView *progressView1 = self.segmentProgressViews[(NSUInteger) self.currentIndex];
                [self updateWidthForView:progressView1 newWidth:0];
            } else {
                [self.timer invalidate];
                self.timer = nil;
            }

            id <SwrveInAppStorySegmentDelegate> strongDelegate = self.segmentDelegate;
            if (strongDelegate) {
                [strongDelegate segmentFinishedAtIndex:segmentFinishedIndex];
            }
        }
    }
}

- (void)updateWidthForView:(UIView *)view newWidth:(CGFloat)newWidth {
    CGRect frame = view.frame;
    frame.size.width = newWidth;
    view.frame = frame;
}

- (CGFloat)progressIntervalWidth {
    NSNumber *pageDuration;
    if (self.pageDurations && self.pageDurations.count > 0) {
        pageDuration = self.pageDurations[(NSUInteger) self.currentIndex];
    } else {
        pageDuration = self.storySettings.pageDuration;
    }
    double pageDurationSeconds = pageDuration.doubleValue / 1000;
    CGFloat value = pageDurationSeconds * PROGRESS_SPEED;
    return self.segmentMaxWidth / value;
}

- (void)setUpTimer {
    if (!self.timer) {
        double interval = 1.0 / PROGRESS_SPEED;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self
                                                    selector:@selector(animateSegment)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (void)startSegmentAtIndex:(int)index {
    if (index < 0 || index > ((int) self.segmentProgressViews.count - 1)) {
        return;
    }

    if (index > self.currentIndex) {
        for (int i = self.currentIndex; i < index; i++) {
            UIView *progressView = self.segmentProgressViews[(NSUInteger) i];
            [self updateWidthForView:progressView newWidth:self.segmentMaxWidth];
        }
    } else if (index < self.currentIndex) {
        for (int i = self.currentIndex; i >= index; i--) {
            UIView *progressView = self.segmentProgressViews[(NSUInteger) i];
            [self updateWidthForView:progressView newWidth:0];
        }
    }
    self.currentIndex = index;
    [self animateSegment];
    [self setUpTimer];
}

- (void)stop {
    if (self.timer) {
        [self.timer invalidate];
    }
}

@end
