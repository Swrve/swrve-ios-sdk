#import "SwrveConversationButton.h"
#import "SwrveConversationUIButton.h"

@implementation SwrveConversationButton

@synthesize description = _description;
@synthesize actions = _actions;
@synthesize target = _target;

-(id)initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveControlTypeButton];
    if(self) {
        
        NSString *description = [dict objectForKey:kSwrveKeyDescription];
        if ([description length] != 0) {
            _description = description;
        }

        NSString *target = [dict objectForKey:kSwrveKeyTarget];
        if ([target length] != 0) {
            _target = target;
        }

        NSDictionary *action = [dict objectForKey:kSwrveKeyAction];
        if (action) {
            _actions = action;
        }

        NSDictionary *immutableStyle = [dict objectForKey:kSwrveKeyStyle];
        NSMutableDictionary *style = [immutableStyle mutableCopy];
        // v1,v2,v3 won't have font details and a blank font file means using system font
        if (style && ![style objectForKey:kSwrveKeyFontFile]) {
            [style setObject:@"" forKey:kSwrveKeyFontFile];
        }
        if (style && ![style objectForKey:kSwrveKeyTextSize]) {
            [style setObject:kSwrveDefaultButtonFontSize forKey:kSwrveKeyTextSize];
        }
        if (style && ![style objectForKey:kSwrveKeyAlignment]) {
            [style setObject:kSwrveDefaultButtonAlignment forKey:kSwrveKeyAlignment];
        }
        self.style = style;
    }
    return self;
}

-(BOOL)endsConversation {
    return _target == nil;
}

-(UIView *)view {
    if(_view == nil) {
        SwrveConversationUIButton *button = [SwrveConversationUIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:_description forState:UIControlStateNormal];
        //Used by sdk systemtests
        button.accessibilityIdentifier = _description;
        _view = button;
    }
    return _view;
}

@end
