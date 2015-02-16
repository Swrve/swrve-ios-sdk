
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveConversationResponseItem.h"

@implementation SwrveConversationResponseItem

@synthesize tag;
@synthesize value;

-(id) initWithInputItem:(SwrveInputItem *)inputItem {
    self = [super init];
    if(self) {
        tag = inputItem.tag;
        value = inputItem.userResponse;
    }
    return self;
}

@end
