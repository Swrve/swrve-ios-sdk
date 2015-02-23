
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import <Foundation/Foundation.h>
#import "SwrveConversationAtom.h"

#define kSwrveKeyDescription @"description"

@interface SwrveConversationButton : SwrveConversationAtom

-(id) initWithTag:(NSString *)tag andDescription:(NSString *)description;

@property (readonly, nonatomic) NSString *description;
@property (strong, nonatomic) NSDictionary *actions;

@end
