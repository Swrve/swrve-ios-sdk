#import "InAppPurchaseDemo.h"

@implementation InAppPurchaseDemo

@synthesize item1_price;
@synthesize item1_quantity;
@synthesize item2_price;
@synthesize item2_quantity;
@synthesize item3_price;
@synthesize item3_quantity;
@synthesize paymentsAreDisabledView;
@synthesize couldNotLoadView;
@synthesize storeView;

-(id) init
{
    self = [self initWithCurrencyMultiplier:1.0f];
    return self;
}

-(id) initWithCurrencyMultiplier:(float) multiplier
{
    if( self = [super initWithNibName:@"InAppPurchaseDemo" bundle:nil] )
    {
        currencyMultiplier = multiplier;
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    return self;
}

-(void) createResources:(DemoResourceManager *) resourceManager;
{
    DemoResource *birdPack1 = [[DemoResource alloc] init:@"com.swrve.bird_pack1"
                                            withAttributes:@{
                                                @"productId": @"com.swrve.bird_pack1",
                                                @"amount_to_show": @"10"
                                            }
                                ];
    
    NSArray* birdPack2_currencies = [[NSArray alloc] initWithObjects:@{@"name": @"Birds", @"amount": @250}, nil];
    DemoResource *birdPack2 = [[DemoResource alloc] init:@"com.swrve.bird_pack2"
                                            withAttributes:@{
                                                @"productId": @"com.swrve.bird_pack2",
                                                @"amount_to_show": @"250",
                                                @"reward_currencies": birdPack2_currencies
                                            }
                                ];
    
    NSArray* birdPack3_currencies = [[NSArray alloc] initWithObjects:@{@"name": @"Birds", @"amount": @1000}, @{@"name": @"Gold", @"amount": @250}, nil];
    NSArray* birdPack3_items = [[NSArray alloc] initWithObjects:@{@"name": @"Cage", @"amount": @1}, nil];
    DemoResource *birdPack3 = [[DemoResource alloc] init:@"com.swrve.bird_pack3"
                                            withAttributes:@{
                                                @"productId": @"com.swrve.bird_pack3",
                                                @"amount_to_show": @"1000",
                                                @"reward_currencies": birdPack3_currencies,
                                                @"reward_items": birdPack3_items
                                            }
                                ];

    DemoResource *iapResource = [[DemoResource alloc] init:@"birds_iap_sheet"
                                              withAttributes:@{ @"item.count" : @"3",
                                                                @"item.0": @"com.swrve.bird_pack1",
                                                                @"item.1": @"com.swrve.bird_pack2",
                                                                @"item.2": @"com.swrve.bird_pack3"}];
    // Finally, register the resources with your resource manager.
    [resourceManager addResource:birdPack1];
    [resourceManager addResource:birdPack2];
    [resourceManager addResource:birdPack3];
    [resourceManager addResource:iapResource];
}

-(void) onEnterDemo
{
    [self scaleIAPCurrencies:currencyMultiplier];
    [self requestInAppPurchases];
}

-(void) onExitDemo
{
    [self leftStore];
    [self scaleIAPCurrencies:1.0f / currencyMultiplier];
}

- (void) requestInAppPurchases
{
    // Show cannot make payments screen if payments are disabled
    if ([SKPaymentQueue canMakePayments] == NO)
    {
        [UIView transitionFromView:self.view
                            toView:paymentsAreDisabledView
                          duration:0.65f
                           options:UIViewAnimationOptionTransitionCurlUp
                        completion:nil];
        
        // [TRACK] How often are payments disabled on devices?
        [[DemoFramework getSwrve] event:@"Swrve.Demo.Monetization.PaymentsDisabled"];
        return;
    }

    // Look up the resource that tells you what items are in the store front.
    DemoResource* iapResource = [[DemoFramework getDemoResourceManager] lookupResource:@"birds_iap_sheet"];
    
    // Look up the items
    NSArray* items = [iapResource getAttributeAsArrayOfString:@"item"];
    
    // Look up product IDs for each item
    NSMutableSet* productIds = [[NSMutableSet alloc] initWithCapacity:items.count];
    for( unsigned int itemIndex = 0; itemIndex < items.count; ++itemIndex )
    {
        DemoResource* item = [[DemoFramework getDemoResourceManager] lookupResource:items[itemIndex]];
        [productIds addObject:[item getAttributeAsString:@"productId"]];
    }
    
    // Request the products from the app store.  This call is asynchronous.  The productsRequest
    // method will be called when the request returns.
    SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: productIds];
    request.delegate = self;
    [request start];
}

- (void)request:(SKRequest*)request didFailWithError:(NSError *)error
{
    #pragma unused(request)
    NSLog(@"Error reading app store request: %@ %@", [error description], [error localizedFailureReason]);
    NSLog(@"Error: Could not connect to iTunes Store. Note that in Xcode 5 StoreKit and anything related to in-app purchases has been disabled in the simulator, so if you are using the simulator to run this please try on a device instead.");
    [UIView transitionFromView:self.view
                        toView:couldNotLoadView
                      duration:0.65f
                       options:0
                    completion:nil];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    #pragma unused(request)
    // Get the products requested
    products = response.products;
    
    NSLog(@"Invalid identifiers:%@", [response invalidProductIdentifiers]);

    // Show cannot connect screen if no products were returned
    if ([products count] < 1)
    {
        [UIView transitionFromView:self.view
                            toView:couldNotLoadView
                          duration:0.65f
                           options:UIViewAnimationOptionTransitionCurlUp
                        completion:nil];
        
        // [TRACK] How often does the app store not give us products?
        [[DemoFramework getSwrve] event:@"Swrve.Demo.Monetization.ProductsDidNotLoad"];
        //return;
    }

    DemoResourceManager* resourceManager = [DemoFramework getDemoResourceManager];
    
    // Get the three products that will be shown in the store.  These products
    // tell you how much each gem pack is.  We assume that the products in this
    // array are in the same order that we requested them in.
    SKProduct* product0 = [products objectAtIndex:0];
    SKProduct* product1 = [products objectAtIndex:1];
    SKProduct* product2 = [products objectAtIndex:2];
    
    // Set the values in the UI
    self.item1_quantity.text = [[resourceManager lookupResource:product0.productIdentifier] getAttributeAsString:@"amount_to_show"];
    self.item1_price.text = [self priceAsString:product0];
    self.item2_quantity.text = [[resourceManager lookupResource:product1.productIdentifier] getAttributeAsString:@"amount_to_show"];
    self.item2_price.text = [self priceAsString:product1];
    self.item3_quantity.text = [[resourceManager lookupResource:product2.productIdentifier] getAttributeAsString:@"amount_to_show"];
    self.item3_price.text = [self priceAsString:product2];
    
    // Show the store
    [UIView transitionFromView:self.view
                        toView:storeView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCurlUp
                    completion:nil];
    
    // [TRACK] How often is the store opened?
    [[DemoFramework getSwrve] event:@"Swrve.Demo.Monetization.Store.Enter"];
}

- (IBAction)onBuyPack:(id)sender
{
    UIButton *button = (UIButton*)sender;
    if (button.tag == 1)
    {
        [self purchaseProduct:products[0]];
    }
    else if (button.tag == 2)
    {
        [self purchaseProduct:products[1]];
    }
    else if (button.tag == 3)
    {
        [self purchaseProduct:products[2]];
    }
}

- (void) purchaseProduct:(SKProduct*) product
{
    // Submit the payment to the app store
    SKPayment* payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    // [TRACK] When a transactions starts
    [[DemoFramework getSwrve]event:@"Swrve.Demo.Monetization.Store.Purchase"
                           payload:[NSDictionary dictionaryWithObject:@"start" forKey:@"progress"]];
}

- (void) processTransactions:(NSArray *)transactions onQueue:(SKPaymentQueue *)queue
{
    #pragma unused(queue)
    for (SKPaymentTransaction *transaction in transactions)
    {
        // Find the product that is being processed
        SKProduct* purchasedProduct = NULL;
        for( unsigned int productIndex = 0; productIndex < products.count; ++productIndex )
        {
            SKProduct* product = products[productIndex];
            if( [product.productIdentifier isEqualToString:transaction.payment.productIdentifier] )
            {
                purchasedProduct = product;
                break;
            }
        }
    
        // Handle logic for store kit
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                // Look up the purchased product.
                if( purchasedProduct != nil ) {
                    
                    // Tell the user
                    NSString* message = [[NSString alloc] initWithFormat:@"Thank you for your purchase!"];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Purchase Completed successfully" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                }
                
                break;
            case SKPaymentTransactionStateFailed:
                break;
            case SKPaymentTransactionStateRestored:
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self processTransactions:queue.transactions onQueue:queue];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    [self processTransactions:transactions onQueue:queue];
}

- (void) leftStore
{
    // [TRACK] How often do users leave?
    [[DemoFramework getSwrve]event:@"Swrve.Demo.Monetization.Store.Exit"];
}

- (void) scaleIAPCurrencies:(float) scale
{
    // Look up the resource that tells you what items are in the store front.
    DemoResource* iapResource = [[DemoFramework getDemoResourceManager] lookupResource:@"birds_iap_sheet"];
    
    // Look up the items
    NSArray* items = [iapResource getAttributeAsArrayOfString:@"item"];
    
    // Multiply the amount of currency that the user gets for each pack
    for( unsigned int itemIndex = 0; itemIndex < items.count; ++itemIndex )
    {
        DemoResource* item = [[DemoFramework getDemoResourceManager] lookupResource:items[itemIndex]];
        int originalAmount = [item getAttributeAsInt:@"amount"];
        float newAmount = originalAmount * scale;
        [item setAttributeAsInt:@"amount" withValue:(int)roundf(newAmount)];
    }
}

- (NSString *) priceAsString:(SKProduct *) product
{
    NSString *result = nil;
    
    if( [[product price] doubleValue] == 0.0 )
    {
        NSArray *components = [[product localizedDescription] componentsSeparatedByString:@"$"];
        return [NSString stringWithFormat:@"$%@", components[1]];
    }
    else
    {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:[product priceLocale]];
        
        result = [formatter stringFromNumber:[product price]];
    }
    
    return result;
}

- (IBAction)onCloseStore:(id)sender
{
    #pragma unused(sender)
    [self.navigationController popViewControllerAnimated:YES];
}

@end
