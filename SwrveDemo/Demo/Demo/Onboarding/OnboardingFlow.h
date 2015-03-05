/*
 * Controller used to onboard users the first time they use the app.
 */
@interface OnboardingFlow : UIViewController {
    NSArray* stages;
    int stage;
    UIViewController* viewToReturnTo;
    
}

@property (nonatomic, retain) IBOutlet UIView *view0;
@property (nonatomic, retain) IBOutlet UIView *view1;
@property (nonatomic, retain) IBOutlet UIView *view2;
@property (nonatomic, retain) IBOutlet UIView *view3;

/*
 * Called to skip last screen of the tutorial
 */
- (IBAction)onSkipApiKey:(id)sender;

/*
 * Called to navigate to the swrve dashboard
 */
- (IBAction)onNavigateToSwrveDashboard:(id)sender;

/*
 * The current stage of the flow.
 */
@property (nonatomic) int stage;


/*
 * Moves onboarding onto the specified stage
 */
-(void) moveToStage:(int) stage;

/*
 * Finishes onboarding and navigates to the the viewToReturnTo specified on initialization. 
 */
-(void) finish;

@end
