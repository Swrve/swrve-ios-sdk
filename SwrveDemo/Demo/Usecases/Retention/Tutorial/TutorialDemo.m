#import "TutorialDemo.h"

@implementation TutorialDemo

@synthesize image;
@synthesize label;

-(id) init
{
    return [super initWithNibName:@"TutorialDemo" bundle:nil];
}

-(void) createResources:(DemoResourceManager *) resourceManager;
{
    
    DemoResource *step1Resource = [[DemoResource alloc] init:@"Tutorial.Step1"
                                                withAttributes:@{@"image" : @"tutorial_a.png",
                                                                 @"text" : @"Welcome to the tutorial demo.",
                                                                 @"enabled" : @"true"}];
    DemoResource *step2Resource = [[DemoResource alloc] init:@"Tutorial.Step2"
                                                withAttributes:@{@"image" : @"tutorial_a.png",
                                                                 @"text" : @"You can go back and forth with the buttons,",
                                                                 @"enabled" : @"true"}];
    DemoResource *step3Resource = [[DemoResource alloc] init:@"Tutorial.Step3"
                                                withAttributes:@{@"image" : @"tutorial_a.png",
                                                                 @"text" : @"edit the text of each step",
                                                                 @"enabled" : @"true"}];
    DemoResource *step4Resource = [[DemoResource alloc] init:@"Tutorial.Step4"
                                                withAttributes:@{@"image" : @"tutorial_a.png",
                                                                 @"text" : @"change the background image",
                                                                 @"enabled" : @"true"}];
    DemoResource *step5Resource = [[DemoResource alloc] init:@"Tutorial.Step5"
                                                withAttributes:@{@"image" : @"tutorial_a.png",
                                                                 @"text" : @"and disable steps.",
                                                                 @"enabled" : @"true"}];
    
    DemoResource *tutorialResource = [[DemoResource alloc] init:@"Tutorial Config"
                                                   withAttributes:@{ @"steps.count" : @"5",
                                                                     @"steps.0" : @"Tutorial.Step1",
                                                                     @"steps.1" : @"Tutorial.Step2",
                                                                     @"steps.2" : @"Tutorial.Step3",
                                                                     @"steps.3" : @"Tutorial.Step4",
                                                                     @"steps.4" : @"Tutorial.Step5",
                                                                     @"enabled": @"true"}];
    [resourceManager addResource:step1Resource];
    [resourceManager addResource:step2Resource];
    [resourceManager addResource:step3Resource];
    [resourceManager addResource:step4Resource];
    [resourceManager addResource:step5Resource];
    
    [resourceManager addResource:tutorialResource];
}

-(void) onEnterDemo
{
    currentStep = -1;
    [self moveToNextStep];
}

-(void) onExitDemo
{
}

- (void) moveToPreviousStep
{
    [self moveToStep:currentStep - 1];
}

- (void) moveToNextStep
{
    [self moveToStep:currentStep + 1];
}

- (void) moveToStep:(int)stepIndex
{
    // Lookup names of tutorial step resources
    NSArray* tutorialSteps = [[[DemoFramework getDemoResourceManager] lookupResource:@"Tutorial Config"] getAttributeAsArrayOfString:@"steps"];
    
    // Stay within the bounds of the available steps
    if( stepIndex < 0 || stepIndex > (int)tutorialSteps.count )
    {
        return;
    }
    
    currentStep = stepIndex;

    if(currentStep < (int)tutorialSteps.count)
    {
        // Lookup the tutorial step resource
        DemoResource* tutorialStep = [[DemoFramework getDemoResourceManager] lookupResource:tutorialSteps[(unsigned int)stepIndex]];
        
        // Update image and text
        if( tutorialStep != nil && [tutorialStep getAttributeAsBool:@"enabled"])
        {
            [self image].image = [UIImage imageNamed:[tutorialStep getAttributeAsString:@"image"]];
            [self label].text = [tutorialStep getAttributeAsString:@"text"];
        }
    }
}

-(IBAction) nextStep
{
    [self moveToNextStep];
}

-(IBAction)previousStep
{
    [self moveToPreviousStep];
}


@end
