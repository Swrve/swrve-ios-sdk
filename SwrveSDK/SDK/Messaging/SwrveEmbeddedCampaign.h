#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SwrveCampaign.h"

@class SwrveEmbeddedMessage;

/*! embedded campaign. */
@interface SwrveEmbeddedCampaign : SwrveCampaign

@property (atomic, retain) SwrveEmbeddedMessage* message;

- (id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json forController:(SwrveMessageController *)controller;

-(BOOL)hasMessageForEvent:(NSString *)event;
-(BOOL)hasMessageForEvent:(NSString *)event withPayload:(NSDictionary *)payload;

- (SwrveEmbeddedMessage*)messageForEvent:(NSString *)event
                       withPayload:(NSDictionary *)payload
                            atTime:(NSDate *)time
                             withReasons:(NSMutableDictionary *)campaignReasons;

@end

