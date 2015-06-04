#import "Swrve.h"
#import "SwrveBaseCampaign.h"
#import "SwrveConversationCampaign.h"
#import "SwrvePrivateBaseCampaign.h"
#import "SwrveConversation.h"

@interface SwrveConversationCampaign()

@property (nonatomic, weak)     SwrveMessageController* controller;

@end

@implementation SwrveConversationCampaign

@synthesize controller, conversation, filters;

-(id)initAtTime:(NSDate*)time fromJSON:(NSDictionary *)dict withAssetsQueue:(NSMutableSet*)assetsQueue forController:(SwrveMessageController*)_controller
{
    self.controller = _controller;
    id instance = [super initAtTime:time fromJSON:dict withAssetsQueue:assetsQueue forController:_controller];
    NSDictionary* conversationJson = [dict objectForKey:@"conversation"];
    
    // Set up asset downloads here: for each page, scan content to find any images/assets, queue up for download as an asset
    for (NSDictionary *page in [conversationJson objectForKey:@"pages"]) {
        for (NSDictionary *contentItem in [page objectForKey:@"content"]) {
            if ([[contentItem objectForKey:@"type"] isEqualToString:@"image"]) {
                [assetsQueue addObject:[contentItem objectForKey:@"value"]];
            }
        }
    }
    self.conversation = [SwrveConversation fromJSON:conversationJson forCampaign:self forController:_controller];
    self.filters      = [NSArray arrayWithObjects:@"swrve.permission.ios.push_notifications.requestsable", nil];
    //[dict objectForKey:@"filters"];
    
    return instance;
}

-(void)conversationWasShownToUser:(SwrveConversation *)message
{
    [self conversationWasShownToUser:message at:[NSDate date]];
}

-(void)conversationWasShownToUser:(SwrveConversation*)conversation at:(NSDate*)timeShown
{
#pragma unused(conversation)
    [self incrementImpressions];
    [self setMessageMinDelayThrottle:timeShown];
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
    
    if (self.controller == nil || ![self.controller supportsDeviceFilters:filters]) {
        [self logAndAddReason:[NSString stringWithFormat:@"Some filters were not supported in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }
    
    if ([self.conversation areDownloaded:assets]) {
        DebugLog(@"%@ matches a trigger in %ld", event, (long)self.ID);
        return conversation;
    }
    
    [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld hasn't finished downloading", (long)self.ID] withReasons:campaignReasons];
    return nil;
}

@end
