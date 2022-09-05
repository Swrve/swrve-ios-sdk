#import "SwrveEmbeddedCampaign.h"
#import "SwrveEmbeddedMessage.h"
#import "SwrveCampaign+Private.h"
#import "SwrveMessageController+Private.h"

@implementation SwrveEmbeddedCampaign

@synthesize message;

-(id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json forController:(SwrveMessageController *)controller {
    id instance = [super initAtTime:time fromDictionary:json];
    NSDictionary *embedded_message = [json objectForKey:@"embedded_message"];
    SwrveEmbeddedMessage *embeddedMessage = [[SwrveEmbeddedMessage alloc] initWithDictionary:embedded_message forCampaign:self forController:controller];
    self.message = embeddedMessage;
    
    if ([json objectForKey:@"subject"] != [NSNull null] && [json objectForKey:@"subject"] != nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.subject = [json objectForKey:@"subject"];
#pragma clang diagnostic pop
    }
    
    self.campaignType = SWRVE_CAMPAIGN_EMBEDDED;
    
    self.name = self.message.name;
    
    return instance;
}

-(BOOL)hasMessageForEvent:(NSString *)event {

    return [self hasMessageForEvent:event withPayload:nil];
}

-(BOOL)hasMessageForEvent:(NSString *)event withPayload:(NSDictionary *)payload {

    return [self canTriggerWithEvent:event andPayload:payload];
}

- (SwrveEmbeddedMessage*)messageForEvent:(NSString *)event
                       withPayload:(NSDictionary *)payload
                            atTime:(NSDate *)time
                       withReasons:(NSMutableDictionary *)campaignReasons {

    if (![self hasMessageForEvent:event withPayload:payload]){

        [SwrveLogger debug:@"There is no trigger in %ld that matches %@", (long)self.ID, event];
        [self logAndAddReason:[NSString stringWithFormat:@"There is no trigger in %ld that matches %@ with conditions %@", (long)self.ID, event, payload] withReasons:campaignReasons];
        return nil;
    }

    if (![self message])
    {
        [self logAndAddReason:[NSString stringWithFormat:@"No embedded message in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    if (![self checkCampaignRulesForEvent:event atTime:time withReasons:campaignReasons]) {
        return nil;
    }

    return self.message;
}

#if TARGET_OS_IOS /** exclude tvOS **/
-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}
#endif

-(BOOL)assetsReady:(NSSet *)assets withPersonalization:(NSDictionary *)personalization {
    return YES;
}

@end
