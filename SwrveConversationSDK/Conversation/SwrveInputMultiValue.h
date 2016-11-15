#import "SwrveInputItem.h"

@interface SwrveInputMultiValue : SwrveInputItem

@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) NSInteger selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
-(void) loadViewWithContainerView:(UIView*)containerView;
-(NSUInteger) numberOfRowsNeeded;
-(CGFloat) heightForRow:(NSUInteger)row inTableView:(UITableView *)tableView;

@end
