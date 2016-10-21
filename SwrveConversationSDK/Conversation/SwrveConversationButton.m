#import "SwrveConversationButton.h"
#import "SwrveConversationUIButton.h"

@implementation SwrveConversationButton

@synthesize description = _description;
@synthesize actions = _actions;
@synthesize target = _target;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveControlTypeButton];
    if(self) {
        if([dict objectForKey:kSwrveKeyDescription]) {
            _description = [dict objectForKey:kSwrveKeyDescription];
        }
        _target = nil;
        NSString *target = [dict objectForKey:@"target"]; // Leave the target nil if this a conversation ender (i.e. no following state)
        if (target && ![target isEqualToString:@""]) {
            _target = target;
        }
        if([dict objectForKey:@"action"]) {
            _actions = [dict objectForKey:@"action"];
        }

        NSDictionary *immutableStyle = [dict objectForKey:kSwrveKeyStyle];
        NSMutableDictionary *style = [immutableStyle mutableCopy];
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

-(BOOL) endsConversation {
    return _target == nil;
}

-(UIView *)view {
    if(_view == nil) {
        SwrveConversationUIButton *button = [SwrveConversationUIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:_description forState:UIControlStateNormal];
        _view = button;
    }
    return _view;
}

@end
