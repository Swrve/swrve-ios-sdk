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

// Page related
+(void)pageTransition:(SwrveConversation*)conversation fromPage:(NSString*)originPage toPage:(NSString*)toPage withControl:(NSString*)controlTag{
    NSDictionary *eventPayload =
    @{
      @"event" : @"navigation",
      @"to" : toPage,
      @"page" : originPage,
      @"conversation" : [conversation.conversationID stringValue],
      @"control" : controlTag
      };
    
    [[Swrve sharedInstance] event:[self nameOf:@"navigation" for:conversation] payload:eventPayload];
}

+(void)viewed:(SwrveConversation*)conversation page:(NSString*)pageTag {
    [self genericEvent:@"impression" forConversation:conversation onPage:pageTag];
}

// Actions
+(void)linkVisit:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"link" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)callNumber:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"call" forConversation:conversation onPage:pageTag withControl:controlTag];
}

// Error
+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag];
}

+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag withControl:controlTag];
}

// TODO: link accessed / impression / call / page transition / error if any
@end
