#import "SwrveContentStarRatingView.h"
#import "SwrveConversationResourceManagement.h"
#import "SwrveSetup.h"

static float const kSwrveStarRatingHeight = 60.0f;
static float const kSwrveStarRatingPadding = 40.0f;

@interface SwrveContentStarRatingView ()

@property (strong, nonatomic) UIImage *swrveNotSelectedImage;
@property (strong, nonatomic) UIImage *swrveFullSelectedImage;
@property (strong, nonatomic) UIImage *swrveNotSelectedImageTinted;
@property (strong, nonatomic) UIImage *swrveFullSelectedImageTinted;
@property (strong, nonatomic) UIColor *swrveBackgroundColor;
@property (strong, nonatomic) UIColor *swrveStarColor;
@property (readwrite, nonatomic) float swrveCurrentRating;
@property (readwrite, nonatomic) NSUInteger swrveMaxRating;
@property (readwrite, nonatomic) float swrveMinMidMargin;
@property (strong, nonatomic) NSMutableArray * swrveStarViews;
@property (assign, atomic) CGSize swrveMinImageSize;

@end

@implementation SwrveContentStarRatingView

@synthesize swrveNotSelectedImage;
@synthesize swrveFullSelectedImage;
@synthesize swrveNotSelectedImageTinted;
@synthesize swrveFullSelectedImageTinted;
@synthesize swrveBackgroundColor;
@synthesize swrveStarColor;
@synthesize swrveCurrentRating;
@synthesize swrveMaxRating;
@synthesize swrveMinMidMargin;
@synthesize swrveStarViews;
@synthesize swrveMinImageSize;
@synthesize swrveRatingDelegate;

- (id) initWithDefaults {
    self = [super init];
    if(self){
        self.swrveStarViews = [NSMutableArray new];
        self.swrveNotSelectedImage =  [SwrveConversationResourceManagement imageWithName:@"star_empty"];
        self.swrveFullSelectedImage = [SwrveConversationResourceManagement imageWithName:@"star_full"];
        self.swrveStarColor = [UIColor redColor];
        self.swrveCurrentRating = 0;
        self.swrveMaxRating = 5;
        self.swrveMinMidMargin = 5.0f;
        self.swrveMinImageSize = CGSizeMake(40, 40);

        [self cacheTintImages];
        [self setStarsFromMax];
    }
    return self;
}

- (void) setDelegate:(id<SwrveConversationStarRatingViewDelegate>)delegate {
    self.swrveRatingDelegate = delegate;
}

- (void) setAvailableWidth:(CGFloat)width {
    CGRect frame = CGRectMake(kSwrveStarRatingPadding/2, 0, 0, 0);
    frame.size.width = width - kSwrveStarRatingPadding;
    frame.size.height = [self starHeightFromWidth:frame.size.width];
    self.frame = frame;
}

- (void) setStarsFromMax {
    [self.swrveStarViews removeAllObjects];
    // Add new image views
    for(NSUInteger i = 0; i < self.swrveMaxRating; ++i) {
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.swrveStarViews addObject:imageView];
        [self addSubview:imageView];
    }
    [self setNeedsLayout];
    [self refresh];
}

- (void) updateWithStarColor:(UIColor *)starColor withBackgroundColor:(UIColor *)backgroundColor {
    self.swrveStarColor = starColor;
    self.swrveBackgroundColor = backgroundColor;
    [[self layer] setBackgroundColor:backgroundColor.CGColor];
    [self cacheTintImages];

    // Relayout and refresh
    [self setNeedsLayout];
    [self refresh];
}

- (void) cacheTintImages {
    if (self.swrveNotSelectedImage) {
        self.swrveNotSelectedImageTinted = [self tintImageWithColor:self.swrveStarColor withImage:swrveNotSelectedImage];
    }
    if (self.swrveFullSelectedImage) {
        self.swrveFullSelectedImageTinted = [self tintImageWithColor:self.swrveStarColor withImage:swrveFullSelectedImage];
    }
}

- (void) refresh {
    for(NSUInteger i = 0; i < self.swrveStarViews.count; ++i) {
        UIImageView *imageView = [self.swrveStarViews objectAtIndex:i];
        if (self.swrveCurrentRating >= i+1) {
            imageView.image = self.swrveFullSelectedImageTinted;
        } else {
            imageView.image = self.swrveNotSelectedImageTinted;
        }
    }
}

- (void) layoutSubviews {
    [super layoutSubviews];

    if (self.swrveNotSelectedImage == nil) return;

    CGFloat imageWidthHeight = [self starHeightFromWidth:self.frame.size.width];
    // Calculate spacing between stars
    CGFloat spacing = (self.frame.size.width - imageWidthHeight*self.swrveStarViews.count) / (self.swrveStarViews.count - 1);
    // Set size and location to stars
    for (NSUInteger i = 0; i < self.swrveStarViews.count; ++i) {
        UIImageView *imageView = [self.swrveStarViews objectAtIndex:i];
        CGRect imageFrame = CGRectMake(i * (spacing + imageWidthHeight), 0, imageWidthHeight, imageWidthHeight);
        imageView.frame = imageFrame;
    }
}

- (CGFloat) starHeightFromWidth:(CGFloat)availableWidth {
    // Obtain the star rating width/height based on the space available
    CGFloat desiredImageWidth = (availableWidth - (self.swrveMinMidMargin * (self.swrveStarViews.count - 1))) / self.swrveStarViews.count;
    return SWRVEMIN(SWRVEMAX(self.swrveMinImageSize.width, desiredImageWidth), kSwrveStarRatingHeight);
}

#pragma mark - iOS6 change tint support
- (UIImage *) tintImageWithColor:(UIColor *)color withImage:(UIImage *)image {
    CGRect contextRect;
    contextRect.origin.x = 0.0f;
    contextRect.origin.y = 0.0f;
    contextRect.size = [image size];
    CGSize itemImageSize = [image size];
    CGPoint itemImagePosition;
    itemImagePosition.x = ((contextRect.size.width - itemImageSize.width) / 2);
    itemImagePosition.y = ((contextRect.size.height - itemImageSize.height) );
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, [[UIScreen mainScreen] scale]);

    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextBeginTransparencyLayer(c, NULL);
    CGContextScaleCTM(c, 1.0, -1.0);
    CGContextClipToMask(c, CGRectMake(itemImagePosition.x, -itemImagePosition.y, itemImageSize.width, -itemImageSize.height), [image CGImage]);

    color = [color colorWithAlphaComponent:1.0];

    CGContextSetFillColorWithColor(c, color.CGColor);

    contextRect.size.height = -contextRect.size.height;
    CGContextFillRect(c, contextRect);
    CGContextEndTransparencyLayer(c);

    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resultImage;
}

#pragma mark - User Interaction (touches)
- (void)handleTouchAtLocation:(CGPoint)touchLocation {
    int newRating = 0;
    for(int i = (int)self.swrveStarViews.count - 1; i >= 0; i--) {
        UIImageView *imageView = [swrveStarViews objectAtIndex:(NSUInteger)i];
        if (touchLocation.x > imageView.frame.origin.x) {
            newRating = i+1;
            break;
        }
    }

    self.swrveCurrentRating = newRating;
    if(self.swrveCurrentRating < 1.0){
        self.swrveCurrentRating = 1.0;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
#pragma unused(event)
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation];
    [self.swrveRatingDelegate ratingView:self ratingDidChange:self.swrveCurrentRating];
    [self refresh];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
#pragma unused(event)
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation];
    [self.swrveRatingDelegate ratingView:self ratingDidChange:self.swrveCurrentRating];
    [self refresh];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
#pragma unused(event)
#pragma unused(touches)
    [self.swrveRatingDelegate ratingView:self ratingDidChange:self.swrveCurrentRating];
}

@end
