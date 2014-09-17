#import "Swrve.h"

/*! Used internally to offer QA user functionality */
@interface SwrveTalkQA : NSObject

    @property (atomic) BOOL resetDevice;
    @property (atomic) BOOL logging;

    -(id)initWithJSON:(NSDictionary*)qaJson withAnalyticsSDK:(Swrve*)sdk;
    -(void)talkSession:(NSDictionary*)campaignsDownloaded;
    -(void)triggerFailure:(NSString*)event withReason:(NSString*)globalReason;
    -(void)trigger:(NSString*)event withMessage:(SwrveMessage*)messageShown withReason:(NSDictionary*)campaignReasons withMessages:(NSDictionary*)campaignMessages;
    -(void)updateDeviceInfo;
    -(void)pushNotification:(NSDictionary*)notification;

@end
