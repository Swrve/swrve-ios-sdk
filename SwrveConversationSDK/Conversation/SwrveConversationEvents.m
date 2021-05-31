#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif
#import "SwrveConversationEvents.h"
#import "SwrveBaseConversation.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationPane.h"
#import "SwrveInputMultiValue.h"
#import "SwrveContentVideo.h"
#import "SwrveContentStarRating.h"

@implementation SwrveConversationEvents
static NSMutableDictionary *_customPayload = nil;

+ (NSMutableDictionary *)customPayload {
    if (_customPayload == nil) {
        _customPayload = [NSMutableDictionary new];
    }
    return _customPayload;
}

+ (void)setCustomPayload:(NSMutableDictionary *)newCustomPayload {
    if ([newCustomPayload count] > 5) {
        [SwrveLogger error:@"Swrve custom payload rejected, attempted to add more than 5 key pair values", nil];
        return;
    }

    if (![SwrveConversationEvents validatePayloadKeys:newCustomPayload]) {
        [SwrveLogger error:@"Swrve custom payload rejected, attempted to add a key which is already reserved for Swrve internal events", nil];
        return;
    }
    _customPayload = [newCustomPayload copy];
}

+ (bool)validatePayloadKeys:(NSMutableDictionary *)payload {
    NSArray *restrictedSwrveKeys = @[@"event",
            @"to",
            @"page",
            @"conversation",
            @"control",
            @"fragment",
            @"result",
            @"name",
            @"id"];

    NSMutableArray *keys = [NSMutableArray arrayWithArray:[payload allKeys]];
    NSUInteger countBefore = [keys count];
    [keys removeObjectsInArray:restrictedSwrveKeys];
    return (countBefore == [keys count]);
}

+ (bool)isSurveyEvent:(NSString *)eventName {
    NSArray *surveyEvents = @[@"star-rating", @"choice", @"play"];
    return [surveyEvents containsObject:eventName];
}

+ (void)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload {
    NSString *payloadEventName = [eventPayload objectForKey:@"event"];
    if ([self isSurveyEvent:payloadEventName] && [_customPayload count] > 0) {
        NSMutableDictionary *newPayload = [NSMutableDictionary new];
        [newPayload addEntriesFromDictionary:_customPayload];
        [newPayload addEntriesFromDictionary:eventPayload];
        [[SwrveCommon sharedInstance] eventInternal:eventName payload:newPayload triggerCallback:false];
    } else {
        [[SwrveCommon sharedInstance] eventInternal:eventName payload:eventPayload triggerCallback:false];
    }
}

+(void)started:(SwrveBaseConversation*)conversation onStartPage:(NSString*)pageTag {
    [self genericEvent:@"start" forConversation:conversation onPage:pageTag];
}

+(void)done:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"done" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)cancel:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"cancel" forConversation:conversation onPage:pageTag];
}

+(void)genericEvent:(NSString*)name forConversation:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:controlTag {
    NSDictionary *eventPayload =
    @{
      @"event" : name,
      @"page" : pageTag,
      @"conversation" : [conversation.conversationID stringValue],
      @"control" : controlTag
    };
    NSString *eventName = [self nameOf:name for:conversation];
    [self eventInternal:eventName payload:eventPayload];
}

+(void)genericEvent:(NSString*)name forConversation:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag {
    NSDictionary *eventPayload =
    @{
      @"event" : name,
      @"page" : pageTag,
      @"conversation" : [conversation.conversationID stringValue]
    };
    NSString *eventName = [self nameOf:name for:conversation];
    [self eventInternal:eventName payload:eventPayload];
}

+(NSString*)nameOf:(NSString*)event for:(SwrveBaseConversation*)conversation {
   return [NSString stringWithFormat:@"Swrve.Conversations.Conversation-%@.%@", conversation.conversationID, event];
}

// Page related
+(void)impression:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"impression" forConversation:conversation onPage:pageTag];
}

+(void)pageTransition:(SwrveBaseConversation*)conversation fromPage:(NSString*)originPage toPage:(NSString*)toPage withControl:(NSString*)controlTag{
    NSDictionary *eventPayload =
    @{
      @"event" : @"navigation",
      @"to" : toPage,
      @"page" : originPage,
      @"conversation" : [conversation.conversationID stringValue],
      @"control" : controlTag
    };
    NSString *eventName = [self nameOf:@"navigation" for:conversation];
    [self eventInternal:eventName payload:eventPayload];
}

// Atom actions
+(void)gatherAndSendUserInputs:(SwrveConversationPane*)conversationPane forConversation:(SwrveBaseConversation*)conversation {
    // Send the queued user input elements
    for(SwrveConversationAtom *atom in conversationPane.content) {
        if([atom isKindOfClass:[SwrveInputMultiValue class]]) {
            SwrveInputMultiValue *item = (SwrveInputMultiValue*)atom;
            NSString* result = item.userResponse;
            if (result && ![result isEqualToString:@""]) {
                NSDictionary *payload =
                        @{
                                @"event" : @"choice",
                                @"page" : conversationPane.tag,
                                @"conversation" : [conversation.conversationID stringValue],
                                @"fragment" : item.tag,
                                @"result" : result
                        };
                NSString *eventName = [self nameOf:@"choice" for:conversation];
                [self eventInternal:eventName payload:payload];
            }
        }
#if TARGET_OS_IOS /** exclude tvOS **/
        else if ([atom isKindOfClass:[SwrveContentVideo class]]) {
            SwrveContentVideo *item = (SwrveContentVideo*)atom;
            if (item.interactedWith) {
                NSDictionary *payload =
                @{
                  @"event" : @"play",
                  @"page" : conversationPane.tag,
                  @"conversation" : [conversation.conversationID stringValue],
                  @"fragment" : item.tag
                };
                NSString *eventName = [self nameOf:@"play" for:conversation];
                [self eventInternal:eventName payload:payload];
            }
        }
#endif
        else if ([atom isKindOfClass:[SwrveContentStarRating class]]) {
            SwrveContentStarRating *item = (SwrveContentStarRating*)atom;
                NSDictionary *payload =
                @{
                  @"event" : @"star-rating",
                  @"page" : conversationPane.tag,
                  @"conversation" : [conversation.conversationID stringValue],
                  @"fragment" : item.tag,
                  @"result" :[NSString stringWithFormat:@"%.01f", item.currentRating]
                  };
                NSString *eventName = [self nameOf:@"star-rating" for:conversation];
                [self eventInternal:eventName payload:payload];
            }
    }

}

// Actions
+(void)linkVisit:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"visit" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)callNumber:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"call" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)deeplinkVisit:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"deeplink" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)permissionRequest:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"permission" forConversation:conversation onPage:pageTag withControl:controlTag];
}

// Error
+(void)error:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag];
}

+(void)error:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag withControl:controlTag];
}
@end
