#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveMessageFocus : NSObject

- (id)initWithView:(UIView *)rootView;

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context;

@end

NS_ASSUME_NONNULL_END
