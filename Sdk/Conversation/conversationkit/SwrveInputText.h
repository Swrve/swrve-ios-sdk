#import "SwrveInputItem.h"
#import <QuartzCore/QuartzCore.h>

@interface SwrveInputText : SwrveInputItem <UITextViewDelegate>

@property(nonatomic, readonly) NSString *placeHolder;
@property(nonatomic, readonly) NSUInteger numberOfLines;
@property(nonatomic, readonly) NSString *descriptiveText;
@property (strong, nonatomic) UIToolbar *fieldAccessoryView;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
@end
