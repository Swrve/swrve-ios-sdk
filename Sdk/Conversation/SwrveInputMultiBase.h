#import "SwrveInputItem.h"

@interface SwrveInputMultiBase : SwrveInputItem

@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *description;

-(void)             loadViewWithContainerView:(UIView*)containerView;
-(BOOL)             hasDescription;
-(NSUInteger)       numberOfRowsNeeded;
-(CGFloat)          heightForRow:(NSUInteger)row;

-(UITableViewCell*) fetchDescriptionCell:(UITableView*)tableView;
-(UITableViewCell*) fetchStandardCell:(UITableView*)tableView;
-(UITableViewCell*) styleCell:(UITableViewCell *)cell atRow:(NSUInteger)row;
@end
