
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveConversationResource.h"
#import "SwrveContentHTML.h"
#import "SwrveSetup.h"

@interface SwrveContentHTML () {
    UIWebView *webview;
}
@end

@implementation SwrveContentHTML

-(void) loadView {
    // Create _view
    webview = [[UIWebView alloc] init];
    webview.frame = CGRectMake(0,0,[SwrveConversationAtom widthOfContentView], 1);
    webview.backgroundColor = [UIColor clearColor];
    webview.opaque = NO;
    webview.delegate = self;
    webview.userInteractionEnabled = YES;
    [SwrveContentItem scrollView:webview].scrollEnabled = NO;
    NSString *fontFam = @"Helvetica";
    
    NSString *htmlPage = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">html h1 {font-family:\"%@\"; font-weight:bold; font-size:22px; color:#333333} \
                          body {font-family:\"%@\";background-color: transparent;} \
                          </style> \
                          </head> \
                          <body> \
                          %@ \
                          </body></html>", fontFam, fontFam, self.value];
    [webview loadHTMLString:htmlPage baseURL:nil];
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

#pragma UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
#pragma unused (webView)
    CGRect frame;
    NSString *output = [(UIWebView*)_view
                        stringByEvaluatingJavaScriptFromString:
                        @"document.height;"];
     frame = _view.frame;
    frame.size.height = [output floatValue];
    _view.frame = frame;
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
    // Reload the web page
    NSString *htmlPage = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">html h1 {font-family:\"Helvetica\"; font-weight:bold; font-size:22px; color:#333333} \
                          body {font-family:\"Helvetica\";background-color: transparent;} \
                          </style> \
                          </head> \
                          <body> \
                          %@ \
                          </body></html>", self.value];
    [webview loadHTMLString:htmlPage baseURL:nil];
    _view = webview;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kSwrveNotifyOrientationChange object:nil];
}

@end
