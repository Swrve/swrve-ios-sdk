#import <UIKit/UIKit.h>

#import "SwrveMessageFormat.h"
#import "SwrveInAppMessageConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveMessageUIView : UIView

- (id)initWithMessageFormat:(SwrveMessageFormat *)format
                     pageId:(NSNumber *)pageId
                 parentSize:(CGSize)sizeParent
                 controller:(UIViewController *)delegate
            personalization:(NSDictionary *)personalizationDict
                inAppConfig:(SwrveInAppMessageConfig *)config;
@end

NS_ASSUME_NONNULL_END
