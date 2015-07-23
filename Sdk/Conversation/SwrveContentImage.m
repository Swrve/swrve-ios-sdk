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

-(void) loadViewWithContainerView:(UIView*)containerView {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        NSString* cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString* swrve_folder = @"com.ngt.msgs";
        NSURL* bgurl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cache, swrve_folder, self.value, nil]];
        UIImage* image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:bgurl]];
        [self sizeAndDisplayImage:image withContainer:containerView];
    });
}

- (void)sizeAndDisplayImage:(UIImage*)image withContainer:(UIView*)containerView
{
    if (image != nil) {
        // Create _view and add image to it
        _view = iv = [[UIImageView alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Image setting and manipulation should be done on the main thread, otherwise this slows down a lot on iOS 7
            self->iv.image = image;
            CGFloat containerWidth = containerView.frame.size.width;
            CGSize imageSize = image.size;
            self->iv.frame = CGRectMake(0, 0, containerWidth, ((imageSize.height/imageSize.width)*containerWidth));
        });
        // Notify that the view is ready to be displayed
        [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
        // Get notified if the view should change dimensions
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:kSwrveNotifyOrientationChange object:nil];
    }
}

// Respond to device orientation changes by resizing the width of the view
// Subviews of this should be flexible using AutoResizing masks
-(void) deviceOrientationDidChange {
    _view.frame = [self newFrameForOrientationChange];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSwrveNotifyOrientationChange object:nil];
}

@end
