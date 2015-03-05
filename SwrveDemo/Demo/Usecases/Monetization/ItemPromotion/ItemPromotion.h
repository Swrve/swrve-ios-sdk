#import "DemoFramework.h"

/*
 * A demo that shows how to respond to Swrve in-app messages and direct
 * users to an in app store front.
 */
@interface ItemPromotionDemo : Demo<SwrveMessageDelegate> {

}

/*
 * DOC
 */
- (IBAction)onShowOffer:(id)sender;

@end
