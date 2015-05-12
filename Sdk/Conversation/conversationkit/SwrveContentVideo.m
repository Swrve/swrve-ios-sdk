
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveContentVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SwrveSetup.h"

#import "UIWebView+YouTubeVimeo.h"

@interface SwrveContentVideo () {
    NSString *_height;
    UIWebView *webview;
}

@end

@implementation SwrveContentVideo

@synthesize height=_height;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeVideo andDictionary:dict];
    _height = [dict objectForKey:@"height"];
    return self;
}

-(BOOL) willRequireLandscape {
    return YES;
}

-(void) stop {
    // Stop the running video - this will happen on a
    // page change.
    [webview loadHTMLString:@"" baseURL:nil];
}

-(void) loadView {
    // Create _view
    float vid_height = (_height) ? [_height floatValue] : 180.0;
    _view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [SwrveConversationAtom widthOfContentView], vid_height)];
    webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 300.0, vid_height)];
    [self sizeTheWebView];
    webview.backgroundColor = [UIColor clearColor];
    webview.opaque = NO;
    webview.delegate = self;
    webview.userInteractionEnabled = YES;
    // ??? testers
    // this is the default - webview.autoresizesSubviews = YES;
    [SwrveContentItem scrollView:webview].scrollEnabled = NO;
    [webview loadYouTubeOrVimeoVideo:self.value];
    [_view addSubview:webview];
    // Get notified if the view should change dimensions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:kSwrveNotifyOrientationChange object:nil];
}

-(UIView *)view {
    if(!_view) {
        [self loadView];
    }
    return _view;
}

-(void) webViewDidFinishLoad:(UIWebView *)webView {
#pragma unused (webView)
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

-(void) sizeTheWebView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Make the webview full width on iPad
        webview.frame = CGRectMake(0.0, 0.0, _view.frame.size.width, webview.frame.size.height/webview.frame.size.width*_view.frame.size.width);
    } else {
        // Cope with phone rotation
        // Too big or same size?
        if (webview.frame.size.width >= _view.frame.size.width) {
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
-(void) deviceOrientationDidChange {
    _view.frame = [self newFrameForOrientationChange];
    [self sizeTheWebView];
}

- (void)dealloc {
    if (webview.delegate == self) {
        webview.delegate = nil; // Unassign self from being the delegate, in case we get deallocated before the webview!
    }
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kSwrveNotifyOrientationChange object:nil];
}

@end
