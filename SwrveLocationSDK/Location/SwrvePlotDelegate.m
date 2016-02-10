#import "SwrvePlotDelegate.h"
#import "SwrvePlot.h"

static SwrvePlotDelegate *_swrveSharedPlot = NULL;
static dispatch_once_t sharedInstanceToken = 0;

@implementation SwrvePlotDelegate

+(SwrvePlotDelegate*) sharedInstance
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedPlot = [SwrvePlotDelegate alloc];
    });
    return _swrveSharedPlot;
}

-(void)startPlot {
    [SwrvePlot initializeWithLaunchOptions:[self launchOptions] delegate:self];
}

-(void)didReceiveLocalNotification:(UILocalNotification *)notification {
    [Plot handleNotification:notification];
}

-(void)plotFilterNotifications:(PlotFilterNotifications*)filterNotifications {
    [SwrvePlot filterLocationCampaigns:filterNotifications];
}

-(void)plotHandleNotification:(UILocalNotification*)localNotification data:(NSString*)data {
    [SwrvePlot engageLocationCampaign:localNotification withData:data];
}

@end
