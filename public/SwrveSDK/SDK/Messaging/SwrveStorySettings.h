#import <Foundation/Foundation.h>

#if __has_include(<SwrveSDK/SwrveStoryDismissButton.h>)
#import <SwrveSDK/SwrveStoryDismissButton.h>
#else
#import "SwrveStoryDismissButton.h"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    kSwrveStoryLastPageProgressionDismiss,
    kSwrveStoryLastPageProgressionStop,
    kSwrveStoryLastPageProgressionLoop
} LastPageProgression;

@interface SwrveStorySettings : NSObject

@property(nonatomic) NSNumber *pageDuration; // milliseconds
@property(nonatomic) LastPageProgression lastPageProgression;
@property(nonatomic) NSNumber *lastPageDismissId;
@property(nonatomic) NSString *lastPageDismissName;
@property(nonatomic) NSNumber *topPadding;
@property(nonatomic) NSNumber *rightPadding;
@property(nonatomic) NSNumber *leftPadding;
@property(nonatomic) NSString *barColor;
@property(nonatomic) NSString *barBgColor;
@property(nonatomic) NSNumber *barHeight;
@property(nonatomic) NSNumber *segmentGap;
@property(nonatomic) BOOL gesturesEnabled;
@property(nonatomic) SwrveStoryDismissButton *dismissButton;

- (instancetype)initWithDictionary:(NSDictionary *)storySettings;

@end

NS_ASSUME_NONNULL_END
