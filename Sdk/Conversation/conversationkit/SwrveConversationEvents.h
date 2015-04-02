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

// Conversation related
+(void)started:(SwrveConversation*)conversation onPage:(NSString*)pageTag;
+(void)cancelled:(SwrveConversation*)conversation onPage:(NSString*)pageTag;
+(void)finished:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;

// Page related
+(void)pageTransition:(SwrveConversation*)conversation fromPage:(NSString*)originPage toPage:(NSString*)toPage withControl:(NSString*)controlTag;
+(void)viewed:(SwrveConversation*)conversation page:(NSString*)pageTag;

// Actions
+(void)linkVisit:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)callNumber:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;

// Errors
+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag;
+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
@end

#endif
