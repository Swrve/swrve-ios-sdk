#import "Swrve.h"
#import "SwrveInAppCampaign.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#if __has_include(<SwrveSDKCommon/SwrveAssetsManager.h>)
#import <SwrveSDKCommon/SwrveAssetsManager.h>
#else
#import "SwrveAssetsManager.h"
#endif
#import "SwrveCampaign+Private.h"
#import "SwrveMessageController+Private.h"

@implementation SwrveInAppCampaign

@synthesize messages;

-(id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json withAssetsQueue:(NSMutableSet *)assetsQueue forController:(SwrveMessageController*)controller
{
    id instance = [super initAtTime:time fromDictionary:json];
    NSMutableArray *loadedMessages = [NSMutableArray new];
    NSArray *campaign_messages = [json objectForKey:@"messages"];
    for (NSDictionary *messageDict in campaign_messages)
    {
        SwrveMessage *message = [[SwrveMessage alloc] initWithDictionary:messageDict forCampaign:self forController:controller];
        [loadedMessages addObject:message];
    }
    self.messages = [loadedMessages copy];

    [self addAssetsToQueue:assetsQueue];
    if ([json objectForKey:@"subject"] != [NSNull null] && [json objectForKey:@"subject"] != nil) {
        self.subject = [json objectForKey:@"subject"];
    }

    return instance;
}

- (void)addAssetsToQueue:(NSMutableSet *)assetsQueue {
    for (SwrveMessage *message in self.messages) {
        for (SwrveMessageFormat *format in message.formats) {
            // Add all images to the download queue
            for (SwrveButton *button in format.buttons) {
                NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:button.image andDigest:button.image andIsImage:YES];
                [assetsQueue addObject:assetQueueItem];
            }

            for (SwrveImage *image in format.images) {
                NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:image.file andDigest:image.file andIsImage:YES];
                [assetsQueue addObject:assetQueueItem];
            }
        }
    }
}

-(void)messageWasShownToUser:(SwrveMessage *)message
{
    [self messageWasShownToUser:message at:[NSDate date]];
}

-(void)messageWasShownToUser:(SwrveMessage*)message at:(NSDate*)timeShown
{
#pragma unused(message)
    [self wasShownToUserAt:timeShown];

    if (![self randomOrder])
    {
        NSUInteger count = [[self messages] count];
        NSUInteger nextMessage = (self.state.next + 1) % count;
        DebugLog(@"Round Robin message in campaign %ld is %ld (next will be %ld)", (unsigned long)[self ID], (unsigned long)self.state.next, (unsigned long)nextMessage);
        [self.state setNext:nextMessage];
    }
}

-(void)messageDismissed:(NSDate *)timeDismissed
{
    [self setMessageMinDelayThrottle:timeDismissed];
}

static SwrveMessage* firstFormatFrom(NSArray* messages, NSSet* assets)
{
    // Return the first fully downloaded format
    for (SwrveMessage* message in messages) {
        if ([message assetsReady:assets]){
            return message;
        }
    }
    return nil;
}

/**
 * Quick check to see if this campaign might have messages matching this event trigger
 * This is used to decide if the campaign is a valid candidate for automatically showing at session start
 */
-(BOOL)hasMessageForEvent:(NSString*)event {

    return [self hasMessageForEvent:event withPayload:nil];
}

-(BOOL)hasMessageForEvent:(NSString*)event withPayload:(NSDictionary *)payload {

    return [self canTriggerWithEvent:event andPayload:payload];
}

-(SwrveMessage*)messageForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
{
    return [self messageForEvent:event withPayload:nil withAssets:assets atTime:time withReasons:nil];
}


-(SwrveMessage*)messageForEvent:(NSString*)event
                       withPayload:(NSDictionary *)payload
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
                       withReasons:(NSMutableDictionary*)campaignReasons {

    if (![self hasMessageForEvent:event withPayload:payload]){

        DebugLog(@"There is no trigger in %ld that matches %@", (long)self.ID, event);
        [self logAndAddReason:[NSString stringWithFormat:@"There is no trigger in %ld that matches %@ with conditions %@", (long)self.ID, event, payload] withReasons:campaignReasons];
        return nil;
    }

    if ([[self messages] count] == 0)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"No messages in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    if (![self checkCampaignRulesForEvent:event atTime:time withReasons:campaignReasons]) {
        return nil;
    }

    SwrveMessage *message = nil;
    if (self.randomOrder)
    {
        DebugLog(@"Random Message in %ld", (long)self.ID);
        NSArray* shuffled = [SwrveMessageController shuffled:self.messages];
        message = firstFormatFrom(shuffled, assets);
    }

    if (message == nil && messages.count > self.state.next)
    {
        message = [self.messages objectAtIndex:(NSUInteger)self.state.next];
    }
    
    if ([message assetsReady:assets]) {
        DebugLog(@"%@ matches a trigger in %ld", event, (long)self.ID);
        return message;
    }

    [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld hasn't finished downloading", (long)self.ID] withReasons:campaignReasons];
    return nil;
}
#if TARGET_OS_IOS /** exclude tvOS **/
-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationUnknown) {
        return YES;
    }

    for (SwrveMessage* message in self.messages) {
        if ([message supportsOrientation:orientation]){
            return YES;
        }
    }
    return NO;
}
#endif
-(BOOL)assetsReady:(NSSet *)assets
{
    for (SwrveMessage* message in self.messages) {
        if (![message assetsReady:assets]){
            return NO;
        }
    }
    return YES;
}

@end
