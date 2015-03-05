#import "Demo.h"
#import "DemoFramework.h"

@implementation Demo

-(void) createResources:(DemoResourceManager *) resourceManager
{
    #pragma unused(resourceManager)
    return;
}

-(void) viewDidLoad
{
    self.navigationController.navigationBar.translucent = NO;
}

-(void) onEnterDemo
{
    
}

-(void) onExitDemo
{
    
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if(parent != nil && [self respondsToSelector:@selector(onEnterDemo)])
    {
        // [TRACK] What demos do users look at
        NSDictionary * payload = [NSDictionary dictionaryWithObject:self.title forKey:@"name"];
        [[DemoFramework getSwrveInternal] event:@"Swrve.Demo.UI.Demo.Click" payload:payload];
        [self onEnterDemo];
    }
    
    if( parent == nil && [self respondsToSelector:@selector(onExitDemo)] )
    {
        [self onExitDemo];
    }
}

@end
