//
//  TutorialDemo.h
//  SwrveDemoFramework
//
//  Copyright (c) 2010-2014 Swrve. All rights reserved.
//

#import "DemoFramework.h"

@interface TutorialDemo : Demo {
    
    int currentStep;
}

@property (nonatomic, retain) IBOutlet UIImageView *image;
@property (nonatomic, retain) IBOutlet UILabel *label;

@end
