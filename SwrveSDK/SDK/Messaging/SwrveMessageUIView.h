#import <UIKit/UIKit.h>

#if __has_include(<SwrveSDK/SwrveMessageFormat.h>)
#import <SwrveSDK/SwrveMessageFormat.h>
#else
#import "SwrveMessageFormat.h"
#endif

@class SwrveInAppMessageConfig;

NS_ASSUME_NONNULL_BEGIN

@interface SwrveMessageUIView : UIView

@property (nonatomic) BOOL renderError;

- (id)initWithMessageFormat:(SwrveMessageFormat *)format
                     pageId:(NSNumber *)pageId
                 parentSize:(CGSize)sizeParent
                 controller:(UIViewController *)delegate
            personalization:(NSDictionary *)personalizationDict
                inAppConfig:(SwrveInAppMessageConfig *)config;
@end

NS_ASSUME_NONNULL_END
