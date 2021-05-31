#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwrveDeeplinkDelegate <NSObject>

@optional

/*! The Swrve SDK currently processes deeplinks with openUrl. This may not work if the
 * the link is a universal link. Use this delegate to overide that processing and use your own
 * implementation
 * \param nsurl NSURL to be processed.
 */
- (void)handleDeeplink:(NSURL *)nsurl;

@end

NS_ASSUME_NONNULL_END
