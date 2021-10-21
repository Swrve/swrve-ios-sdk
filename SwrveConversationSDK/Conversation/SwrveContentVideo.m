#import "SwrveContentVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif
#if TARGET_OS_IOS /** exclude tvOS **/

@interface SwrveContentVideo () {
    float _height;
    WKWebView *webview;
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
    id rawHeight = [dict objectForKey:@"height"];
    if (rawHeight) {
        _height = [rawHeight floatValue];
    } else {
        _height = 180.0;
    }

    // video loading fullscreen from webview iframe creates a new uiwindow, we need to set its windowlevel
    // to the same as the main conversation uiwindow level to ensure it appears above it.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidBecomeActive:)
                                                 name:UIWindowDidBecomeVisibleNotification
                                               object:nil];

    return self;
}

- (void)windowDidBecomeActive:(NSNotification *)notification {
    // we can assume within the context of this conversation uiwindow that the uiwindow becoming active is from the video tap in the webview
    if (isNewUIWindowFromWebViewClick) {
        UIWindow *window = notification.object;
        window.windowLevel = UIWindowLevelAlert + 1;
    }
}

- (void)stop {
    isNewUIWindowFromWebViewClick = NO;
    [webview setNavigationDelegate:nil];
    [webview setUIDelegate:nil];
    // Stop the running video - this will happen on a page change.
    [webview loadHTMLString:@"about:blank" baseURL:nil];
}

-(void)viewDidDisappear
{
    if (webview.isLoading) {
        [webview stopLoading];
    }
}

- (void)loadViewWithContainerView:(UIView *)containerView {
    _containerView = containerView;

    // Enable audio
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];

    // Create _view
    WKWebViewConfiguration *wkConfig = [WKWebViewConfiguration new];
    [wkConfig setAllowsInlineMediaPlayback:YES];

    _view = webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 1, _height) configuration:wkConfig];

    [self sizeTheWebView];
    webview.backgroundColor = [UIColor clearColor];
    webview.opaque = NO;
    webview.UIDelegate = self;
    webview.navigationDelegate = self;
    webview.userInteractionEnabled = YES;
    webview.scrollView.scrollEnabled = NO;

    NSString *rawValue = [self.value stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];

    preventNavigation = NO;
    [self loadYouTubeVideo:rawValue];

    UITapGestureRecognizer *gesRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]; // Declare the Gesture.
    gesRecognizer.delegate = self;
    [gesRecognizer setNumberOfTapsRequired:1];
    [webview addGestureRecognizer:gesRecognizer];
    // Notify that the view is ready to be displayed
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
#pragma unused(webView, navigation)
    preventNavigation = YES;
    CGRect frame = webview.frame;
    frame.size.width = _containerView.frame.size.width;
    webview.frame = frame;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
#pragma unused(webView, navigation, error)
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

- (void)sizeTheWebView {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
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
- (void)respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
#pragma unused (orientation)
    _view.frame = [self newFrameForOrientationChange];
    [self sizeTheWebView];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler NS_EXTENSION_UNAVAILABLE_IOS("") {
#pragma unused (webView)
    NSURLRequest *nsurl = navigationAction.request;

    // Check if the navigation is coming from a user clicking on a link
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:[nsurl URL] options:@{} completionHandler:^(BOOL success) {
                [SwrveLogger debug:@"Opening url [%@] successfully: %d", nsurl, success];
            }];
        } else {
            [SwrveLogger error:@"Could not open url, not supported (should not reach this code)", nil];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    // Check if the youtube link that is opening is the logo that redirects to the full website
    if (nsurl != nil) {
        NSString *url = [[nsurl URL] absoluteString];
        if (@available(iOS 8.0, *)) {
            if ([url containsString:@"youtube.com/"] && ![url containsString:@"youtube.com/embed/"]) {
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:[nsurl URL] options:@{} completionHandler:^(BOOL success) {
                        [SwrveLogger debug:@"Opening url [%@] successfully: %d", nsurl, success];
                    }];
                } else {
                    [SwrveLogger error:@"Could not open url, not supported (should not reach this code)", nil];
                }
                decisionHandler(WKNavigationActionPolicyCancel);
                return;

            }
        }
    }

    if (!preventNavigation) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)parentViewChangedSize:(CGSize)size {
    // Mantain full width
    _view.frame = CGRectMake(0, 0, size.width, _view.frame.size.height);
}

#pragma mark - video url processing and rendering

- (NSString *)vimeoEmbed:(NSString *)url {
    return url;
}

-(void)loadYouTubeVideo:(NSString*)videoUrl {
    if ([videoUrl rangeOfString:@"vimeo"].length > 0) {
        [self loadVideo:videoUrl];
    } else if ([videoUrl rangeOfString:@"youtube"].length > 0) {
        [self loadVideo:videoUrl];
    } else {
        // It's not video, nor is it youtube, so we are not sure what to do.
        // The backend video URL conditioning should mean that we don't get here.
    }
}

- (void)loadVideo:(NSString*)url {
    webview.scrollView.bounces = NO;
    webview.scrollView.scrollEnabled = NO;
    NSString *html = [self embedVideoInHTML:url];
    [webview loadHTMLString:html baseURL:nil];
}

- (NSString *)embedVideoInHTML:(NSString *)url {
    NSString *htmlString = @"<html style=\"margin:0;\"><head><meta name=\"viewport\" content=\"initial-scale = 1.0, user-scalable = no\"/></head><body style=\"background:#000000;margin:0;\"><iframe width=\"100%%\" height=\"100%%\" src=\"%@\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    return [NSString stringWithFormat:htmlString, url];
}

#pragma mark - teardown

- (void)dealloc {
    if (webview.UIDelegate == self) {
        [webview setUIDelegate: nil]; // Unassign self from being the delegate, in case we get deallocated before the webview!
    }

    if (webview.navigationDelegate == self) {
        [webview setNavigationDelegate: nil];
    }
}

@end
#endif
