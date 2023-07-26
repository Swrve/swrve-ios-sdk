#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwrveInAppMessageFocusDelegate <NSObject>

@optional

/*! Use this delegate in SwrveInAppMessageConfig to configure button focus changes. For tvOS only.
 * \param context provides focus update information.
 * \param coordinator used for focus-related animations.
 * \param parent the parent view.
 */
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
                     parentView:(UIView *)parent;

@end

NS_ASSUME_NONNULL_END
