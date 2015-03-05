#import "Demo.h"

/*
 * A simple utility to view resoures stored in Swrve's servers.
 */
@interface ResourceViewer : Demo <UITableViewDataSource,UITableViewDelegate> {
    
    IBOutlet UITableView *resourceTable;
    IBOutlet UIButton *button;
    
    NSArray *resources;
    NSMutableArray *attributes;
    
    UIToolbar *toolbar;
    int viewAttributes;
}
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) NSArray *resources;
@property (atomic, retain) NSMutableArray *attributes;
@property (nonatomic, retain) IBOutlet UITableView *resourceTable;

@end
