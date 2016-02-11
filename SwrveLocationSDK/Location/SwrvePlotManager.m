#import "SwrvePlotManager.h"
#import "PlotPayload.h"
#import "SwrveCommon.h"
#import "SwrvePlot.h"

@implementation SwrvePlotManager

@synthesize locationCampaigns;

- (NSMutableArray*)filterLocationCampaigns:(PlotFilterNotifications *)filterNotifications {

    DebugLog(@"LocationCampaigns: Offered PlotFilterNotifications of size %lu.", (unsigned long)filterNotifications.uiNotifications.count);

    SwrveLocationManager * locationManager = [self getSwrveLocationManager];
    NSMutableArray* locationCampaignsMatched = [NSMutableArray array];
    for (UILocalNotification *localNotification in filterNotifications.uiNotifications) {
        NSString *payload = [localNotification.userInfo objectForKey:PlotNotificationActionKey];
        if (!payload) {
            DebugLog(@"Error in filterLocationCampaigns. No payload.", nil);
            continue;
        }

        PlotPayload *locationPayload = [[PlotPayload alloc] initWithPayload:payload];
        if (locationPayload == nil || locationPayload.campaignId == nil) {
            DebugLog(@"Error in filterLocationCampaigns. Problem parsing payload: %@", payload);
            continue;
        }

        SwrveLocationCampaign *locationCampaign = [locationManager locationWithCampaignId:locationPayload.campaignId];
        if (locationCampaign == nil || locationCampaign.message == nil || locationCampaign.message.locationMessageId == nil) {
            DebugLog(@"LocationCampaign not downloaded, or not targeted, or invalid. Payload: %@", payload);
            continue;
        }

        [locationCampaignsMatched addObject:localNotification];
    }

    NSMutableArray* notificationsToSend = [NSMutableArray array];
    if (locationCampaignsMatched.count == 0) {
        DebugLog(@"No LocationCampaigns were matched.", nil);
    } else {

        for(UILocalNotification *notificationToSend in locationCampaignsMatched) {

            NSString *payload = [notificationToSend.userInfo objectForKey:PlotNotificationActionKey];
            PlotPayload *plotPayload = [[PlotPayload alloc] initWithPayload:payload];
            DebugLog(@"LocationCampaigns: Matched campaignId:%@", plotPayload.campaignId);

            SwrveLocationCampaign *locationCampaign = [locationManager locationWithCampaignId:plotPayload.campaignId];
            SwrveLocationMessage *locationMessage = locationCampaign.message;

            if ([locationMessage expectsGeofenceLabel] == YES) {
                if(plotPayload.geofenceLabel == nil || [plotPayload.geofenceLabel length] == 0) {
                    DebugLog(@"LocationCampaigns: Not showing locationMessage %@. Missing geofenceLabel from plot payload: %@", locationMessage.locationMessageId, payload);
                    continue;
                } else {
                    notificationToSend.alertBody = [locationMessage.body stringByReplacingOccurrencesOfString:GEOFENCE_LABEL_PLACEHOLDER withString:plotPayload.geofenceLabel];
                }
            } else {
                notificationToSend.alertBody = locationMessage.body;
            }

            // add locationMessageId for engagement event later
            NSMutableDictionary *userInfoCopy = [NSMutableDictionary dictionaryWithDictionary:notificationToSend.userInfo];
            [userInfoCopy setObject:locationMessage.toJson forKey:PlotNotificationActionKey];

            [notificationToSend setUserInfo:userInfoCopy];
            [notificationsToSend addObject:notificationToSend];

            // TODO need test coverage on this to check an impression event is queued
            NSString *eventName = [NSString stringWithFormat:@"Swrve.Location.Location-%@.impression", locationMessage.locationMessageId];
            [[SwrveCommon getSwrveCommon] eventInternal:eventName payload:nil triggerCallback:true];
        }
    }

    [filterNotifications showNotifications:notificationsToSend];
    return notificationsToSend;
}

- (SwrveLocationManager *)getSwrveLocationManager {

    SwrveLocationManager *locationManager = [[SwrveLocationManager alloc] init];

    id<ISwrveCommon> swrveCommon = [SwrveCommon getSwrveCommon];
    NSData* data = [swrveCommon getCampaignData:SWRVE_CAMPAIGN_LOCATION];
    if (data != nil) {
        NSError* error = nil;
        NSDictionary* locationCampaignsDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            DebugLog(@"Error init location campaigns.\nError: %@\njson: %@", error, data);
        } else {
            NSDictionary* inner = [locationCampaignsDict valueForKey:@"campaigns"];
            if(nil != inner) {
                locationCampaignsDict = inner;
            }
            [locationManager updateWithDictionary:locationCampaignsDict];
        }
    }

    // debug information only
    if ([[locationManager locationCampaigns] count] < 20) {
        NSMutableString *campaignIds = [[NSMutableString alloc] init];
        for (id key in locationManager.locationCampaigns) {
            [campaignIds appendString:key];
            [campaignIds appendString:@","];
        }
        DebugLog(@"LocationCampaigns in cache:%@", campaignIds);
    }

    return locationManager;
}

- (int) engageLocationCampaign:(UILocalNotification*)localNotification withData:(NSString*)locationMessageJson {
#pragma unused (localNotification)

    int success = SWRVE_FAILURE;
    NSData *jsonData = [locationMessageJson dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *locationMessageDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (!error) {
        SwrveLocationMessage *locationMessage = [[SwrveLocationMessage alloc] initWithDictionary:locationMessageDictionary];

        // TODO need test coverage on this to check an engaged event is queued
        NSString *eventName = [NSString stringWithFormat:@"Swrve.Location.Location-%@.engaged", locationMessage.locationMessageId];
        success = [[SwrveCommon getSwrveCommon] eventInternal:eventName payload:nil triggerCallback:true];
        [[SwrveCommon getSwrveCommon] sendQueuedEvents];

        NSDictionary *payloadDictionary = locationMessage.getPayloadDictionary;
        NSString *deeplink = [payloadDictionary objectForKey:@"_sd"];
        if (deeplink) {
            DebugLog(@"LocationCampaigns: Opening deeplink:%@", deeplink);
            BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:deeplink]];
            if(canOpen) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:deeplink]];
            } else {
                DebugLog(@"LocationCampaigns: Cannot open deeplink:%@", deeplink);
            }
        }
    } else {
        DebugLog(@"LocationCampaigns: Error parsing data in engageLocationCampaign. Data:%@", locationMessageJson);
    }

    return success;
}

@end
