#import "Plot.h"

@interface SwrvePlotDelegate : NSObject<PlotDelegate>

@property (atomic, retain) NSDictionary* launchOptions;

+ (SwrvePlotDelegate*)sharedInstance;
-(void)startPlot;
-(void)didReceiveLocalNotification:(UILocalNotification *)notification;

@end
