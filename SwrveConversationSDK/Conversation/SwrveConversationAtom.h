#import <UIKit/UIKit.h>
#import "SwrveSetup.h"

@class SwrveBaseConversation;

#define kSwrveKeyTag @"tag"
#define kSwrveKeyType @"type"
#define kSwrveKeyValues @"values"
#define kSwrveKeyAnswerId @"answer_id"
#define kSwrveKeyAnswerText @"answer_text"
#define kSwrveKeyStyle @"style"
#define kSwrveKeyFontFile @"font_file"
#define kSwrveKeyFontDigest @"font_digest"
#define kSwrveKeyFontPostscriptName @"font_postscript_name"
#define kSwrveKeyFontNativeStyle @"font_native_style"
#define kSwrveKeyTextSize @"text_size"
#define kSwrveKeyAlignment @"alignment"

// Content types
#define kSwrveContentTypeHTML @"html-fragment"
#define kSwrveContentTypeImage @"image"
#define kSwrveContentTypeVideo @"video"
#define kSwrveContentSpacer @"spacer"
#define kSwrveContentUnknown @"UNKNOWN"
// Input types
#define kSwrveInputMultiValue @"multi-value-input"
// Control types
#define kSwrveControlTypeButton @"button"
#define kSwrveContentStarRating @"star-rating"

// Notifications
#define kSwrveNotificationViewReady @"SwrveNotificationViewReady"

// Orientation Change delegate
@protocol SwrveConversationAtomDelegate <NSObject>

@required
- (void) respondToDeviceOrientationChange:(UIDeviceOrientation) orientation;

@end

@interface SwrveConversationAtom : NSObject {
    UIView *_view;
}

@property (readonly, nonatomic) NSString *tag;
@property (readonly, nonatomic) NSString *type;
@property (readonly, nonatomic) UIView *view;
@property (strong, nonatomic)   NSDictionary *style;
@property (strong, nonatomic) id <SwrveConversationAtomDelegate> delegate;

-(id)                initWithTag:(NSString *)tag andType:(NSString *)type;
-(CGRect)            newFrameForOrientationChange;
-(NSUInteger)        numberOfRowsNeeded;
-(CGFloat)           heightForRow:(NSUInteger) row inTableView:(UITableView *)tableView;
-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView;

// Subclasses should override this
-(void) loadViewWithContainerView:(UIView*)containerView;
-(void) parentViewChangedSize:(CGSize)size;

// If the atom has some kind of activity going, then
// this is notice to cease it. Defaults to doing nothing.
-(void) stop;
-(void) viewDidDisappear;
// Temporal fix to remove views from model.
-(void) removeView;

@end
