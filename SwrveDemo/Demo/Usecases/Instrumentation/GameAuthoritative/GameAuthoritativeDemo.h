//
//  GameAuthoritativeDemo.h
//  SwrveDemoFramework
//
//  Copyright (c) 2010-2014 Swrve. All rights reserved.
//

#import "DemoFramework.h"

@interface GameAuthoritativeDemo : Demo<DemoResourceManagerDelegate> {
    Swrve* swrve;
    DemoResourceManager* resourceManager;
}

@property (atomic, retain) IBOutlet UILabel* timeToLoadLabel;
@end
