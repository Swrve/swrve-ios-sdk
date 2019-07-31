#import "SwrveContentSpacer.h"
#import "SwrveSetup.h"
#import "SwrveConversationStyler.h"

@interface SwrveContentSpacer () {
    float _height;
}
@end

@implementation SwrveContentSpacer

@synthesize height = _height;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentSpacer andDictionary:dict];
    id rawValue = [dict objectForKey:@"height"];
    if (rawValue) {
        _height = [rawValue floatValue];
    } else {
        _height = 0;
    }
    return self;
}

-(void) loadViewWithContainerView:(UIView*)containerView {
    // Height is defined as 'pixels' so we need to transform it to the point space
    float screenScale = (float)[[UIScreen mainScreen] scale];
    float spacer_height = _height / screenScale;
    _view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerView.frame.size.width, spacer_height)];
    [SwrveConversationStyler styleView:_view withStyle:self.style];
    // Notify that the view is ready to be displayed
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

-(void)parentViewChangedSize:(CGSize)size {
    // Mantain full width
    _view.frame = CGRectMake(0, 0, size.width, _view.frame.size.height);
}

@end
