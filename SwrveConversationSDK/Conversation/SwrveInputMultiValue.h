#import "SwrveInputItem.h"

#define kSwrveDefaultMultiValueDescriptionFontSize [NSNumber numberWithDouble:20.0]
static NSString *const kSwrveDefaultMultiValueCellFontName =  @"Helvetica";
#define kSwrveDefaultMultiValueCellFontSize [NSNumber numberWithDouble:17.0]

@interface SwrveInputMultiValue : SwrveInputItem

@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) NSInteger selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
-(void) loadViewWithContainerView:(UIView*)containerView;
-(NSUInteger) numberOfRowsNeeded;
-(CGFloat) heightForRow:(NSUInteger)row inTableView:(UITableView *)tableView;

@end
