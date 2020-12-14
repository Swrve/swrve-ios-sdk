#import <UIKit/UIKit.h>
#import "SwrveSetup.h"

@class SwrveBaseConversation;

static NSString *const kSwrveKeyTag                = @"tag";
static NSString *const kSwrveKeyType               = @"type";
static NSString *const kSwrveKeyValues             = @"values";
static NSString *const kSwrveKeyAnswerId           = @"answer_id";
static NSString *const kSwrveKeyAnswerText         = @"answer_text";
static NSString *const kSwrveKeyStyle              = @"style";
static NSString *const kSwrveKeyFontFile           = @"font_file";
static NSString *const kSwrveKeyFontPostscriptName = @"font_postscript_name";
static NSString *const kSwrveKeyFontDigest         = @"font_digest";
static NSString *const kSwrveKeyFontNativeStyle    = @"font_native_style";
static NSString *const kSwrveKeyTextSize           = @"text_size";
static NSString *const kSwrveKeyAlignment          = @"alignment";

// Content types
static NSString *const kSwrveContentTypeHTML   = @"html-fragment";
static NSString *const kSwrveContentTypeImage  = @"image";
static NSString *const kSwrveContentTypeVideo  = @"video";
static NSString *const kSwrveContentSpacer     = @"spacer";
static NSString *const kSwrveContentUnknown    = @"UNKNOWN";
// Input types
static NSString *const kSwrveInputMultiValue   = @"multi-value-input";
// Control types
static NSString *const kSwrveControlTypeButton = @"button";
static NSString *const kSwrveContentStarRating = @"star-rating";

// Notifications
static NSString *const kSwrveNotificationViewReady = @"SwrveNotificationViewReady";

// Orientation Change delegate
@protocol SwrveConversationAtomDelegate <NSObject>

@required
#if TARGET_OS_IOS /** exclude tvOS **/
- (void) respondToDeviceOrientationChange:(UIDeviceOrientation) orientation;
#endif
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
