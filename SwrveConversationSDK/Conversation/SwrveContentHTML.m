#import "SwrveContentHTML.h"
#import "SwrveConversationStyler.h"
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#else
#import "SwrveCommon.h"
#import "SwrveLocalStorage.h"
#endif

#if TARGET_OS_IOS /** exclude tvOS **/
NSString* const DEFAULT_CSS = @"html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, ruby, section, summary, time, mark, audio, video { margin: 0; padding: 0; border: 0; font-size: 100%; font: inherit; vertical-align: baseline; } b, i, u { margin: 0; padding: 0; border: 0; font-size: 100%; vertical-align: baseline; } /* HTML5 display-role reset for older browsers */ article, aside, details, figcaption, figure, footer, header, hgroup, menu, nav, section { display: block; } body { line-height: 1; } ol, ul { list-style: none; } blockquote, q { quotes: none; } blockquote:before, blockquote:after, q:before, q:after { content: ''; content: none; } table { border-collapse: collapse; border-spacing: 0; } /* Swrve defaults */ body { font-size: 16px; -webkit-text-size-adjust: 100%;  line-height: 26px; font-family: Helvetica, Arial; } p { letter-spacing: 0; font-size: 16px; line-height: 26px; margin: 0 20px; } h1 { font-size: 48px; line-height: 64px; margin: 0 20px; letter-spacing: 0; text-align: center; } h2 { font-size: 34px; line-height: 45px; margin: 0 20px; letter-spacing: 0; text-align: center; } h3 { font-size: 24px; line-height: 34px; letter-spacing: 0; margin: 0 20px; text-transform: none; text-align: center; } h4, h5, h6 { text-align: center; } strong { font-weight: bold;} em {font-style: italic;}";

@interface SwrveContentHTML () {
    WKWebView *webview;
    UIView *_containerView;
}
@end

@implementation SwrveContentHTML

-(void) loadViewWithContainerView:(UIView*)containerView {
    _containerView = containerView;
    // Create _view
    _view = webview = [WKWebView new];
    webview.frame = CGRectMake(0, 0, containerView.frame.size.width, 100);
    [SwrveConversationStyler styleView:webview withStyle:self.style];
    webview.opaque = NO;
    [webview setUIDelegate:self];
    [webview setNavigationDelegate:self];
    webview.userInteractionEnabled = YES;
    webview.scrollView.scrollEnabled = NO;

    NSString *html = [SwrveConversationStyler convertContentToHtml:self.value withPageCSS:DEFAULT_CSS withStyle:self.style];

    [webview loadHTMLString:html baseURL:nil];
}

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeHTML andDictionary:dict];
    if(self) {
        NSDictionary *immutableStyle = [dict objectForKey:kSwrveKeyStyle];
        NSMutableDictionary *style = [immutableStyle mutableCopy];
        // v1,v2,v3 won't have font details and a blank font file means using system font
        if (style && ![style objectForKey:kSwrveKeyFontFile]) {
            [style setObject:@"" forKey:kSwrveKeyFontFile];
        }
        if (style && ![style objectForKey:kSwrveKeyTextSize]) {
            [style setObject:@"" forKey:kSwrveKeyTextSize];
        }
        self.style = style;
    }
    return self;
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
#pragma unused (navigation, webView)
    [webview evaluateJavaScript:@"document.getElementById('swrve_content').clientHeight;" completionHandler:
     ^(id _Nullable response, NSError * _Nullable error) {
#pragma unused (error)
         // Measure and set width
         CGRect frame = self->_view.frame;
         frame.size.width = self->_containerView.frame.size.width;
         self->_view.frame = frame;
         // Measure and set height

         NSString *scrollHeight = (NSString *) response;
         frame.size.height = [scrollHeight floatValue];
         self->_view.frame = frame;

         // Notify that the view is ready to be displayed
         [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
     }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler NS_EXTENSION_UNAVAILABLE_IOS("") {
#pragma unused (webView)
    NSURLRequest *request = navigationAction.request;

    static NSString *regexp = @"^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9])[.])+([A-Za-z]|[A-Za-z][A-Za-z0-9-]*[A-Za-z0-9])$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexp];

    if ([predicate evaluateWithObject:request.URL.host]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:request.URL options:@{} completionHandler:^(BOOL success) {
                [SwrveLogger debug:@"Opening url [%@] successfully: %d", request.URL, success];
            }];
        } else {
            [SwrveLogger error:@"Could not load link, not supported (should not reach this code)", nil];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

// Respond to device orientation changes by resizing the width of the view
// Subviews of this should be flexible using AutoResizing masks
-(void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
    #pragma unused (orientation)
    _view.frame = [self newFrameForOrientationChange];
    _view = webview;
}

-(void)parentViewChangedSize:(CGSize)size {
    // Mantain full width
    _view.frame = CGRectMake(0, 0, size.width, _view.frame.size.height);
}

-(void) stop {
    [webview setUIDelegate:nil];
    [webview setNavigationDelegate:nil];
    if (webview.isLoading) {
        [webview stopLoading];
    }
}

-(void)viewDidDisappear {

    if (webview.isLoading) {
        [webview stopLoading];
    }
}
@end
#endif
