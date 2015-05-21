#import <UIKit/UIKit.h>
#import "SwrveSetup.h"

// Content types
#define kSwrveContentTypeText @"text"
#define kSwrveContentTypeHTML @"html-fragment"
#define kSwrveContentTypeImage @"image"
#define kSwrveContentTypeVideo @"video"
// Input types
#define kSwrveInputTypeText @"text-input"
#define kSwrveInputMultiValueLong @"multi-value-long-input"
#define kSwrveInputMultiValue @"multi-value-input"
// Control types
#define kSwrveControlTypeButton @"button"

// Notifications
#define kSwrveNotificationViewReady @"SwrveNotificationViewReady"

@interface SwrveConversationAtom : NSObject {
    UIView *_view;
}

@property (readonly, nonatomic) NSString *tag;
@property (readonly, nonatomic) NSString *type;
@property (readonly, nonatomic) UIView *view;
@property (strong, nonatomic)   NSDictionary *style;

-(id)                initWithTag:(NSString *)tag andType:(NSString *)type;
-(BOOL)              willRequireLandscape;
-(CGRect)            newFrameForOrientationChange;
-(NSUInteger)        numberOfRowsNeeded;
-(CGFloat)           heightForRow:(NSUInteger) row;
-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView;

// Subclasses should override this
-(void) loadView;

// If the atom has some kind of activity going, then
// this is notice to cease it. Defaults to doing nothing.
-(void) stop;

+(CGFloat) widthOfContentView;
@end
