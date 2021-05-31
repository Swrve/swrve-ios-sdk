#import "SwrveCampaign.h"

@class SwrveMessageController;

@interface SwrveCampaign()

/*! Set the message mimimum delay time. */
-(void)setMessageMinDelayThrottle:(NSDate*)timeShown;

/*! Log the reason for campaigns not being available. */
-(void)logAndAddReason:(NSString *)reason withReasons:(NSMutableDictionary*)campaignReasons;

/*! Check if it is too soon to display a message after launch. */
-(BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate *)now;

/*! Check if it is too soon to display a message after a delay. */
-(BOOL)isTooSoonToShowMessageAfterDelay:(NSDate *)now;

/*! Check that rules pass. */
-(BOOL)checkCampaignRulesForEvent:(NSString *)event
                           atTime:(NSDate *)time
                      withReasons:(NSMutableDictionary *)campaignReasons;

/*! Check that Triggers are valid. */
-(BOOL)canTriggerWithEvent:(NSString*)event andPayload:(NSDictionary*)payload;

/*! Notify when the campaign was displayed. */
- (void)wasShownToUserAt:(NSDate *)timeShown;

/*! Returns true if the campaign is active at a given time . */
-(BOOL)isActive:(NSDate*)date withReasons:(NSMutableDictionary*)campaignReasons;

/*! Return the serialized state of the campaign */
-(NSDictionary*)stateDictionary;

@end
