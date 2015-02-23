@class SwrveMessageController;

/*! PRIVATE: Base campaign methods. */
@interface SwrveBaseCampaign(SwrveBaseCampaignProtected)

@property (retain, nonatomic) NSMutableSet* triggers;
@property (retain, nonatomic) NSDate*       dateStart;
@property (retain, nonatomic) NSDate*       dateEnd;
@property (atomic) BOOL randomOrder;

/*! PRIVATE: Set the message mimimum delay time. */
-(void)setMessageMinDelayThrottle:(NSDate*)timeShown;

/*! PRIVATE: Log the reason for campaigns not being available. */
-(void)logAndAddReason:(NSString*)reason withReasons:(NSMutableDictionary*)campaignReasons;

/*! PRIVATE: Check if it is too soon to display a message after launch. */
-(BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate*)now;

/*! PRIVATE: Check if it is too soon to display a message after a delay. */
-(BOOL)isTooSoonToShowMessageAfterDelay:(NSDate*)now;

/*! PRIVATE: Check that rules pass. */
-(BOOL)checkCampaignRulesForEvent:(NSString*)event
                           atTime:(NSDate*)time
                      withReasons:(NSMutableDictionary*)campaignReasons;
@end
