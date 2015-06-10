#import "SwrveContentHTML.h"
#import "SwrveConversationStyler.h"

@interface SwrveContentHTML () {
    UIWebView *webview;
}
@end

@implementation SwrveContentHTML

-(void) loadView {
    // Create _view
    webview = [[UIWebView alloc] init];
    webview.frame = CGRectMake(0,0,[SwrveConversationAtom widthOfContentView], 1);
    [SwrveConversationStyler styleView:webview withStyle:self.style];
    webview.opaque = NO;
    webview.delegate = self;
    webview.userInteractionEnabled = YES;
    [SwrveContentItem scrollView:webview].scrollEnabled = NO;

    NSString *html = [SwrveConversationStyler convertContentToHtml:self.value withStyle:self.style];
    [webview loadHTMLString:html baseURL:nil];

    _view = webview;
    // Get notified if the view should change dimensions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:kSwrveNotifyOrientationChange object:nil];
}

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeHTML andDictionary:dict];
    return self;
}

-(UIView *)view {
    if(!_view) {
        [self loadView];
    }
    return _view;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
#pragma unused (webView)
    CGRect frame;
    NSString *output = [(UIWebView*)_view
                        stringByEvaluatingJavaScriptFromString:
                        @"document.height;"];
    frame = _view.frame;
    frame.size.height = [output floatValue];
    _view.frame = frame;
    // Notify that the view is ready to be displayed
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
#pragma unused (navigationType, webView)
    static NSString *regexp = @"^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9])[.])+([A-Za-z]|[A-Za-z][A-Za-z0-9-]*[A-Za-z0-9])$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexp];
    
    if ([predicate evaluateWithObject:request.URL.host]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    } else {
        return YES;
    }
}

// Respond to device orientation changes by resizing the width of the view
// Subviews of this should be flexible using AutoResizing masks
-(void) deviceOrientationDidChange
{
    _view.frame = [self newFrameForOrientationChange];

    NSString *html = [SwrveConversationStyler convertContentToHtml:self.value withStyle:self.style];
    [webview loadHTMLString:html baseURL:nil];

    _view = webview;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kSwrveNotifyOrientationChange object:nil];
}

@end
