#import "SwrveContentVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "UIWebView+YouTubeVimeo.h"
#import "SwrveCommon.h"
#if TARGET_OS_IOS /** exclude tvOS **/

@interface SwrveContentVideo () {
    NSString *_height;
    UIWebView *webview;
    UIView *_containerView;
    BOOL preventNavigation;
    BOOL isNewUIWindowFromWebViewClick;
}

@end

@implementation SwrveContentVideo

@synthesize height = _height;
@synthesize interactedWith = _interactedWith;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeVideo andDictionary:dict];
    _height = [dict objectForKey:@"height"];
    
    // video loading fullscreen from uiwebview iframe creates a new uiwindow, we need to set its windowlevel
    // to the same as the main conversation uiwindow level to ensure it appears above it.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidBecomeActive:)
                                                 name:UIWindowDidBecomeVisibleNotification
                                               object:nil];
    
    return self;
}

- (void)windowDidBecomeActive:(NSNotification *)notification {
    // we can assume within the context of this conversation uiwindow that the uiwindow becoming active is from the video tap in the uiwebview
    if (isNewUIWindowFromWebViewClick) {
        UIWindow *window = notification.object;
        window.windowLevel = UIWindowLevelAlert + 1;
    }
}

-(void) stop {
    isNewUIWindowFromWebViewClick = NO;
    [webview setDelegate:nil];
    // Stop the running video - this will happen on a page change.
    [webview loadHTMLString:@"about:blank" baseURL:nil];
}

-(void)viewDidDisappear
{
    if (webview.isLoading) {
        [webview stopLoading];
    }
}

-(void) loadViewWithContainerView:(UIView*)containerView {
    _containerView = containerView;
    
    // Enable audio
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    // Create _view
    CGFloat vid_height = (_height) ? [_height floatValue] : 180.0;
    _view = webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 1, vid_height)];
    [self sizeTheWebView];
    webview.backgroundColor = [UIColor clearColor];
    webview.opaque = NO;
    webview.delegate = self;
    webview.userInteractionEnabled = YES;
    webview.scrollView.scrollEnabled = NO;
    
    NSString *rawValue = [self.value stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];

    preventNavigation = NO;
    [webview loadYouTubeOrVimeoVideo:rawValue];
    
    UITapGestureRecognizer *gesRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]; // Declare the Gesture.
    gesRecognizer.delegate = self;
    [gesRecognizer setNumberOfTapsRequired:1];
    [webview addGestureRecognizer:gesRecognizer];
    // Notify that the view is ready to be displayed
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
#pragma unused(gestureRecognizer, otherGestureRecognizer)
    return YES;
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
#pragma unused(gestureRecognizer)
    _interactedWith = YES;
    isNewUIWindowFromWebViewClick = YES;
}

- (void) sizeTheWebView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Make the webview full width on iPad
        webview.frame = CGRectMake(0.0, 0.0, _view.frame.size.width, webview.frame.size.height/webview.frame.size.width*_view.frame.size.width);
    } else {
        // Cope with phone rotation
        // Too big or same size?
        if (webview.frame.size.width > 0 && webview.frame.size.width >= _view.frame.size.width) {
            webview.frame = CGRectMake(0.0, 0.0, _view.frame.size.width, webview.frame.size.height/webview.frame.size.width*_view.frame.size.width);
        }
        // Too small?
        if(webview.frame.size.width < _view.frame.size.width) {
            webview.frame = CGRectMake((_view.frame.size.width-webview.frame.size.width)/2, webview.frame.origin.y, webview.frame.size.width, webview.frame.size.height);
        }
    }
    // Adjust the containing view around this too
    _view.frame = CGRectMake(_view.frame.origin.x, _view.frame.origin.y, _view.frame.size.width, webview.frame.size.height);
}

// Respond to device orientation changes by resizing the width of the view
// Subviews of this should be flexible using AutoResizing masks
-(void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
#pragma unused (orientation)
    _view.frame = [self newFrameForOrientationChange];
    [self sizeTheWebView];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
#pragma unused(webView, request, navigationType)
    NSURL* nsurl = [request URL];
    
    // Check if the navigation is coming from a user clicking on a link
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:^(BOOL success) {
                DebugLog(@"Opening url [%@] successfully: %d", nsurl, success);
            }];
        } else {
            DebugLog(@"Could not open url, not supported (should not reach this code)");
        }
        return NO;
    }
    
    // Check if the youtube link that is opening is the logo that redirects to the full website
    if (nsurl != nil) {
        NSString* url = nsurl.absoluteString;
        if (@available(iOS 8.0, *)) {
            if ([url containsString:@"youtube.com/"] && ![url containsString:@"youtube.com/embed/"]) {
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:^(BOOL success) {
                        DebugLog(@"Opening url [%@] successfully: %d", nsurl, success);
                    }];
                } else {
                    DebugLog(@"Could not open url, not supported (should not reach this code)");
                }
                return NO;
            }
        } 
    }
    
    return !preventNavigation;
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
#pragma unused(webView)
    preventNavigation = YES;
    CGRect frame = webview.frame;
    frame.size.width = _containerView.frame.size.width;
    webview.frame = frame;
}

-(void)parentViewChangedSize:(CGSize)size {
    // Mantain full width
    _view.frame = CGRectMake(0, 0, size.width, _view.frame.size.height);
}

- (void)dealloc {
    if (webview.delegate == self) {
        webview.delegate = nil; // Unassign self from being the delegate, in case we get deallocated before the webview!
    }
}

@end
#endif
