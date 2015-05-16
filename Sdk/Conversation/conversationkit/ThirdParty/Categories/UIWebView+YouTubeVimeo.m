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
            [self loadYouTubeVideoID:videoID];
        } else {
            // TODO: log an issue
        }
    }
}

-(void) loadVideoFromUrl:(NSURL*)url {
    [self setMediaPlaybackRequiresUserAction:NO];
    [self loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void) loadVideoFromFile:(NSString*)url {
    // TODO: SwrveLogIt(@"UIWebView+YouTubeVimeo :: loadVideo");
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = NO;
    
    // Pull the data from the video into a file locally
    //
    NSString *fileName = [self generateFileNameWithExtension:@"html"];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], fileName];
    NSString *htmlToLoad = [self htmlForVideoUrl:url];
    NSData *data = [htmlToLoad dataUsingEncoding:NSUTF8StringEncoding];
    
    [data writeToFile:filePath atomically:YES];
    [self loadVideoFromUrl:[NSURL fileURLWithPath:filePath]];
}

-(void)loadYouTubeVideoID:(NSString*)videoID {
    // TODO: SwrveLogIt(@"UIWebView+YouTubeVimeo :: loadYouTubeVideoID");
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = NO;
    
    NSString *fileName = [NSString stringWithFormat:@"youtubevideo%@.html",videoID];
    
    // File is stored in the NSCachesDirectory, where it will be deleted on
    // app uninstall, app update, or if memory conditions are low
    //
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], fileName];
    NSData *data = [[self htmlForYouTubeEmbed:videoID] dataUsingEncoding:NSUTF8StringEncoding];
    
    //write data to file
    [data writeToFile:filePath atomically:YES];
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: filePath]]];
}

#pragma mark URL Processing

-(NSString *) htmlForYouTubeEmbed:(NSString *)videoID {
    NSString *htmlString = @"<html><head> <meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = \"%f\"/></head> <body style=\"background:#000000;margin-top:0px;margin-left:0px\"> <iframe width= \"%f\" height=\"%f\" src = \"http://www.youtube.com/embed/%@?html5=1&controls=0&iv_load_policy=3&modestbranding=1&showinfo=0&rel=0\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    NSString *html = [NSString stringWithFormat:htmlString, self.frame.size.width, self.frame.size.width, self.frame.size.height, videoID];
    SwrveLogIt(@"UIWebView+YouTubeVimeo :: youTubeEmbedHTMLFromVideoID :: html:\n%@\n", html);
    return html;
}

-(NSString *) htmlForVideoUrl:(NSString *)url {
    NSString *htmlString = @"<html><head> <meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = \"%f\"/></head> <body style=\"background:#000000;margin-top:0px;margin-left:0px\"> <iframe width= \"%f\" height=\"%f\" src = \"%@\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    NSString *html = [NSString stringWithFormat:htmlString, self.frame.size.width, self.frame.size.width, self.frame.size.height, url];
    SwrveLogIt(@"UIWebView+YouTubeVimeo :: embedVideoInHTML :: html:\n%@\n", html);
    return html;
}

#pragma mark Helper methods

-(NSString*)generateFileNameWithExtension:(NSString *)extensionString {
    NSString *timeString = [self uniqueFileName];
    NSString *fileName = [NSString stringWithFormat:@"video-%@.%@", timeString, extensionString];
    return fileName;
}

// Using a timestamp strategy here because NSUUID not available
// pre iOS6. We to use 'A' for milliseconds in the format.
// See #56
-(NSString*)uniqueFileName {
    NSDate *time = [NSDate date];
    NSDateFormatter* df = [NSDateFormatter new];
    [df setDateFormat:@"dd-MM-yyyy-hh-mm-ss-A"];
    return [df stringFromDate:time];
}

@end
