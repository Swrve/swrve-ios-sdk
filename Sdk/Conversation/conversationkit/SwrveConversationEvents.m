//
//  SwrveConversationEvents.m
//  SwrveDemoFramework
//
//  Created by Oisin Hurley on 25/03/2015.
//  Copyright (c) 2015 Swrve. All rights reserved.
//

#import "SwrveConversationEvents.h"
#import "SwrveConversation.h"
#import "Swrve.h"

@implementation SwrveConversationEvents

+(void)started:(SwrveConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"start" forConversation:conversation onPage:pageTag];
}

+(void)cancelled:(SwrveConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"cancel" forConversation:conversation onPage:pageTag];
}

+(void)finished:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"done" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)genericEvent:(NSString*)name forConversation:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:controlTag{
    NSDictionary *eventPayload =
    @{
      @"event" : name,
      @"page" : pageTag,
      @"conversation" : [conversation.conversationID stringValue],
      @"control" : controlTag
      };
    
    [[Swrve sharedInstance] event:[self nameOf:name for:conversation] payload:eventPayload];
}

+(void)genericEvent:(NSString*)name forConversation:(SwrveConversation*)conversation onPage:(NSString*)pageTag {
    NSDictionary *eventPayload =
    @{
      @"event" : name,
      @"page" : pageTag,
      @"conversation" : [conversation.conversationID stringValue]
      };
    
    [[Swrve sharedInstance] event:[self nameOf:name for:conversation] payload:eventPayload];
}

+(NSString*)nameOf:(NSString*)event for:(SwrveConversation*)conversation {
   return [NSString stringWithFormat:@"Swrve.Conversations.Conversation-%@.%@", conversation.conversationID, event];
}

// TODO: link accessed / impression / call / page transition / error if any
@end
