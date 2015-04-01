#import "Demo.h"

/*
 * A node in the demo menu tree.
 */
@interface DemoMenuNode : NSObject {
    
    NSString* title;
    NSString* name;
    NSString* description;
    
    NSArray* children;
    Demo* demo;
};

/*
 * Short title for the demo or category.  Is shown as the header in the UITableView.
 */
@property (nonatomic,retain) NSString* title;
/*
 * One or two word name for the demo or category.  Is shown as the cell in the UITableView.
 */
@property (nonatomic,retain) NSString* name;
/*
 * Full description of the demo or category.  Is shown as the footer in the UITableView.
 */
@property (nonatomic,retain) NSString* description;
/*
 * Child demos of the category or null if the node is a leaf.
 */
@property (nonatomic,retain) NSArray* children;
/*
 * UIViewController of the demo if the node is a leaf or null if the node is a category.
 */
@property (nonatomic,retain) Demo* demo;

/*
 * Iterates over all nodes in the tree and calls callback for each node.
 */
+(void) enumerate:(DemoMenuNode *)node withCallback:(void (^)(DemoMenuNode *node))callback;

@end

/*
 * View that is the main demo menu in the app.  Shows demos in a
 * grouped table format.
 */
@interface DemoMenuViewController : UIViewController {
    
    DemoMenuNode *menuNode;
};

@property (nonatomic,retain) DemoMenuNode *menuNode;

@end
