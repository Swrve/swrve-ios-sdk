#import <UIKit/UIKit.h>
#import "SwrveSetup.h"

// Content types
#define kSwrveContentTypeText @"text"
#define kSwrveContentTypeHTML @"html-fragment"
#define kSwrveContentTypeImage @"image"
#define kSwrveContentTypeVideo @"video"
#define kSwrveContentTypeTalkback @"talkback"
// Input types
#define kSwrveInputTypeText @"text-input"
#define kSwrveInputReaction @"reaction-input"
#define kSwrveInputMultiValueLong @"multi-value-long-input"
#define kSwrveInputSlider @"slider-input"
#define kSwrveInputMultiValue @"multi-value-input"
#define kSwrveNetPromoter @"nps-input"
#define kSwrveCalendarInput @"calendar-input"
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
