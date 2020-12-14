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
        
        if ([json objectForKey:@"buttons"]) {
            self.buttons = [json mutableArrayValueForKey:@"buttons"];
        }
        
        if ([json objectForKey:@"data"]) {
            self.data = [json objectForKey:@"data"];
        }
        
        if ([json objectForKey:@"type"]) {
            self.type = [self retrieveType:[json objectForKey:@"type"]];
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

-(void)wasShownToUser {
//TODO: https://swrvedev.jira.com/browse/SWRVE-27162
    
    //SwrveMessageController* c = self.controller;
//    if (c != nil) {
//        [c messageWasShownToUser:self];
//    }
}

@end
