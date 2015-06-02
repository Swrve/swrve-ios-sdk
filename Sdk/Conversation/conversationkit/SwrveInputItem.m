#import "SwrveInputItem.h"
#import "SwrveSetup.h"

@implementation SwrveInputItem

@synthesize optional;
@dynamic userResponse;

-(BOOL) isFirstResponder {
    return NO;
}

-(void) resignFirstResponder {
    // Do nothing - subclasses should though.
}

-(BOOL)isComplete {
    return YES;
}

-(void) highlight {
    // Do nothing - subclasses should though.
}

-(void) removeHighlighting {
    // Do nothing - subclasses should though.
}

-(BOOL) isValid:(NSError * __autoreleasing *)error {
    // Do nothing - subclasses implement
    *error= nil;
    return YES;
}

@end
