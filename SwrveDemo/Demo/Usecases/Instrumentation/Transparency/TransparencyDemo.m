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
    self.oldBackgroundColor = [DemoFramework getSwrveTalk].backgroundColor;
    
    // Change the default background color to clear
    [DemoFramework getSwrveTalk].backgroundColor = [UIColor clearColor];
}

-(void) onExitDemo
{
    [DemoFramework getSwrveTalk].backgroundColor = self.oldBackgroundColor;
    
}

- (IBAction)onShowOffer:(id)sender
{
    #pragma unused(sender)
    [[DemoFramework getSwrve]event:@"Swrve.Demo.CrossPromoMessage"];
}

@end

