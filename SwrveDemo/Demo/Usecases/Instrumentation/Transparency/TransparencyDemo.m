#import "TransparencyDemo.h"

@interface TransparencyDemo()

@property (atomic) UIColor* oldBackgroundColor;

@end

@implementation TransparencyDemo

@synthesize oldBackgroundColor;

-(id) init
{
    return [super initWithNibName:@"TransparencyDemo" bundle:nil];
}

-(void) onEnterDemo
{
    self.oldBackgroundColor = [DemoFramework getSwrveTalk].inAppMessageBackgroundColor;
    
    // Change the default background color to clear
    [DemoFramework getSwrveTalk].inAppMessageBackgroundColor = [UIColor clearColor];
}

-(void) onExitDemo
{
    [DemoFramework getSwrveTalk].inAppMessageBackgroundColor = self.oldBackgroundColor;
    
}

- (IBAction)onShowOffer:(id)sender
{
    #pragma unused(sender)
    [[DemoFramework getSwrve]event:@"Demo.CrossPromoMessage"];
}

@end

