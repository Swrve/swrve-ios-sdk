//
//  SwrveConversationEvents.h
//  SwrveDemoFramework
//
//  Created by Oisin Hurley on 25/03/2015.
//  Copyright (c) 2015 Swrve. All rights reserved.
//

#ifndef SwrveDemoFramework_SwrveConversationEvents_h
#define SwrveDemoFramework_SwrveConversationEvents_h

@class SwrveConversation;

@interface SwrveConversationEvents : NSObject

+(void)started:(SwrveConversation*)conversation onPage:(NSString*)pageTag;
+(void)cancelled:(SwrveConversation*)conversation onPage:(NSString*)pageTag;
+(void)finished:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;

@end

#endif
