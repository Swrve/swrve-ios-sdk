
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

@interface SwrveConversationPane : NSObject 

@property (readonly, atomic, strong) NSArray *content;  // Array of SwrveConversationAtoms
@property (readonly, atomic, strong) NSArray *controls; // Array of SwrveConversationButtons
@property (readonly, atomic, strong) NSString *name;
@property (readonly, atomic, strong) NSString *title;

-(id) initWithDictionary:(NSDictionary *)dict;

@end
