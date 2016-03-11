#import "SwrveConversationStarRatingView.h"
#import "SwrveSetup.h"

@interface SwrveConversationStarRatingView ()

@property (strong, nonatomic) UIImage *swrveNotSelectedImage;
@property (strong, nonatomic) UIImage *swrveFullSelectedImage;
@property (assign, nonatomic) UIColor *swrveBackgroundColor;
@property (assign, nonatomic) UIColor *swrveStarColor;
@property (readwrite, nonatomic) float swrveCurrentRating;
@property (readwrite, nonatomic) float swrveMaxRating;
@property (readwrite, nonatomic) float swrveLeftMargin;
@property (readwrite, nonatomic) float swrveMidMargin;
@property (strong, nonatomic) NSMutableArray * swrveStarViews;
@property (assign, atomic) CGSize swrveMinImageSize;
@property (strong, nonatomic) id <SwrveConversationStarRatingViewDelegate> delegate;

@end

@implementation SwrveConversationStarRatingView

@synthesize swrveStarViews;
@synthesize swrveNotSelectedImage;
@synthesize swrveFullSelectedImage;
@synthesize swrveStarColor;
@synthesize swrveBackgroundColor;
@synthesize swrveCurrentRating;
@synthesize swrveMaxRating;
@synthesize swrveMidMargin;
@synthesize swrveLeftMargin;
@synthesize swrveMinImageSize;
@synthesize delegate;


- (id) initWithDefaults {
    self =[super init];
    
    if(self){
        self.swrveStarViews = [[NSMutableArray alloc] init];
        self.swrveNotSelectedImage = [UIImage imageNamed:@"star-empty.png"];
        self.swrveFullSelectedImage = [UIImage imageNamed:@"star-full.png"];
        self.swrveStarColor = [UIColor colorWithRed:253.0f/255.0f green:193.0f/255.0f blue:45.0f/255.0f alpha:1.0f];
        self.swrveCurrentRating = 0;
        self.swrveMaxRating = 5.0f;
        self.swrveMidMargin = 5.0f;
        self.swrveLeftMargin = 0.0f;
        self.swrveMinImageSize = CGSizeMake(5, 5);
        self.delegate = nil;
    }
    
    return self;
}


- (void) initRatingTypewithStarColor:(UIColor *) starColor withBackgroundColor:(UIColor *)backgroundColor
          {
              self.swrveStarColor = starColor;
              self.swrveBackgroundColor = backgroundColor;
              [[self layer] setBackgroundColor:backgroundColor.CGColor];
              
              // Relayout and refresh
              [self setNeedsLayout];
              [self refresh];

}

- (void) refresh {
    for(NSUInteger i = 0; i < self.swrveStarViews.count; ++i) {
        UIImageView *imageView = [self.swrveStarViews objectAtIndex:i];
        if (self.swrveCurrentRating >= i+1) {
            imageView.image = self.swrveFullSelectedImage;
            if([imageView respondsToSelector:@selector(setTintColor:)]){
                imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [imageView setTintColor:self.swrveStarColor];
            }else{
                imageView.image = [self tintImageWithColor:self.swrveBackgroundColor withImage:imageView.image];
            }

        } else {
            imageView.image = self.swrveNotSelectedImage;
            if([imageView respondsToSelector:@selector(setTintColor:)]){
                imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [imageView setTintColor:self.swrveStarColor];
            }else{
                imageView.image = [self tintImageWithColor:self.swrveBackgroundColor withImage:imageView.image];
            }
        }
    }
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    if (self.swrveNotSelectedImage == nil) return;

    CGFloat desiredImageWidth = (self.frame.size.width - (self.swrveLeftMargin * 2) - (self.swrveMidMargin * self.swrveStarViews.count)) / self.swrveStarViews.count;

    CGFloat imageWidth = SWRVEMAX(self.swrveMinImageSize.width, desiredImageWidth);
    CGFloat imageHeight = SWRVEMAX(self.swrveMinImageSize.height, self.frame.size.height);
    
    for (NSUInteger i = 0; i < self.swrveStarViews.count; ++i) {
        
        UIImageView *imageView = [self.swrveStarViews objectAtIndex:i];
        CGRect imageFrame = CGRectMake((self.swrveLeftMargin + i) * (self.swrveMidMargin+imageWidth), 0, imageWidth, imageHeight);
        imageView.frame = imageFrame;
    }
}

#pragma mark - iOS6 change tint support

- (UIImage *) tintImageWithColor:(UIColor *)color withImage:(UIImage *)image
{
    CGRect contextRect;
    contextRect.origin.x = 0.0f;
    contextRect.origin.y = 0.0f;
    contextRect.size = [image size];
    CGSize itemImageSize = [image size];
    CGPoint itemImagePosition;
    itemImagePosition.x = ((contextRect.size.width - itemImageSize.width) / 2);
    itemImagePosition.y = ((contextRect.size.height - itemImageSize.height) );
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector((scale))])
        UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, [[UIScreen mainScreen] scale]);
    else
        UIGraphicsBeginImageContext(contextRect.size);
    
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
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
#pragma unused(event)
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation];
    [self refresh];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
#pragma unused(event)
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self handleTouchAtLocation:touchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
#pragma unused(event)
#pragma unused(touches)
    [delegate ratingView:self ratingDidChange:self.swrveCurrentRating];
}



@end
