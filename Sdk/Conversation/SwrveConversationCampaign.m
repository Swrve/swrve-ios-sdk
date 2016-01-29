#import "Swrve.h"
#import "SwrveBaseCampaign.h"
#import "SwrveConversationCampaign.h"
#import "SwrvePrivateBaseCampaign.h"

@interface SwrveConversationCampaign()

@property (nonatomic, weak) SwrveMessageController* controller;

@end

@implementation SwrveConversationCampaign

@synthesize controller, conversation, filters;

-(id)initAtTime:(NSDate*)time fromJSON:(NSDictionary *)dict withAssetsQueue:(NSMutableSet*)assetsQueue forController:(SwrveMessageController*)_controller
{
    self.controller = _controller;
    id instance = [super initAtTime:time fromJSON:dict withAssetsQueue:assetsQueue forController:_controller];
    NSDictionary* conversationJson = [dict objectForKey:@"conversation"];
    self.conversation = [SwrveConversation fromJSON:conversationJson forCampaign:self forController:_controller];
    self.filters      = [dict objectForKey:@"filters"];
    [self addAssetsToQueue:assetsQueue];
    
    return instance;
}

-(void)addAssetsToQueue:(NSMutableSet*)assetsQueue
{
    // Queue conversation images for download
    for(NSDictionary* page in self.conversation.pages) {
        for (NSDictionary *contentItem in [page objectForKey:@"content"]) {
            if ([[contentItem objectForKey:@"type"] isEqualToString:@"image"]) {
                [assetsQueue addObject:[contentItem objectForKey:@"value"]];
            }
        }
    }
}

-(void)conversationWasShownToUser:(SwrveConversation *)message
{
    [self conversationWasShownToUser:message at:[NSDate date]];
}

-(void)conversationWasShownToUser:(SwrveConversation*)conversation at:(NSDate*)timeShown
{
#pragma unused(conversation)
    [super wasShownToUserAt:timeShown];
}

-(void)conversationDismissed:(NSDate *)timeDismissed
{
    [self setMessageMinDelayThrottle:timeDismissed];
}

/**
 * Quick check to see if this campaign might have messages matching this event trigger
 * This is used to decide if the campaign is a valid candidate for automatically showing at session start
 */
-(BOOL)hasConversationForEvent:(NSString*)event
{
    return [self triggers] != nil && [[self triggers] containsObject:[event lowercaseString]];
}

-(SwrveConversation*)getConversationForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time

{
    return [self getConversationForEvent:event withAssets:assets atTime:time withReasons:nil];
}


-(SwrveConversation*)getConversationForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
                       withReasons:(NSMutableDictionary*)campaignReasons
{
    if (![self hasConversationForEvent:event]){
        DebugLog(@"There is no trigger in %ld that matches %@", (long)self.ID, event);
        return nil;
    }
    
    if (conversation == nil)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"No conversations in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }
    
    if (![self checkCampaignRulesForEvent:event atTime:time withReasons:campaignReasons]) {
        return nil;
    }
    
    SwrveMessageController* controllerStrongReference = self.controller;
    if (controllerStrongReference == nil) {
        DebugLog(@"No message controller!", nil);
        return nil;
    } else {
        NSString* unsupportedFilter = [controllerStrongReference supportsDeviceFilters:filters];
        if (unsupportedFilter != nil) {
            // There was a filter that was not supported
            if ([unsupportedFilter rangeOfString:@".permission."].location != NSNotFound) {
                [self logAndAddReason:[NSString stringWithFormat:@"The permission %@ was either unsupported, denied or already authorised when trying to displaying campaign %ld", unsupportedFilter, (long)self.ID] withReasons:campaignReasons];
            } else {
                [self logAndAddReason:[NSString stringWithFormat:@"The filter %@ was not supported when trying to display campaign %ld", unsupportedFilter, (long)self.ID] withReasons:campaignReasons];
            }
            return nil;
        }
    }
    
    if ([self.conversation assetsReady:assets]) {
        DebugLog(@"%@ matches a trigger in %ld", event, (long)self.ID);
        return conversation;
    }
    
    [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld hasn't finished downloading", (long)self.ID] withReasons:campaignReasons];
    return nil;
}

-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
#pragma unused(orientation)
    return YES;
}

-(BOOL)assetsReady:(NSSet *)assets
{
    return [self.conversation assetsReady:assets];
}

@end
