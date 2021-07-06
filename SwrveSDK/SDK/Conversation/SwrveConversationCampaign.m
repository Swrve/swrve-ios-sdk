#import "Swrve.h"
#import "SwrveConversationCampaign.h"
#import "SwrveConversationPane.h"
#import "SwrveContentItem.h"
#import "SwrveInputMultiValue.h"
#import "SwrveConversationButton.h"
#import "SwrveContentImage.h"
#import "SwrveContentHTML.h"
#import "SwrveContentStarRating.h"

#if __has_include(<SwrveSDKCommon/SwrveAssetsManager.h>)
#import <SwrveSDKCommon/SwrveAssetsManager.h>
#else
#import "SwrveAssetsManager.h"
#endif

#import "SwrveCampaign+Private.h"
#import "SwrveMessageController+Private.h"

@interface SwrveConversationCampaign()

@property (nonatomic, weak) SwrveMessageController* controller;

@end

@implementation SwrveConversationCampaign

@synthesize controller, conversation, filters;

- (id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json withAssetsQueue:(NSMutableSet *)assetsQueue forController:(SwrveMessageController *)_controller {
    if (self = [super initAtTime:time fromDictionary:json]) {
        self.controller = _controller;
        NSDictionary *conversationJson = [json objectForKey:@"conversation"];
        self.conversation = [[SwrveConversation alloc] initWithJSON:conversationJson forCampaign:self forController:controller];

        self.filters = [json objectForKey:@"filters"];
        [self addAssetsToQueue:assetsQueue];
        
        self.campaignType = SWRVE_CAMPAIGN_CONVERSATION;
    }
    
    return self;
}

- (void)addAssetsToQueue:(NSMutableSet *)assetsQueue {
#if TARGET_OS_IOS /** exclude conversation assets from tvOS **/
    for (SwrveConversationPane *page in self.conversation.pages) {

        // Add image and font assets to queue from content
        for (SwrveContentItem *contentItem in page.content) {
            if ([contentItem isKindOfClass:[SwrveContentImage class]]) {
                [self addImageToQ:assetsQueue withAsset:contentItem];

            }
            else if ([contentItem isKindOfClass:[SwrveContentHTML class]] || [contentItem isKindOfClass:[SwrveContentStarRating class]]) {
                [self addFontToQ:assetsQueue withAsset:contentItem.style];
            }
            else if ([contentItem isKindOfClass:[SwrveInputMultiValue class]]) {
                SwrveInputMultiValue *inputMultiValue = (SwrveInputMultiValue*) contentItem;
                [self addFontToQ:assetsQueue withAsset:inputMultiValue.style];

                for (NSDictionary *value in inputMultiValue.values) {
                    NSDictionary *style = [value objectForKey:kSwrveKeyStyle];
                    [self addFontToQ:assetsQueue withAsset:style];
                }
            }
        }

        // Add font assets to queue from button control
        for (SwrveConversationButton *button in page.controls) {
            [self addFontToQ:assetsQueue withAsset:button.style];
        }
    }
#endif
}

- (void)addImageToQ:(NSMutableSet *)assetQueue withAsset:(SwrveContentItem *)contentItem {
    NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:contentItem.value andDigest:contentItem.value andIsExternal:NO andIsImage:YES];
    [assetQueue addObject:assetQueueItem];
}

- (void)addFontToQ:(NSMutableSet *)assetQueue withAsset:(NSDictionary *)style {
    if (style && [style objectForKey:kSwrveKeyFontFile] && [style objectForKey:kSwrveKeyFontDigest] && ![SwrveBaseConversation isSystemFont:style]) {
        NSString *name = [style objectForKey:kSwrveKeyFontFile];
        NSString *digest = [style objectForKey:kSwrveKeyFontDigest];
        NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:name andDigest:digest andIsExternal:NO andIsImage:NO];
        [assetQueue addObject:assetQueueItem];
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

-(BOOL)hasConversationForEvent:(NSString*)event {

    return [self hasConversationForEvent:event withPayload:nil];
}

- (BOOL)hasConversationForEvent:(NSString*)event withPayload:(NSDictionary *)payload {

    return [self canTriggerWithEvent:event andPayload:payload];
}

-(SwrveConversation*)conversationForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
{
    return [self conversationForEvent:event withPayload:nil withAssets:assets atTime:time withReasons:nil];
}


-(SwrveConversation*)conversationForEvent:(NSString*)event
                                 withPayload:(NSDictionary*)payload
                                  withAssets:(NSSet*)assets
                                      atTime:(NSDate*)time
                                 withReasons:(NSMutableDictionary*)campaignReasons {

    if (![self hasConversationForEvent:event withPayload:payload]) {

        [SwrveLogger debug:@"There is no trigger in %ld that matches %@", (long)self.ID, event];
        [self logAndAddReason:[NSString stringWithFormat:@"There is no trigger in %ld that matches %@ with conditions %@", (long)self.ID, event, payload] withReasons:campaignReasons];

        return nil;
    }

    if (self.conversation == nil)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"No conversations in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    if (![self checkCampaignRulesForEvent:event atTime:time withReasons:campaignReasons]) {
        return nil;
    }

    SwrveMessageController* controllerStrongReference = self.controller;
    if (controllerStrongReference == nil) {
        [SwrveLogger error:@"No message controller!", nil];
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
        [SwrveLogger debug:@"%@ matches a trigger in %ld", event, (long)self.ID];
        return self.conversation;
    }

    [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld hasn't finished downloading", (long)self.ID] withReasons:campaignReasons];
    return nil;
}

#if TARGET_OS_IOS /** exclude tvOS **/
-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
#pragma unused(orientation)
    return YES;
}
#endif

-(BOOL)assetsReady:(NSSet *)assets withPersonalization:(NSDictionary *)personalization
{
#pragma unused(personalization) //personalization is not supported in Conversations
    return [self.conversation assetsReady:assets];
}

@end
