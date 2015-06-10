#import "SwrveContentSpacer.h"
#import "SwrveSetup.h"
#import "SwrveConversationStyler.h"

@interface SwrveContentSpacer () {
    NSString *_height;
}
@end

@implementation SwrveContentSpacer

@synthesize height = _height;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentSpacer andDictionary:dict];
    _height = [dict objectForKey:@"spacerHeight"];
    return self;
}

-(void) loadView {
    float spacer_height = (_height) ? [_height floatValue] : 0;
    _view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [SwrveConversationAtom widthOfContentView], spacer_height)];
    [SwrveConversationStyler styleView:_view withStyle:self.style];
}

-(UIView *)view {
    if(!_view) {
        [self loadView];
    }
    return _view;
}

@end
