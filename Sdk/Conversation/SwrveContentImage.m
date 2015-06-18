#import "SwrveContentImage.h"

@interface SwrveContentImage () {
    UIImageView *iv;
}
@end

@implementation SwrveContentImage

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeImage andDictionary:dict];
    return self;
}

-(void) loadView {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        NSString* cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString* swrve_folder = @"com.ngt.msgs";
        NSURL* bgurl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cache, swrve_folder, self.value, nil]];
        UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:bgurl]];

        [self sizeAndDisplayImage:image];
    });
}

- (void)sizeAndDisplayImage:(UIImage *)image
{
    // Create _view and add image to it
    iv = [[UIImageView alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Image setting and manipulation should be done on the main thread, otherwise this slows down a lot on iOS 7
        self->iv.image = image;
        [self->iv sizeToFit];
        CGRect r = self->iv.frame;
        self->iv.frame = CGRectMake(r.origin.x, r.origin.y, [SwrveConversationAtom widthOfContentView], (r.size.height/r.size.width*[SwrveConversationAtom widthOfContentView]));
        self->_view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [SwrveConversationAtom widthOfContentView], self->iv.frame.size.height)];
        [self->_view addSubview:self->iv];
    });
    // Notify that the view is ready to be displayed
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
    // Get notified if the view should change dimensions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:kSwrveNotifyOrientationChange object:nil];
}

-(UIView *)view {
    if(!_view) {
        [self loadView];
    }
    return _view;
}

// Respond to device orientation changes by resizing the width of the view
// Subviews of this should be flexible using AutoResizing masks
-(void) deviceOrientationDidChange {
    _view.frame = [self newFrameForOrientationChange];
    // Redraw the image and image view within this view
    CGRect ivCgRect = iv.frame;

    // Too big or same size?
    if (ivCgRect.size.width>0 && ivCgRect.size.width >= _view.frame.size.width) {
        iv.frame = CGRectMake(0.0, 0.0, _view.frame.size.width, ivCgRect.size.height/ ivCgRect.size.width*_view.frame.size.width);
    }
    // Too small?
    if(ivCgRect.size.width < _view.frame.size.width) {
        iv.frame = CGRectMake((_view.frame.size.width- ivCgRect.size.width)/2, ivCgRect.origin.y, ivCgRect.size.width, ivCgRect.size.height);
    }
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kSwrveNotifyOrientationChange object:nil];
}

@end
