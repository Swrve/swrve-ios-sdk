#import "SwrveEmbeddedMessage.h"
#import "SwrveMessageController.h"

@interface SwrveEmbeddedMessage()

@property (nonatomic, weak) SwrveMessageController* controller;

@end

@implementation SwrveEmbeddedMessage

@synthesize controller, campaign, data, type, buttons;

-(id)initWithDictionary:(NSDictionary *)json forCampaign:(SwrveEmbeddedCampaign *)_campaign forController:(SwrveMessageController*)_controller {
    if (self = [super init]) {
        self.campaign     = _campaign;
        self.controller   = _controller;
        self.messageID    = [json objectForKey:@"id"];
        if ([json objectForKey:@"priority"]) {
            self.priority = [json objectForKey:@"priority"];
        } else {
            self.priority = [NSNumber numberWithInt:9999];
        }
        
        if ([json objectForKey:@"buttons"] && [json objectForKey:@"buttons"] != [NSNull null]) {
            self.buttons = [json mutableArrayValueForKey:@"buttons"];
        }
        
        if ([json objectForKey:@"type"] && [json objectForKey:@"type"] != [NSNull null]) {
            self.type = [self retrieveType:[json objectForKey:@"type"]];
        }
        
        if ([json objectForKey:@"data"] && [json objectForKey:@"data"] != [NSNull null]) {
            self.data = [json objectForKey:@"data"];
        }
        
        if ([json objectForKey:@"name"] && [json objectForKey:@"name"] != [NSNull null]) {
            self.name = [json objectForKey:@"name"];
        }
        
        if ([json objectForKey:@"message_center_details"] && [json objectForKey:@"message_center_details"] != [NSNull null]) {
            self.messageCenterDetails = [[SwrveMessageCenterDetails alloc] initWithJSON:[json objectForKey:@"message_center_details"]];
        }
        
        if ([json objectForKey:@"control"] && [json objectForKey:@"control"] != [NSNull null]) {
            self.control = [[json objectForKey:@"control"] boolValue];
        }
    }
    return self;
}

-(SwrveEmbeddedDataType) retrieveType:(NSString *) typeString {
    if([typeString isEqualToString:@"json"]) {
        return kSwrveEmbeddedDataTypeJson;
    }
        
    return kSwrveEmbeddedDataTypeOther;
}

@end
