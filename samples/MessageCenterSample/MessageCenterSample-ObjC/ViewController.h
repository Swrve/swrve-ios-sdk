#import <UIKit/UIKit.h>
#import "SwrveMessageDelegate.h"

@interface ViewController : UITableViewController<SwrveMessageDelegate>

@property (nonatomic, retain) NSArray *campaigns;

@end

