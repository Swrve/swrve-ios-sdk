#import "SwrveConversationEvents.h"
#import "SwrveConversation.h"
#import "Swrve.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationPane.h"
#import "SwrveInputMultiValue.h"
#import "SwrveInputMultiValueLong.h"
#import "SwrveContentVideo.h"

@implementation SwrveConversationEvents

+(void)started:(SwrveConversation*)conversation onStartPage:(NSString*)pageTag {
    [self genericEvent:@"start" forConversation:conversation onPage:pageTag];
}

+(void)done:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"done" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)cancel:(SwrveConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"cancel" forConversation:conversation onPage:pageTag];
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
+(void)impression:(SwrveConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"impression" forConversation:conversation onPage:pageTag];
}

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

// Atom actions
+(void)gatherAndSendUserInputs:(SwrveConversationPane*)conversationPane forConversation:(SwrveConversation*)conversation {
    // Send the queued user input elements
    for(SwrveConversationAtom *atom in conversationPane.content) {
        if([atom isKindOfClass:[SwrveInputMultiValue class]]) {
            SwrveInputMultiValue *item = (SwrveInputMultiValue*)atom;
            NSString* result = item.userResponse;
            NSDictionary *userInputResult =
            @{
              @"event" : @"choice",
              @"page" : conversationPane.tag,
              @"conversation" : [conversation.conversationID stringValue],
              @"fragment" : item.tag,
              @"result" : result
              };
            [[Swrve sharedInstance] event:[self nameOf:@"choice" for:conversation] payload:userInputResult];
            
        } else if ([atom isKindOfClass:[SwrveInputMultiValueLong class]]) {
            SwrveInputMultiValueLong *item = (SwrveInputMultiValueLong*)atom;
            NSDictionary* results = item.userResponse;
            NSArray* questionIds = [results allKeys];
            for (NSString* questionId in questionIds) {
                NSString* questionValue = [results valueForKey:questionId];
                NSDictionary *userInputResult =
                @{
                  @"event" : @"multi-choice",
                  @"page" : conversationPane.tag,
                  @"conversation" : [conversation.conversationID stringValue],
                  @"fragment" : item.tag,
                  @"set" : questionId,
                  @"result" : questionValue
                  };
                [[Swrve sharedInstance] event:[self nameOf:@"multi-choice" for:conversation] payload:userInputResult];
            }
        } else if ([atom isKindOfClass:[SwrveContentVideo class]]) {
            SwrveContentVideo *item = (SwrveContentVideo*)atom;
            if (item.interactedWith) {
                NSDictionary *userInputResult =
                @{
                  @"event" : @"play",
                  @"page" : conversationPane.tag,
                  @"conversation" : [conversation.conversationID stringValue],
                  @"fragment" : item.tag
                };
                [[Swrve sharedInstance] event:[self nameOf:@"play" for:conversation] payload:userInputResult];
            }
        }
    }

}

// Actions
+(void)linkVisit:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"visit" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)callNumber:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"call" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)deeplinkVisit:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"deeplink" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)permissionRequest:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"permission" forConversation:conversation onPage:pageTag withControl:controlTag];
}

// Error
+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag];
}

+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag withControl:controlTag];
}
@end
