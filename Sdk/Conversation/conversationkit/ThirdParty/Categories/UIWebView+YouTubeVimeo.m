#import "UIWebView+YouTubeVimeo.h"
#import "SwrveSetup.h"

@implementation UIWebView (YouTubeVimeo)


-(NSString *)vimeoEmbed:(NSString *)url {
    return url;
}

-(void)loadYouTubeOrVimeoVideo:(NSString*)videoUrl {
    if ([videoUrl rangeOfString:@"vimeo"].length > 0) {
        [self loadVideo:videoUrl];
    } else if ([videoUrl rangeOfString:@"youtube"].length > 0) {
        [self loadVideo:videoUrl];
    } else {
        // It's not video, nor is it youtube, so we are not sure what to do.
        // The backend video URL conditioning should mean that we don't get here.
    }
}

-(void)loadVideo:(NSString*)url {
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = NO;
    [self setMediaPlaybackRequiresUserAction:NO];
    [self loadHTMLString:[self embedVideoInHTML:url] baseURL:[NSURL URLWithString:@"/"]];
}

-(NSString *)embedVideoInHTML:(NSString *)url {
    NSString *htmlString = @"<html><head> <meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = \"%f\"/></head> <body style=\"background:#000000;margin-top:0px;margin-left:0px\"> <iframe width= \"%f\" height=\"%f\" src = \"%@\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    NSString *html = [NSString stringWithFormat:htmlString, self.frame.size.width, self.frame.size.width, self.frame.size.height, url];
    return html;
}

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
