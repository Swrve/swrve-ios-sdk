
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveConversationAtom.h"

@interface SwrveInputItem : SwrveConversationAtom

@property(nonatomic,strong) id userResponse;
@property(nonatomic,assign,getter = isOptional) BOOL optional;

-(BOOL) isFirstResponder;
-(void) resignFirstResponder;
-(BOOL) isComplete;
-(void) highlight;
-(void) removeHighlighting;
-(BOOL) isValid:(NSError**)error;

@end
