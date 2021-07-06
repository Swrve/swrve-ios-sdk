#import "Swrve.h"
#import "SwrveInAppCampaign.h"
#import "SwrveButton.h"
#import "SwrveImage.h"

#if __has_include(<SwrveSDKCommon/SwrveAssetsManager.h>)
#import <SwrveSDKCommon/SwrveAssetsManager.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#import <SwrveSDKCommon/TextTemplating.h>
#else
#import "SwrveAssetsManager.h"
#import "SwrveUtils.h"
#import "TextTemplating.h"
#endif
#import "SwrveCampaign+Private.h"
#import "SwrveMessageController+Private.h"

@implementation SwrveInAppCampaign

@synthesize message;

- (id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json withAssetsQueue:(NSMutableSet *)assetsQueue forController:(SwrveMessageController*)controller withPersonalization:(NSDictionary *) personalization
{
    id instance = [super initAtTime:time fromDictionary:json];
    NSDictionary *messageDict = [json objectForKey:@"message"];
    self.message = [[SwrveMessage alloc] initWithDictionary:messageDict forCampaign:self forController:controller];

    [self addAssetsToQueue:assetsQueue withPersonalization:personalization];
    if ([json objectForKey:@"subject"] != [NSNull null] && [json objectForKey:@"subject"] != nil) {
        self.subject = [json objectForKey:@"subject"];
    }
    
    self.campaignType = SWRVE_CAMPAIGN_IAM;

    return instance;
}

- (void)addAssetsToQueue:(NSMutableSet *)assetsQueue withPersonalization:(NSDictionary *)personalization {
    for (SwrveMessageFormat *format in message.formats) {
        // Add all images to the download queue
        for (SwrveButton *button in format.buttons) {
            if (button.dynamicImageUrl) {
                NSError *error;
                NSString *resolvedUrl = [TextTemplating templatedTextFromString:button.dynamicImageUrl withProperties:personalization andError:&error];
                if (error != nil || resolvedUrl == nil) {
                    [SwrveLogger debug:@"Could not resolve personalization: %@", button.dynamicImageUrl];
                } else {
                    NSData *data = [resolvedUrl dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
                    NSString *sha1Url = [SwrveUtils sha1:data];
                    NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:sha1Url andDigest:resolvedUrl andIsExternal:YES andIsImage:YES];
                    [assetsQueue addObject:assetQueueItem];
                }
            }
            
            if (button.image) {
                NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:button.image andDigest:button.image andIsExternal:NO andIsImage:YES];
                [assetsQueue addObject:assetQueueItem];
            }
        }

        for (SwrveImage *image in format.images) {
            if (image.dynamicImageUrl) {
                NSError *error;
                NSString *resolvedUrl = [TextTemplating templatedTextFromString:image.dynamicImageUrl withProperties:personalization andError:&error];
                if (error != nil || resolvedUrl == nil) {
                    [SwrveLogger debug:@"Could not resolve personalization: %@", image.dynamicImageUrl];
                } else {
                    NSData *data = [resolvedUrl dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
                    NSString *sha1Url = [SwrveUtils sha1:data];
                    NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:sha1Url andDigest:resolvedUrl andIsExternal:YES andIsImage:YES];
                    [assetsQueue addObject:assetQueueItem];
                }
            }
            
            if (image.file) {
                NSMutableDictionary *assetQueueItem = [SwrveAssetsManager assetQItemWith:image.file andDigest:image.file andIsExternal:NO andIsImage:YES];
                [assetsQueue addObject:assetQueueItem];
            }
        }
    }
}

- (void)messageWasShownToUser:(SwrveMessage *)messageShown {
    [self messageWasShownToUser:messageShown at:[NSDate date]];
}

- (void)messageWasShownToUser:(SwrveMessage*)messageShown at:(NSDate *)timeShown {
#pragma unused(messageShown)
    [self wasShownToUserAt:timeShown];
}

- (void)messageDismissed:(NSDate *)timeDismissed {
    [self setMessageMinDelayThrottle:timeDismissed];
}

/**
 * Quick check to see if this campaign might have messages matching this event trigger
 * This is used to decide if the campaign is a valid candidate for automatically showing at session start
 */
- (BOOL)hasMessageForEvent:(NSString *)event {
    return [self hasMessageForEvent:event withPayload:nil];
}

- (BOOL)hasMessageForEvent:(NSString *)event withPayload:(NSDictionary *)payload {
    return [self canTriggerWithEvent:event andPayload:payload];
}

-(SwrveMessage*)messageForEvent:(NSString*)event
                     withAssets:(NSSet*)assets
            withPersonalization:(NSDictionary *) personalization
                         atTime:(NSDate*)time
{
    return [self messageForEvent:event withPayload:nil withAssets:assets withPersonalization:personalization atTime:time withReasons:nil];
}


-(SwrveMessage*)messageForEvent:(NSString *)event
                    withPayload:(NSDictionary *)payload
                     withAssets:(NSSet *)assets
            withPersonalization:(NSDictionary *)personalization
                         atTime:(NSDate *)time
                    withReasons:(NSMutableDictionary *)campaignReasons {

    if (![self hasMessageForEvent:event withPayload:payload]) {
        [SwrveLogger debug:@"There is no trigger in %ld that matches %@", (long)self.ID, event];
        [self logAndAddReason:[NSString stringWithFormat:@"There is no trigger in %ld that matches %@ with conditions %@", (long)self.ID, event, payload] withReasons:campaignReasons];
        return nil;
    }

    if (self.message == nil) {
        [self logAndAddReason:[NSString stringWithFormat:@"No messages in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    if (![self checkCampaignRulesForEvent:event atTime:time withReasons:campaignReasons]) {
        return nil;
    }

    if ([message assetsReady:assets withPersonalization:personalization]) {
        [SwrveLogger debug:@"%@ matches a trigger in %ld", event, (long)self.ID];
        return message;
    }

    [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld hasn't finished downloading", (long)self.ID] withReasons:campaignReasons];
    return nil;
}

#if TARGET_OS_IOS /** exclude tvOS **/
- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationUnknown) {
        return YES;
    }
    if ([self.message supportsOrientation:orientation]) {
        return YES;
    }
    return NO;
}
#endif

-(BOOL)assetsReady:(NSSet *)assets withPersonalization:(NSDictionary *)personalization {
    if (![message assetsReady:assets withPersonalization:personalization]){
        return NO;
    }
    return YES;
}

@end
