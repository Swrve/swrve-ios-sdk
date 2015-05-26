#import "UIWebView+YouTubeVimeo.h"
#import "SwrveSetup.h"

@implementation UIWebView (YouTubeVimeo)


-(NSString *)vimeoEmbed:(NSString *)url {
    return url;
}

-(void)loadYouTubeOrVimeoVideo:(NSString*)videoUrl {
    SwrveLogIt(@"UIWebView+YouTubeVimeo :: loadYouTubeOrVimeoVideo, videoUrl: %@", videoUrl);

    if ([videoUrl rangeOfString:@"vimeo"].length > 0) {
        [self loadVideo:videoUrl];
        return;
    }
    
    if ([videoUrl rangeOfString:@"youtube"].length > 0) {
        [self loadVideo:videoUrl];
        return;
    } else {
        // It's not video, nor is it youtube, so we are not sure what to do.
        // The backend video URL conditioning should mean that we don't get here.
    }
}

-(NSString *)youTubeEmbedHTMLFromVideoID:(NSString *)videoID {
    NSString *htmlString = @"<html><head> <meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = \"%f\"/></head> <body style=\"background:#000000;margin-top:0px;margin-left:0px\"> <iframe width= \"%f\" height=\"%f\" src = \"http://www.youtube.com/embed/%@?html5=1&controls=0&iv_load_policy=3&modestbranding=1&showinfo=0&rel=0\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    NSString *html = [NSString stringWithFormat:htmlString, self.frame.size.width, self.frame.size.width, self.frame.size.height, videoID];
    SwrveLogIt(@"UIWebView+YouTubeVimeo :: youTubeEmbedHTMLFromVideoID :: html:\n%@\n", html);
    return html;
}

-(NSString *)embedVideoInHTML:(NSString *)url {
    NSString *htmlString = @"<html><head> <meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = \"%f\"/></head> <body style=\"background:#000000;margin-top:0px;margin-left:0px\"> <iframe width= \"%f\" height=\"%f\" src = \"%@\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    NSString *html = [NSString stringWithFormat:htmlString, self.frame.size.width, self.frame.size.width, self.frame.size.height, url];
    SwrveLogIt(@"UIWebView+YouTubeVimeo :: embedVideoInHTML :: html:\n%@\n", html);
    return html;
}

-(void)loadVideo:(NSString*)url {
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = NO;

    // Pull the data from the video into a file locally
    NSString *fileName = [self generateFileNameWithExtension:@"html"];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], fileName];
    NSString *htmlToLoad = [self embedVideoInHTML:url];
    NSData *data = [htmlToLoad dataUsingEncoding:NSUTF8StringEncoding];
    
    [data writeToFile:filePath atomically:YES];

    // Now, load the video
    [self setMediaPlaybackRequiresUserAction:NO];
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]]];
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
