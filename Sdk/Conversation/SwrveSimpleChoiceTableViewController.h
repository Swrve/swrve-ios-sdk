#import <UIKit/UIKit.h>
#import "SwrveChoiceArray.h"

@interface SwrveSimpleChoiceTableViewController : UITableViewController

@property(nonatomic, strong) SwrveChoiceArray *choiceValues;
@property(nonatomic, strong) NSDictionary *pageStyle;
@property(nonatomic, strong) NSDictionary *choiceStyle;

@end
