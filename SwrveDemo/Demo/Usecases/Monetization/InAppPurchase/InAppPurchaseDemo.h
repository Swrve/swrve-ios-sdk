#import "DemoFramework.h"

@interface InAppPurchaseDemo : Demo <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    
    // Array of products that are available in the demo.  These are downloaded
    // from apple store when the demo is started. 
    NSArray *products;
    
    // Amount to multiply curreices by for special sales.  Used by other demos
    // to show promo offers.
    float currencyMultiplier;
}

@property (nonatomic,retain) IBOutlet UILabel *item1_price;
@property (nonatomic,retain) IBOutlet UILabel *item1_quantity;
@property (nonatomic,retain) IBOutlet UILabel *item2_price;
@property (nonatomic,retain) IBOutlet UILabel *item2_quantity;
@property (nonatomic,retain) IBOutlet UILabel *item3_price;
@property (nonatomic,retain) IBOutlet UILabel *item3_quantity;
@property (nonatomic,retain) IBOutlet UIView *paymentsAreDisabledView;
@property (nonatomic,retain) IBOutlet UIView *couldNotLoadView;
@property (nonatomic,retain) IBOutlet UIView *storeView;

/*
 * Initializes the demo
 */
-(id) init;

/*
 * Initializes with a currency multiplier
 */
-(id) initWithCurrencyMultiplier:(float) multiplier;

/*
 * Creates and registered overrideable resources used in the demo
 */
-(void) createResources:(DemoResourceManager *) resourceManager;

/*
 * Called when the demo starts
 */
-(void) onEnterDemo;

/*
 * Called when the demo finishes
 */
-(void) onExitDemo;

/*
 * Called when a user clicks on a pack to purchase it
 */
- (IBAction)onBuyPack:(id)sender;

@end
