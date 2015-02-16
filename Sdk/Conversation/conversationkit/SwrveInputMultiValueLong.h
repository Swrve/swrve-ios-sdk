
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveInputMultiBase.h"

@interface SwrveInputMultiValueLong : SwrveInputMultiBase

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
-(id) choicesForRow:(NSUInteger) row;

@end
