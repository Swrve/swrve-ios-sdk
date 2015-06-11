#import "SwrveContentItem.h"

@interface SwrveInputItem : SwrveContentItem

@property(nonatomic,strong) id userResponse;
@property(nonatomic,assign,getter = isOptional) BOOL optional;

-(BOOL) isFirstResponder;
-(void) resignFirstResponder;
-(BOOL) isComplete;
-(void) highlight;
-(void) removeHighlighting;
-(BOOL) isValid:(NSError**)error;

@end
