//
//  ItemPromotion.h
//  SwrveDemoFramework
//
//  Copyright (c) 2010-2014 Swrve. All rights reserved.
//

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
