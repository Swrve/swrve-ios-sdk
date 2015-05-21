#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveConversationAtom.h"

@implementation SwrveConversationAtom

@synthesize tag=_tag;
@synthesize type=_type;
@synthesize view=_view;
@synthesize style;

#define kCellTag 101

-(id) initWithTag:(NSString *)tag andType:(NSString *)type {
    SwrveLogIt(@"initWithTag andType: %@ %@", tag, type);
    self = [super init];
    if(self) {
        _tag = tag;
        _type = type;
    }
    return self;
}

-(BOOL) willRequireLandscape {
    return YES;
}

-(void) stop {
    // By default, does nothing. Specialize in subclass
}

-(void) loadView {
    NSException *exec = [[NSException alloc] initWithName:@"NotImplemented" reason:@"Not Implemented" userInfo:nil];
    [exec raise];
}

-(NSUInteger) numberOfRowsNeeded {
    return 1;
}

-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
#pragma unused (row)
    NSString *cellId = [NSString stringWithFormat:@"%@CellId", self.type];
    SwrveLogIt(@"cellForRow :: cellId: %@", cellId);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    /* First, check if there's a previous one there, we may need to reset the content */
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *v = [cell.contentView viewWithTag:kCellTag];
        if(v) {
            [v removeFromSuperview];
        }
    });
    CGRect r = _view.frame;
    SwrveLogIt(@"cellForRow :: r frame in Atom: %f, %f, %f, %f", r.origin.x, r.origin.y, r.size.width, r.size.height);
    // If the content supplied is not as wide as the container cell, pad it to center
    CGFloat containerWidth = [SwrveConversationAtom widthOfContentView];
    CGFloat cellItemWidth  = r.size.width;
    CGFloat leftPadding    = 0.0;
    if (cellItemWidth < containerWidth) {
        // Possibly move this padding in to the item itself
//        SwrveLogIt(@"cellForRow :: Content needs padded");
//        leftPadding = roundf((containerWidth - cellItemWidth) / 2);
    }
    // If it is too wide, adjust
    if (cellItemWidth > containerWidth) {
        leftPadding = 0.0;
        cellItemWidth = containerWidth;
    }
    _view.frame = CGRectMake(leftPadding, [self verticalPadding], cellItemWidth, r.size.height);
    _view.tag = kCellTag;
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell.contentView addSubview:self->_view];
        cell.contentView.backgroundColor = [UIColor clearColor];
    });

    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

-(CGFloat) verticalPadding {
    // TODO: the vertical padding should be adjustable
    return 10.0;
}

-(CGFloat) heightForRow:(NSUInteger) row {
#pragma unused (row)
    return _view.frame.size.height + [self verticalPadding];
}

+(CGSize) screenSize {
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    NSString *device = [[UIDevice currentDevice] model];
    
    if ([device rangeOfString:@"imulator"].location != NSNotFound) {
        // In the days of resizable simulators, you need to get
        // the size of the key window rather than the actual
        // simulator size.
        screenSize = [[UIApplication sharedApplication] keyWindow].frame.size;
    }
    
    return screenSize;
}

// Return the new frame that this view needs to sit correctly
// on the screen after an orientation change
-(CGRect) newFrameForOrientationChange {
    SwrveLogIt(@"deviceOrientationDidChange :: _view frame at start: %f, %f, %f, %f", _view.frame.origin.x, _view.frame.origin.y, _view.frame.size.width, _view.frame.size.height);
    
    CGRect newFrame;
    
    // If you are running iOS8, there seems to be some odd things
    // where the orientation doesn't seem to change in time, and
    // you are better off using the frame of the superview, which
    // appears to have reacted to it correctly.
    //
    // Not sure, but empirical evidence shows this approach gives
    // the correct results.
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        newFrame = CGRectMake(_view.frame.origin.x, _view.frame.origin.y, [SwrveConversationAtom widthOfContentView], _view.frame.size.height);
    } else {
        newFrame = CGRectMake(_view.frame.origin.x, _view.frame.origin.y, _view.superview.frame.size.width, _view.frame.size.height);
    }
    SwrveLogIt(@"deviceOrientationDidChange :: _view frame at end: %f, %f, %f, %f", newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
    
    return newFrame;
}

// Rules for the width of the content view:
//   iPhone, iOS 7+ : width of screen in points
//   iPhone, iOS 6- : 10pt border => width of screen - 20pt
//
//   iPad, iOS 7+ : 540pt
//   iPad, iOS 6- : 520pt
//
+(CGFloat) widthOfContentView {
    CGFloat containerWidth = 540.0;  // default: width of view on iPad iOS 7+
    CGFloat bordersSize = 0.0;
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        bordersSize = 20.0;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // iOS 8 makes width/height orientation dependent at
        // last :)
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
            
            switch (o) {
                case UIDeviceOrientationPortrait:
                case UIDeviceOrientationPortraitUpsideDown:
                case UIDeviceOrientationUnknown:
                case UIDeviceOrientationFaceUp:
                case UIDeviceOrientationFaceDown:
                    containerWidth = [SwrveConversationAtom screenSize].width;
                    break;
                case UIDeviceOrientationLandscapeLeft:
                case UIDeviceOrientationLandscapeRight:
                    containerWidth = [SwrveConversationAtom screenSize].height;
                    break;
            }
        } else {
            containerWidth = [SwrveConversationAtom screenSize].width;
        }
    }
    
    containerWidth -= bordersSize;  // Apply border math for iOS 6-
    
    SwrveLogIt(@"widthOfContentView :: returning containerWidth: %f", containerWidth);
    return containerWidth;
}
@end
