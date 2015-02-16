
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
#import "SwrveConversationResponseItem.h"

@interface SwrveConversationResponse : NSObject

@property (nonatomic, strong) NSString *control;
@property (nonatomic, readonly) NSArray *responseItems;

-(id)   initWithControl:(NSString *)control;
-(void) addResponseItem:(SwrveConversationResponseItem *)item;

@end
