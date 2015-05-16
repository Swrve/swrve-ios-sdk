#import "UIWebView+YouTubeVimeo.h"
#import "SwrveSetup.h"

@implementation UIWebView (YouTubeVimeo)

#pragma mark Public Methods
-(void) loadVideo:(NSString *)videoUrl {
    SwrveLogIt(@"UIWebView+YouTubeVimeo :: loadYouTubeOrVimeoVideo, videoUrl: %@", videoUrl);
    
    if ([videoUrl rangeOfString:@"vimeo"].length > 0) {
        [self loadVimeoVideo:videoUrl];
    } else {
        if ([videoUrl rangeOfString:@"youtube"].length > 0) {
            [self loadYouTubeVideo:videoUrl];
        }
    }
}

#pragma mark Video Provider Methods

-(void) loadVimeoVideo:(NSString*)videoUrl {
    [self loadVideo:videoUrl];
    [self setMediaPlaybackRequiresUserAction:NO];
    [self loadHTMLString:[self htmlForVideoUrl:videoUrl] baseURL:[NSURL URLWithString:@"/"]];
}

-(void) loadYouTubeVideo:(NSString*)videoUrl {
    // YouTube URLs do need processing a little before display

    NSRegularExpression *regexEmbed = [NSRegularExpression regularExpressionWithPattern:@"embed/([^/]+)"
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:nil];
    NSTextCheckingResult *matchEmbed = [regexEmbed firstMatchInString:videoUrl options:0 range:NSMakeRange(0, [videoUrl length])];
    
    // Check to see if it has the word "embed" in it
    if (matchEmbed) {
        [self loadVideo:videoUrl];
    } else {
        // Ok so the backend will always condition the URL to have an
        // embed in it, so this code really doesn't get executed - or shouldn't!
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"?.*v=([^&]+)"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:videoUrl
                                                        options:0
                                                          range:NSMakeRange(0, [videoUrl length])];
        if (match) {
            NSRange videoIDRange = [match rangeAtIndex:1];
            NSString *videoID = [videoUrl substringWithRange:videoIDRange];

            [self setMediaPlaybackRequiresUserAction:NO];
            self.scrollView.bounces = NO;
            self.scrollView.scrollEnabled = NO;
            
            [self loadHTMLString:[self htmlForYouTubeEmbed:videoID] baseURL:[NSURL URLWithString:@"/"]];
        } else {
            // TODO: log an issue
        }
    }
}

#pragma mark URL Processing

-(NSString *) htmlForYouTubeEmbed:(NSString *)videoID {
    NSString *htmlString = @"<html><head> <meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = \"%f\"/></head> <body style=\"background:#000000;margin-top:0px;margin-left:0px\"> <iframe width= \"%f\" height=\"%f\" src = \"http://www.youtube.com/embed/%@?html5=1&controls=0&iv_load_policy=3&modestbranding=1&showinfo=0&rel=0\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    return [NSString stringWithFormat:htmlString, self.frame.size.width, self.frame.size.width, self.frame.size.height, videoID];
}

-(NSString *) htmlForVideoUrl:(NSString *)url {
    NSString *htmlString = @"<html><head> <meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = \"%f\"/></head> <body style=\"background:#000000;margin-top:0px;margin-left:0px\"> <iframe width= \"%f\" height=\"%f\" src = \"%@\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    return [NSString stringWithFormat:htmlString, self.frame.size.width, self.frame.size.width, self.frame.size.height, url];
}

@end
