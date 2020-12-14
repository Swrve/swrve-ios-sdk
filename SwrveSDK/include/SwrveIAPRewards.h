#import <Foundation/Foundation.h>

/*! SwrveIAPRewards contains additional IAP rewards that you want to send to Swrve.
 *
 * If the IAP represents a bundle containing a few reward items and/or
 * in-app currencies you can create a SwrveIAPRewards object and call
 * addCurrency: and addItem: for each element contained in the bundle.
 * By including this when recording an IAP event with Swrve you will be able to track
 * individual bundle items as well as the bundle purchase itself.
 */
@interface SwrveIAPRewards : NSObject

/*! Add a purchased item
 *
 * \param resourceName The name of the resource item with which the user was rewarded.
 * \param quantity The quantity purchased
 */
- (void) addItem:(NSString*) resourceName withQuantity:(long) quantity;

/*! Add an in-app currency purchase
 *
 * \param currencyName The name of the in-app currency with which the user was rewarded.
 * \param amount The amount of in-app currency with which the user was rewarded.
 */
- (void) addCurrency:(NSString*) currencyName withAmount:(long) amount;


/*! Obtain all rewards.
 *
 * \returns All rewards added up until now.
 */
- (NSDictionary*) rewards;

@end
