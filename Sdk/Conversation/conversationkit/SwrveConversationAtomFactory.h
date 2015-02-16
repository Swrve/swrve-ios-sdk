
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import <UIKit/UIKit.h>
#import "SwrveConversationAtom.h"

@interface SwrveConversationAtomFactory : NSObject

+(SwrveConversationAtom *) atomForDictionary:(NSDictionary *)dict;

@end
