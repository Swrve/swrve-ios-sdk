#import "UIWebView+YouTubeVimeo.h"
#import "SwrveSetup.h"

@implementation UIWebView (YouTubeVimeo)


-(NSString *)vimeoEmbed:(NSString *)url {
    return url;
}

-(void)loadYouTubeOrVimeoVideo:(NSString*)videoUrl {
    if ([videoUrl rangeOfString:@"vimeo"].length > 0) {
        [self loadVideo:videoUrl forceInline:NO];
    } else if ([videoUrl rangeOfString:@"youtube"].length > 0) {
        BOOL forceInline = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && SYSTEM_VERSION_LESS_THAN(@"8.0");
        [self loadVideo:videoUrl forceInline:forceInline];
    } else {
        // It's not video, nor is it youtube, so we are not sure what to do.
        // The backend video URL conditioning should mean that we don't get here.
    }
}

-(void)loadVideo:(NSString*)url forceInline:(BOOL)forceInline {
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = NO;
    [self setMediaPlaybackRequiresUserAction:NO];
    [self loadHTMLString:[self embedVideoInHTML:url forceInline:forceInline] baseURL:[NSURL URLWithString:@"/"]];
}

-(NSString *)embedVideoInHTML:(NSString *)url forceInline:(BOOL)forceInline {
    NSString *htmlString = nil;
    if (forceInline) {
        htmlString = @"<html style=\"margin:0;\"><head><meta name=\"viewport\" content=\"initial-scale = 1.0, user-scalable = no\"/></head><body style=\"background:#000000;margin:0;\"><iframe width=\"100%%\" height=\"100%%\" src=\"%@&playsinline=1&controls=0\" frameborder=\"0\" webkit-playsinline></iframe></body></html>";
    } else {
        htmlString = @"<html style=\"margin:0;\"><head><meta name=\"viewport\" content=\"initial-scale = 1.0, user-scalable = no\"/></head><body style=\"background:#000000;margin:0;\"><iframe width=\"100%%\" height=\"100%%\" src=\"%@\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    }
    return [NSString stringWithFormat:htmlString, url];
}

@end
