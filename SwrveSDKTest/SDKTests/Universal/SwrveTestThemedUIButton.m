#import <XCTest/XCTest.h>
#import <SwrveThemedUIButton.h>

@interface SwrveTestThemedUIButton : XCTestCase

@end

@implementation SwrveTestThemedUIButton

- (void)testCornerRadius {
    SwrveCalibration *nilCalibration = nil; // ignore and skip calibration for testing by using a nil SwrveCalibration

    NSString *text = @"text";
    CGRect frame = CGRectMake(0, 0, 100, 50); // frame is 100 width, 50 in height

    // no corner radius
    SwrveButtonTheme *theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                                       fontSize:[NSNumber numberWithInt:100]
                                                   cornerRadius:[NSNumber numberWithInt:0]
                                                       truncate:false];
    SwrveThemedUIButton *themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                                                text:text
                                                                               frame:frame
                                                                         calabration:nilCalibration
                                                                         renderScale:1.0];
    XCTAssertEqual(themedUIButton.layer.cornerRadius, 0);

    // 24 corner radius - just under half the height
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                     fontSize:[NSNumber numberWithInt:100]
                                 cornerRadius:[NSNumber numberWithInt:24]
                                     truncate:false];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:frame
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.layer.cornerRadius, 24);

    // 26 corner radius - just over half the height
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                     fontSize:[NSNumber numberWithInt:100]
                                 cornerRadius:[NSNumber numberWithInt:26]
                                     truncate:false];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:frame
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.layer.cornerRadius, 25);

    frame = CGRectMake(0, 0, 500, 1000); // frame is 500 width, 1000 in height

    // no corner radius
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                     fontSize:[NSNumber numberWithInt:100]
                                 cornerRadius:[NSNumber numberWithInt:0]
                                     truncate:false];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:frame
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.layer.cornerRadius, 0);

    // 249 corner radius - just under half the width
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                     fontSize:[NSNumber numberWithInt:100]
                                 cornerRadius:[NSNumber numberWithInt:249]
                                     truncate:false];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:frame
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.layer.cornerRadius, 249);

    // 251 corner radius - over half the width
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                     fontSize:[NSNumber numberWithInt:100]
                                 cornerRadius:[NSNumber numberWithInt:251]
                                     truncate:false];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:frame
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.layer.cornerRadius, 250);
}

- (void)testTextTruncation {
    SwrveCalibration *nilCalibration = nil; // ignore and skip calibration for testing by using a nil SwrveCalibration

    NSString *text = @"This text is large and not truncated so should be resized down";
    SwrveButtonTheme *theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                                       fontSize:[NSNumber numberWithInt:100]
                                                   cornerRadius:[NSNumber numberWithInt:0]
                                                       truncate:false];
    CGRect rect = CGRectMake(0, 0, 1000, 300);
    SwrveThemedUIButton *themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                                                text:text
                                                                               frame:rect
                                                                         calabration:nilCalibration
                                                                         renderScale:1.0];
    XCTAssertEqual(themedUIButton.titleLabel.font.pointSize, 38);

    text = @"This text is large and not truncated so should be resized down and padding taken into account";
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:20]
                                     fontSize:[NSNumber numberWithInt:100]
                                 cornerRadius:[NSNumber numberWithInt:0]
                                     truncate:false];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:rect
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.titleLabel.font.pointSize, 23);

    text = @"This text fits and should stay at 10 points";
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                     fontSize:[NSNumber numberWithInt:10]
                                 cornerRadius:[NSNumber numberWithInt:0]
                                     truncate:false];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:rect
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.titleLabel.font.pointSize, 10);

    text = @"This text is large but its truncated so it should not be resized and stay at 100 points";
    theme = [self dummyButtonThemeWithPadding:[NSNumber numberWithInt:0]
                                     fontSize:[NSNumber numberWithInt:100]
                                 cornerRadius:[NSNumber numberWithInt:0]
                                     truncate:true];
    themedUIButton = [[SwrveThemedUIButton alloc] initWithTheme:theme
                                                           text:text
                                                          frame:rect
                                                    calabration:nilCalibration
                                                    renderScale:1.0];
    XCTAssertEqual(themedUIButton.titleLabel.font.pointSize, 100);
}

- (SwrveButtonTheme *)dummyButtonThemeWithPadding:(NSNumber *)padding
                                         fontSize:(NSNumber *)fontSize
                                     cornerRadius:(NSNumber *)cornerRadius
                                         truncate:(BOOL)truncate {
    NSDictionary *buttonDictionary = @{
            @"font_size": fontSize,
            @"font_postscript_name": @"",
            @"font_family": @"",
            @"font_style": @"Regular",
            @"font_native_style": @"Normal",
            @"font_file": @"_system_font_",
            @"font_digest": @"",
            @"padding": @{
                    @"top": padding,
                    @"right": padding,
                    @"bottom": padding,
                    @"left": padding
            },
            @"font_color": @"#FF000000",
            @"bg_color": @"#FFFF0000",
            @"corner_radius": cornerRadius,
            @"truncate": truncate ? @YES : @NO,
            @"pressed_state": @{
                    @"font_color": @"#FFFF0000",
                    @"bg_color": @"#ffffd700"
            },
            @"h_align": @"CENTER"
    };
    return [[SwrveButtonTheme alloc] initWithDictionary:buttonDictionary];
}

@end
