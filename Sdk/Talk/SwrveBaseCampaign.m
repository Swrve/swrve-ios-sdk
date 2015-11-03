#import "Swrve.h"
#import "SwrveBaseCampaign.h"
#import "SwrvePrivateBaseCampaign.h"

const static int  DEFAULT_MAX_IMPRESSIONS        = 99999;
const static int  DEFAULT_DELAY_FIRST_MSG        = 180;
const static int  DEFAULT_MIN_DELAY_BETWEEN_MSGS = 60;

@interface SwrveBaseCampaign()
@property (retain, nonatomic) NSDate*       dateStart;
@property (retain, nonatomic) NSDate*       dateEnd;
@property (retain, nonatomic) NSMutableSet* triggers;
@property (retain, nonatomic) NSDate* initialisedTime;
@property (atomic) BOOL randomOrder;
@end

@implementation SwrveBaseCampaign

@synthesize ID;
@synthesize maxImpressions;
@synthesize minDelayBetweenMsgs;
@synthesize impressions;
@synthesize showMsgsAfterLaunch;
@synthesize showMsgsAfterDelay;
@synthesize name;
@synthesize dateStart;
@synthesize dateEnd;
@synthesize triggers;
@synthesize initialisedTime;
@synthesize next;
@synthesize randomOrder;
@synthesize inbox;
@synthesize subject;
@synthesize status;

-(id)initAtTime:(NSDate*)time fromJSON:(NSDictionary *)dict withAssetsQueue:(NSMutableSet*)assetsQueue forController:(SwrveMessageController*)controller
{
    #pragma unused(assetsQueue, controller)
    self = [super init];
    // Default both dates to now
    NSDate* now = [NSDate date];
    [self setDateStart:now];
    [self setDateEnd:now];
    
    [self setMaxImpressions:DEFAULT_MAX_IMPRESSIONS];
    [self setMinDelayBetweenMsgs:DEFAULT_MIN_DELAY_BETWEEN_MSGS];
    [self setInitialisedTime:time];
    [self setShowMsgsAfterLaunch:[[self initialisedTime] dateByAddingTimeInterval:DEFAULT_DELAY_FIRST_MSG]];
    
    [self setTriggers:[[NSMutableSet alloc] init]];
    
    // Load from JSON
    self.ID   = [[dict objectForKey:@"id"] unsignedIntegerValue];
    self.name = [dict objectForKey:@"name"];
    self.inbox = [[dict objectForKey:@"inbox"] boolValue];
    self.subject = [dict objectForKey:@"subject"];
    self.status = SWRVE_CAMPAIGN_STATUS_UNSEEN;
    
    [self loadTriggersFrom:dict];
    [self loadRulesFrom:   dict];
    [self loadDatesFrom:   dict];
    
    return self;
}

-(void)setMessageMinDelayThrottle:(NSDate*)timeShown
{
    [self setShowMsgsAfterDelay:[timeShown dateByAddingTimeInterval:[self minDelayBetweenMsgs]]];
}

-(void)wasShownToUserAt:(NSDate*)timeShown
{
    self.impressions += 1;
    [self setMessageMinDelayThrottle:timeShown];
    self.status = SWRVE_CAMPAIGN_STATUS_SEEN;
}

static NSDate* read_date(id d, NSDate* default_date)
{
    double millis = [d doubleValue];
    
    if (millis > 0){
        double seconds = millis / 1000.0;
        return [NSDate dateWithTimeIntervalSince1970:seconds];
    } else {
        return default_date;
    }
}

-(void)loadDatesFrom:(NSDictionary*)json
{
    self.dateStart = read_date([json objectForKey:@"start_date"], self.dateStart);
    self.dateEnd   = read_date([json objectForKey:@"end_date"],   self.dateEnd);
}

-(void)loadRulesFrom:(NSDictionary*)json
{
    NSDictionary* rules = [json objectForKey:@"rules"];
    DebugLog(@"Rules: %@", rules);
    self.randomOrder = [[rules objectForKey:@"display_order"] isEqualToString: @"random"];
    NSNumber* jsonMaxImpressions = [rules objectForKey:@"dismiss_after_views"];
    if (jsonMaxImpressions)
    {
        self.maxImpressions = jsonMaxImpressions.unsignedIntegerValue;
    }
    
    NSNumber* delayFirstMsg = [rules objectForKey:@"delay_first_message"];
    if (delayFirstMsg)
    {
        self.showMsgsAfterLaunch = [self.initialisedTime dateByAddingTimeInterval:delayFirstMsg.integerValue];
    }
    
    NSNumber* jsonMinDelayBetweenMsgs = [rules objectForKey:@"min_delay_between_messages"];
    if (jsonMinDelayBetweenMsgs)
    {
        self.minDelayBetweenMsgs = [jsonMinDelayBetweenMsgs doubleValue];
    }
}

-(void)loadTriggersFrom:(NSDictionary*)json
{
    NSArray* jsonTriggers = [json objectForKey:@"triggers"];
    if (!jsonTriggers) {
        DebugLog(@"Error loading triggers", nil);
        return;
    }
    
    for (NSString* trigger in jsonTriggers){
        if (trigger) {
            [self.triggers addObject:[trigger lowercaseString]];
        }
    }
    
    DebugLog(@"Campaign Triggers:", nil);
    for (NSString* trigger in self.triggers){
#pragma unused(trigger)
        DebugLog(@"- %@", trigger);
    }
}

-(BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate*)now
{
    return [now compare:[self showMsgsAfterLaunch]] == NSOrderedAscending;
}

-(BOOL)isTooSoonToShowMessageAfterDelay:(NSDate*)now
{
    return [now compare:[self showMsgsAfterDelay]] == NSOrderedAscending;
}

-(void)logAndAddReason:(NSString*)reason withReasons:(NSMutableDictionary*)campaignReasons
{
    if(campaignReasons != nil) {
        [campaignReasons setValue:reason forKey:[[NSNumber numberWithUnsignedInteger:self.ID] stringValue]];
        DebugLog(@"%@",reason);
    }
}

-(NSMutableDictionary*)campaignSettings
{
    NSMutableDictionary* settings = [[NSMutableDictionary alloc] init];
    [settings setValue:[NSNumber numberWithUnsignedInteger:[self ID]] forKey:@"ID"];
    [settings setValue:[NSNumber numberWithUnsignedInteger:[self impressions]] forKey:@"impressions"];
    [settings setValue:[NSNumber numberWithUnsignedInteger:[self status]] forKey:@"status"];
    return settings;
}

-(void)loadSettings:(NSDictionary *)settings
{
    NSNumber* nextJson = [settings objectForKey:@"next"];
    if (nextJson) {
        self.next = nextJson.unsignedIntegerValue;
    }
    NSNumber* impressionsJson = [settings objectForKey:@"impressions"];
    if (impressionsJson) {
        self.impressions = impressionsJson.unsignedIntegerValue;
    }
    NSNumber* statusJson = [settings objectForKey:@"status"];
    if (statusJson) {
        self.status = (SwrveCampaignStatus)statusJson.unsignedIntegerValue;
    }
}

-(BOOL)isActive:(NSDate*)time withReasons:(NSMutableDictionary*)campaignReasons
{
    if ([self.dateStart compare:time] != NSOrderedAscending)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld has not started yet", (long)self.ID] withReasons:campaignReasons];
        return FALSE;
    }
    
    if ([time compare:self.dateEnd] != NSOrderedAscending)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld has finished", (long)self.ID] withReasons:campaignReasons];
        return FALSE;
    }
    
    return TRUE;
}

-(BOOL)checkCampaignRulesForEvent:(NSString*)event
                           atTime:(NSDate*)time
                      withReasons:(NSMutableDictionary*)campaignReasons
{
    if (![self isActive:time withReasons:campaignReasons])
    {
        return FALSE;
    }
    
    // Ignore delay after launch throttle limit for auto show messages
    if ([event caseInsensitiveCompare:AUTOSHOW_AT_SESSION_START_TRIGGER] != NSOrderedSame && [self isTooSoonToShowMessageAfterLaunch:time])
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Too soon after launch. Wait until %@", [SwrveMessageController getTimeFormatted:self.showMsgsAfterLaunch]] withReasons:campaignReasons];
        return FALSE;
    }
    
    if ([self isTooSoonToShowMessageAfterDelay:time])
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Too soon after last message. Wait until %@", [SwrveMessageController getTimeFormatted:self.showMsgsAfterDelay]] withReasons:campaignReasons];
        return FALSE;
    }
    
    if (self.impressions >= self.maxImpressions)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Campaign %ld has been shown %ld times already", (long)self.ID, (long)self.maxImpressions] withReasons:campaignReasons];
        return FALSE;
    }
    
    return TRUE;
}

-(void)addAssetsToQueue:(NSMutableSet*)assetsQueue
{
#pragma unused(assetsQueue)
    // Implemented in sub classes
}

@end
