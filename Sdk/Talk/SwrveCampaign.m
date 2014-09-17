#import "Swrve.h"
#import "SwrveCampaign.h"

const static int  DEFAULT_MAX_IMPRESSIONS        = 99999;
const static int  DEFAULT_DELAY_FIRST_MSG        = 180;
const static int  DEFAULT_MIN_DELAY_BETWEEN_MSGS = 60;

@interface SwrveCampaign()
@property (atomic) BOOL randomOrder;
@property (retain, nonatomic) NSDate*       dateStart;
@property (retain, nonatomic) NSDate*       dateEnd;
@property (retain, nonatomic) NSMutableSet* triggers;
@property (retain, nonatomic) NSDate* initialisedTime;
@end

@implementation SwrveCampaign

@synthesize messages;
@synthesize next;
@synthesize ID;
@synthesize maxImpressions;
@synthesize minDelayBetweenMsgs;
@synthesize impressions;
@synthesize showMsgsAfterLaunch;
@synthesize showMsgsAfterDelay;
@synthesize name;
@synthesize randomOrder;
@synthesize dateStart;
@synthesize dateEnd;
@synthesize triggers;
@synthesize initialisedTime;

-(id)initAtTime:(NSDate*)time
{
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
    return self;
}

-(void)messageWasShownToUser:(SwrveMessage *)message
{
    [self messageWasShownToUser:message at:[NSDate date]];
}

-(void)setMessageMinDelayThrottle:(NSDate*)timeShown
{
    [self setShowMsgsAfterDelay:[timeShown dateByAddingTimeInterval:[self minDelayBetweenMsgs]]];
}

-(void)messageWasShownToUser:(SwrveMessage*)message at:(NSDate*)timeShown
{
    #pragma unused(message)
    [self incrementImpressions];
    [self setMessageMinDelayThrottle:timeShown];
    
    if (![self randomOrder])
    {
        NSUInteger count = [[self messages] count];
        NSUInteger nextMessage = ([self next] + 1) % count;
        DebugLog(@"Round Robin message in campaign %ld is %ld (next will be %ld)", (unsigned long)[self ID], (unsigned long)[self next], (unsigned long)nextMessage);
        [self setNext:nextMessage];
    }
}

-(void)messageDismissed:(NSDate *)timeDismissed
{
    [self setMessageMinDelayThrottle:timeDismissed];
}

-(void)incrementImpressions;
{
    self.impressions += 1;
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

-(void)loadDatesFrom:(NSDictionary*)json {
    self.dateStart = read_date([json objectForKey:@"start_date"], self.dateStart);
    self.dateEnd   = read_date([json objectForKey:@"end_date"],   self.dateEnd);
}

-(void)loadRulesFrom:(NSDictionary*)json {

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

-(void)loadTriggersFrom:(NSDictionary*)json{

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

static SwrveMessage* firstFormatFrom(NSArray* messages, NSSet* assets){

    // Return the first fully downloaded format
    for (SwrveMessage* message in messages) {
        if ([message areDownloaded:assets]){
            return message;
        }
    }
    return nil;
}

/**
 * Quick check to see if this campaign might have messages matching this event trigger
 * This is used to decide if the campaign is a valid candidate for automatically showing at session start
 */
-(BOOL)hasMessageForEvent:(NSString*)event
{
    return [self triggers] != nil && [[self triggers] containsObject:[event lowercaseString]];
}

-(SwrveMessage*)getMessageForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time

{
    return [self getMessageForEvent:event withAssets:assets atTime:time withReasons:nil];
}


-(SwrveMessage*)getMessageForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
                       withReasons:(NSMutableDictionary*)campaignReasons
{
    if (![self hasMessageForEvent:event]){
        DebugLog(@"There is no trigger in %ld that matches %@", (long)self.ID, event);
        return nil;
    }

    if ([[self messages] count] == 0)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"No messages in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    if ([self.dateStart compare:time] != NSOrderedAscending)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld has not started yet", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    if ([time compare:self.dateEnd] != NSOrderedAscending)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld has finished", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    // Ignore delay after launch throttle limit for auto show messages
    if ([event caseInsensitiveCompare:AUTOSHOW_AT_SESSION_START_TRIGGER] != NSOrderedSame && [self isTooSoonToShowMessageAfterLaunch:time])
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Too soon after launch. Wait until %@", [SwrveMessageController getTimeFormatted:self.showMsgsAfterLaunch]] withReasons:campaignReasons];
        return nil;
    }
    
    if ([self isTooSoonToShowMessageAfterDelay:time])
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Too soon after last message. Wait until %@", [SwrveMessageController getTimeFormatted:self.showMsgsAfterDelay]] withReasons:campaignReasons];
        return nil;
    }
    
    if (self.impressions >= self.maxImpressions)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Campaign %ld has been shown %ld times already", (long)self.ID, (long)self.maxImpressions] withReasons:campaignReasons];
        return nil;
    }

    SwrveMessage* message = nil;
    if (self.randomOrder)
    {
        DebugLog(@"Random Message in %ld", (long)self.ID);
        NSArray* shuffled = [SwrveMessageController shuffled:self.messages];
        message = firstFormatFrom(shuffled, assets);
    }

    if (message == nil)
    {
        message = [self.messages objectAtIndex:(NSUInteger)self.next];
    }
    
    if ([message areDownloaded:assets]) {
        DebugLog(@"%@ matches a trigger in %ld", event, (long)self.ID);
        return message;
    }
    
    [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld hasn't finished downloading", (long)self.ID] withReasons:campaignReasons];
    return nil;
}

-(void)logAndAddReason:(NSString*)reason withReasons:(NSMutableDictionary*)campaignReasons
{
    if(campaignReasons != nil) {
        [campaignReasons setValue:reason forKey:[[NSNumber numberWithUnsignedInteger:self.ID] stringValue]];
    }
    DebugLog(@"%@",reason);
}

-(NSDictionary*)campaignSettings
{
    NSMutableDictionary* settings = [[NSMutableDictionary alloc] init];

    [settings setValue:[NSNumber numberWithUnsignedInteger:[self ID]] forKey:@"ID"];
    [settings setValue:[NSNumber numberWithUnsignedInteger:[self next]] forKey:@"next"];
    [settings setValue:[NSNumber numberWithUnsignedInteger:[self impressions]] forKey:@"impressions"];
    return [NSDictionary dictionaryWithDictionary:settings];
}

@end
