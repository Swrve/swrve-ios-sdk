#import "SwrveConversationStarRatingView.h"
#import "SwrveSetup.h"

@interface SwrveConversationStarRatingView ()

@property (strong, nonatomic) UIImage *swrveNotSelectedImage;
@property (strong, nonatomic) UIImage *swrveFullSelectedImage;
@property (assign, nonatomic) UIColor *swrveForegroundColor;
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
@synthesize swrveForegroundColor;
@synthesize swrveBackgroundColor;
@synthesize swrveCurrentRating;
@synthesize swrveMaxRating;
@synthesize swrveMidMargin;
@synthesize swrveLeftMargin;
@synthesize swrveMinImageSize;
@synthesize delegate;


- (id) initWithFrame:(CGRect)frame {
    self =[super initWithFrame:frame];
    
    if(self){
        self.swrveStarViews = [[NSMutableArray alloc] init];
        self.swrveNotSelectedImage = [UIImage imageNamed:@"star-empty"];
        self.swrveFullSelectedImage = [UIImage imageNamed:@"star-full"];
        self.swrveCurrentRating = 0;
        self.swrveMaxRating = 5.0f;
        self.swrveMidMargin = 5.0f;
        self.swrveLeftMargin = 0.0f;
        self.swrveMinImageSize = CGSizeMake(5, 5);
        self.delegate = nil;
        
    }
    
    return self;
}


- (void) initRatingTypewithStarColor:(UIColor *) starColor WithForegroundColor:(UIColor *)foregroundColor withBackgroundColor:(UIColor *)backgroundColor
          {
              self.swrveStarColor = starColor;
              self.swrveForegroundColor = foregroundColor;
              self.swrveBackgroundColor = backgroundColor;
              self.swrveStarViews = [[NSMutableArray alloc] init];
              self.swrveNotSelectedImage = [UIImage imageNamed:@"star-empty"];
              self.swrveFullSelectedImage = [UIImage imageNamed:@"star-full"];
              self.swrveCurrentRating = 0;
              self.swrveMaxRating = 5.0f;
              self.swrveMidMargin = 5.0f;
              self.swrveLeftMargin = 0.0f;
              self.swrveMinImageSize = CGSizeMake(5, 5);
              self.delegate = nil;
    
}

- (void) refresh {
    for(NSUInteger i = 0; i < self.swrveStarViews.count; ++i) {
        UIImageView *imageView = [self.swrveStarViews objectAtIndex:i];
        if (self.swrveCurrentRating >= i+1) {
            imageView.image = self.swrveFullSelectedImage;
            imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [imageView setTintColor:self.swrveStarColor];
        } else {
            imageView.image = self.swrveNotSelectedImage;
            imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [imageView setTintColor:self.swrveStarColor];
        }
    }
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    if (self.swrveNotSelectedImage == nil) return;

    float desiredImageWidth = (self.frame.size.width - (self.swrveLeftMargin * 2) - (self.swrveMidMargin * self.swrveStarViews.count)) / self.swrveStarViews.count;

    float imageWidth = SWRVEMAX(self.swrveMinImageSize.width, desiredImageWidth);
    float imageHeight = SWRVEMAX(self.swrveMinImageSize.height, self.frame.size.height);
    
    for (NSUInteger i = 0; i < self.swrveStarViews.count; ++i) {
        
        UIImageView *imageView = [self.swrveStarViews objectAtIndex:i];
        CGRect imageFrame = CGRectMake((self.swrveLeftMargin + i) * (self.swrveMidMargin+imageWidth), 0, imageWidth, imageHeight);
        imageView.frame = imageFrame;
    }
}

#pragma mark getters / setters

- (void) setSwrveMaxRating:(float)maxRating{
    self.swrveMaxRating = maxRating;
    
    // Remove old image views
    for(NSUInteger i = 0; i < self.swrveStarViews.count; ++i) {
        UIImageView *imageView = (UIImageView *) [self.swrveStarViews objectAtIndex:i];
        [imageView removeFromSuperview];
    }
    [self.swrveStarViews removeAllObjects];
    
    // Add new image views
    for(int i = 0; i < self.swrveMaxRating; ++i) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.swrveStarViews addObject:imageView];
        [self addSubview:imageView];
    }
    
    // Relayout and refresh
    [self setNeedsLayout];
    [self refresh];
}

- (void)setSwrveStarColor:(UIColor *)color {
    self.swrveStarColor = color;
    [self setNeedsDisplay];
    [self refresh];
}

- (void)setSwrveNotSelectedImage:(UIImage *)image {
    self.swrveNotSelectedImage = image;
    [self refresh];
}

- (void)setSwrveFullSelectedImage:(UIImage *)image {
    self.swrveFullSelectedImage = image;
    [self refresh];
}

- (void)setSwrveCurrentRating:(float)rating {
    self.swrveCurrentRating = rating;
    [self refresh];
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
