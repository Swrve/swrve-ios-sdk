#import <UIKit/UIKit.h>
#import "SwrveMessage.h"

@interface UISwrveButton : UIButton

@property (nonatomic, retain) NSString *displayString;
@property (nonatomic, retain) NSString *actionString;
@property(atomic) NSNumber *buttonId;
@property (nonatomic, retain) NSString *buttonName;

@end

