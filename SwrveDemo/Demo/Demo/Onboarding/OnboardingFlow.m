#import "OnboardingFlow.h"
#import "DemoFramework.h"

@implementation OnboardingFlow

@synthesize stage;
@synthesize view0;
@synthesize view1;
@synthesize view2;
@synthesize view3;

-(id) init
{
    self = [super initWithNibName:@"OnboardingFlow" bundle:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    stages = [[NSArray alloc] initWithObjects:self.view, self.view0, self.view1, self.view2, self.view3, nil];
    for( unsigned int i = 0; i < stages.count; ++i )
    {
        UISwipeGestureRecognizer* swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
        swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [stages[i] addGestureRecognizer:swipeRecognizer];
    }
    
    stage = 0;
}

-(void) moveToStage:(int) nextStage
{
    NSString* eventName = [NSString stringWithFormat:@"Swrve.Demo.Tutorial_Step_%d", nextStage];
    [[DemoFramework getSwrveInternal]event:eventName];

    if( nextStage > 4)
    {
        [self finish];
        return;
    }

    UIView* nextView = stages[(unsigned int)nextStage];
    [nextView setFrame:CGRectMake( 1000.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.5];
    [nextView setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:nextView];
    [UIView commitAnimations];
    
    self.stage = nextStage;
}

- (void)finish
{
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onSwipe:(UIGestureRecognizer*)recognizer
{
    #pragma unused(recognizer)
    [self moveToStage:self.stage + 1];
}

- (IBAction)onSkipApiKey:(id)sender
{
    #pragma unused(sender)
    [self finish];
}

- (IBAction)onNavigateToSwrveDashboard:(id)sender
{
    #pragma unused(sender)
}

@end
