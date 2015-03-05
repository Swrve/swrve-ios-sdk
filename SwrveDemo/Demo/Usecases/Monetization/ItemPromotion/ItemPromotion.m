#import "ItemPromotion.h"
#import "InAppPurchaseDemo.h"
    
@implementation ItemPromotionDemo

-(id) init
{
    return [super initWithNibName:@"ItemPromotion" bundle:nil];
}

-(void) onEnterDemo
{
    // Tell the Swrve Talk SDK that this demo will handle the custom button actions instead
    // of relying on the default behavior.
    [DemoFramework getSwrveTalk].customButtonCallback = ^(NSString* action)
    {
        float discount = 1.0;
        
        // Parse the discount amount.
        NSError* error;
        NSData* actionAsData = [action dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* actionAsJson = [NSJSONSerialization JSONObjectWithData:actionAsData options:NSJSONReadingMutableContainers error:&error];
        
        if( [actionAsJson objectForKey:@"currencyMultiplier"])
        {
            discount = ((NSString*)[actionAsJson objectForKey:@"currencyMultiplier"]).floatValue;
            if(discount != 1.0)
            {
                [self showStoreFrontWithDiscount:discount];
            }
        }
    };
    
    [DemoFramework getSwrveTalk].showMessageDelegate = self;
}

- (void) messageWillBeShown:(SwrveMessageViewController*) viewController {
    #pragma unused(viewController)
    NSLog(@"Handle any special logic here before the message is shown.");
}

- (void) messageWillBeHidden:(SwrveMessageViewController*) viewController {
    #pragma unused(viewController)
    NSLog(@"Handle any special logic here after the message is hidden.");
}

- (void) beginShowMessageAnimation:(UIViewController*) viewController {
    #pragma unused(viewController)
    NSLog(@"Implement custom transitions here.");
}

- (void) beginHideMessageAnimation:(UIViewController*) viewController {
    #pragma unused(viewController)
    NSLog(@"Implement custom transitions here, don't forget to call dismissMessageWindow.");
    [[DemoFramework getSwrveTalk] dismissMessageWindow];
}

-(void) onExitDemo
{
    // Tell the Swrve Talk SDK to revert back to it's old behavior and manage
    // button clicks itself.
    [DemoFramework getSwrveTalk].customButtonCallback = nil;
}

- (IBAction)onShowOffer:(id)sender
{
    #pragma unused(sender)
    [[DemoFramework getSwrve]event:@"Swrve.Demo.ItemPromotion"];
}

- (void) showStoreFrontWithDiscount:(float) currencyMultiplier
{
    InAppPurchaseDemo* storeFront = [[InAppPurchaseDemo alloc] initWithCurrencyMultiplier:currencyMultiplier];
    [storeFront onEnterDemo];
    
    [self.navigationController pushViewController:storeFront animated:YES];
}

@end

