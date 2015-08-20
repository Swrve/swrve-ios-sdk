#import "SwrveContentHTML.h"
#import "SwrveConversationStyler.h"

NSString* const DEFAULT_CSS = @"html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, ruby, section, summary, time, mark, audio, video { margin: 0; padding: 0; border: 0; font-size: 100%; font: inherit; vertical-align: baseline; } b, i, u { margin: 0; padding: 0; border: 0; font-size: 100%; vertical-align: baseline; } /* HTML5 display-role reset for older browsers */ article, aside, details, figcaption, figure, footer, header, hgroup, menu, nav, section { display: block; } body { line-height: 1; } ol, ul { list-style: none; } blockquote, q { quotes: none; } blockquote:before, blockquote:after, q:before, q:after { content: ''; content: none; } table { border-collapse: collapse; border-spacing: 0; } /* Swrve defaults */ body { font-size: 16px; line-height: 26px; font-family: Helvetica, Arial; } p { letter-spacing: 0; font-size: 16px; line-height: 26px; margin: 0 20px; } h1 { font-size: 48px; line-height: 64px; margin: 0 20px; letter-spacing: 0; text-align: center; } h2 { font-size: 34px; line-height: 45px; margin: 0 20px; letter-spacing: 0; text-align: center; } h3 { font-size: 24px; line-height: 34px; letter-spacing: 0; margin: 0 20px; text-transform: none; text-align: center; } h4, h5, h6 { text-align: center; }";

@interface SwrveContentHTML () {
    UIWebView *webview;
    UIView *_containerView;
}
@end

@implementation SwrveContentHTML

-(void) loadViewWithContainerView:(UIView*)containerView {
    _containerView = containerView;
    // Create _view
    _view = webview = [[UIWebView alloc] init];
    webview.frame = CGRectMake(0,0, 1, 1);
    [SwrveConversationStyler styleView:webview withStyle:self.style];
    webview.opaque = NO;
    webview.delegate = self;
    webview.userInteractionEnabled = YES;
    [SwrveContentItem scrollView:webview].scrollEnabled = NO;
    
    NSString *html = [SwrveConversationStyler convertContentToHtml:self.value withPageCSS:DEFAULT_CSS withStyle:self.style];
    [webview loadHTMLString:html baseURL:nil];
    
    // Get notified if the view should change dimensions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:kSwrveNotifyOrientationChange object:nil];
}

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeHTML andDictionary:dict];
    return self;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
#pragma unused (webView)
    // Set real width
    CGRect frame = _view.frame;
    frame.size.width = _containerView.frame.size.width;
    _view.frame = frame;
    // Measure height
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
    
    NSString *html = [SwrveConversationStyler convertContentToHtml:self.value withPageCSS:DEFAULT_CSS withStyle:self.style];
    [webview loadHTMLString:html baseURL:nil];
    
    _view = webview;
}

// iOS8+
-(void)viewWillTransitionToSize:(CGSize)size
{
    // Mantain full width
    _view.frame = CGRectMake(0, 0, size.width, _view.frame.size.height);
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kSwrveNotifyOrientationChange object:nil];
}

-(void) stop {
    [webview setDelegate:nil];
    if (webview.isLoading) {
        [webview stopLoading];
    }
}

-(void)viewDidDisappear
{
    if (webview.isLoading) {
        [webview stopLoading];
    }
}

@end
