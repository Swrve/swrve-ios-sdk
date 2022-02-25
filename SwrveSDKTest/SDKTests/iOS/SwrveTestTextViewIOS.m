#import <XCTest/XCTest.h>
#import "SwrveTextView.h"
#import "SwrveConversationStyler.h"

@interface SwrveConversationStyler ()
+ (UIColor *)processHexColorValue:(NSString *)color;
@end

@interface SwrveTestTextViewIOS : XCTestCase

@end

@implementation SwrveTestTextViewIOS

- (void)testSwrveTextViewDownScale{
    NSDictionary *style = @ {
        @"value": @"This text is large and not scrollable so should be resized down",
        @"h_align": @"LEFT",
        @"font_size": @100,
        @"scrollable": @0,
        @"line_height": @0,
        @"padding": @{
                    @"top": @0,
                    @"right": @0,
                    @"bottom": @0,
                    @"left": @0
                }
    };
    
    SwrveTextViewStyle *tvStyle = [[SwrveTextViewStyle alloc] initWithDictionary:style
                                                                   defaultFont:[UIFont systemFontOfSize:0]
                                                        defaultForegroundColor:[UIColor blackColor]
                                                        defaultBackgroundColor:[UIColor clearColor]];
    CGRect rect = CGRectMake(0, 0, 1000, 300);
    //ignore calibration
    SwrveTextView *tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:rect];
    XCTAssertEqual(tv.font.pointSize, 86);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));
    
    style = @ {
        @"value": @"This text is large and not scrollable so should be resized down and line height taken into account",
        @"h_align": @"LEFT",
        @"font_size": @100,
        @"scrollable": @0,
        @"line_height": @2,
        @"padding": @{
                    @"top": @0,
                    @"right": @0,
                    @"bottom": @0,
                    @"left": @0
                }
    };
    
    tvStyle = [[SwrveTextViewStyle alloc] initWithDictionary:style
                                                                   defaultFont:[UIFont systemFontOfSize:0]
                                                        defaultForegroundColor:[UIColor blackColor]
                                                        defaultBackgroundColor:[UIColor clearColor]];
    rect = CGRectMake(0, 0, 1000, 300);
    //ignore calibration
    tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:rect];
    XCTAssertEqual(tv.font.pointSize, 58);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));
    
    
    style = @ {
        @"value": @"This text is large and not scrollable so should be resized down and padding taken into account",
        @"h_align": @"LEFT",
        @"font_size": @100,
        @"scrollable": @0,
        @"line_height": @1,
        @"padding": @{
                    @"top": @20,
                    @"right": @20,
                    @"bottom": @20,
                    @"left": @20
                }
    };
    
    tvStyle = [[SwrveTextViewStyle alloc] initWithDictionary:style
                                                                   defaultFont:[UIFont systemFontOfSize:0]
                                                        defaultForegroundColor:[UIColor blackColor]
                                                        defaultBackgroundColor:[UIColor clearColor]];
    rect = CGRectMake(0, 0, 1000, 300);
    //ignore calibration
    tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:rect];
    XCTAssertEqual(tv.font.pointSize, 72);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));
    
    style = @ {
        @"value": @"This text fits and should stay at 10 points",
        @"h_align": @"LEFT",
        @"font_size": @10,
        @"scrollable": @0
    };

    tvStyle = [[SwrveTextViewStyle alloc] initWithDictionary:style
                                                 defaultFont:[UIFont systemFontOfSize:0]
                                      defaultForegroundColor:[UIColor blackColor]
                                      defaultBackgroundColor:[UIColor clearColor]];
    
    tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:CGRectMake(0, 0, 1000, 300)];
    XCTAssertEqual(tv.font.pointSize, 10);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));

    style = @ {
        @"value": @"This text is large but its scrollable so it should not be resized and stat at 100 points",
        @"h_align": @"LEFT",
        @"font_size": @100,
        @"scrollable": @1

    };

    tvStyle = [[SwrveTextViewStyle alloc] initWithDictionary:style
                                                 defaultFont:[UIFont systemFontOfSize:0]
                                      defaultForegroundColor:[UIColor blackColor]
                                      defaultBackgroundColor:[UIColor clearColor]];
    
    tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:CGRectMake(0, 0, 1000, 300)];
    XCTAssertEqual(tv.font.pointSize, 100);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));
    XCTAssertTrue(tv.scrollEnabled);
}

- (void)testSwrveTextViewStyling {
    NSDictionary *style = @{
        @"value": @"This text is large and not scrollable so should be resized down",
        @"h_align": @"RIGHT",
        @"font_size": @10,
        @"scrollable": @0,
        @"font_postscript_name": @"Arial",
        @"font_native_style": @"",
        @"font_file": @"535.11f95d706be64c4654c18918065a40935531973b.ttf",
        @"font_digest": @"11f95d706be64c4654c18918065a40935531973b",
        @"line_height": @20,
        @"padding": @{
                @"top": @5,
                @"right": @6,
                @"bottom": @7,
                @"left": @8
        },
        @"font_color": @"#224466",
        @"bg_color": @"#00334455"
    };
    
    SwrveTextViewStyle *tvStyle = [[SwrveTextViewStyle alloc] initWithDictionary:style
                                                                   defaultFont:[UIFont systemFontOfSize:0]
                                                        defaultForegroundColor:[UIColor blackColor]
                                                        defaultBackgroundColor:[UIColor clearColor]];

    XCTAssertEqual(tvStyle.text, @"This text is large and not scrollable so should be resized down");
    XCTAssertEqual(tvStyle.textAlignment, NSTextAlignmentRight);
    XCTAssertEqual(tvStyle.fontsize, 10);
    XCTAssertFalse(tvStyle.scrollable);
    XCTAssertEqual(tvStyle.font_postscript_name, @"Arial");
    XCTAssertEqual(tvStyle.font_native_style, @"");
    XCTAssertEqual(tvStyle.font_file, @"535.11f95d706be64c4654c18918065a40935531973b.ttf");
    XCTAssertEqual(tvStyle.font_digest, @"11f95d706be64c4654c18918065a40935531973b");
    XCTAssertEqual(tvStyle.line_height, 20);
    XCTAssertEqual(tvStyle.topPadding, 5);
    XCTAssertEqual(tvStyle.rightPadding, 6);
    XCTAssertEqual(tvStyle.bottomPadding, 7);
    XCTAssertEqual(tvStyle.leftPadding, 8);
    XCTAssertEqualObjects(tvStyle.foregroundColor, [SwrveConversationStyler processHexColorValue:@"#224466"]);
    XCTAssertEqualObjects(tvStyle.backgroundColor, [SwrveConversationStyler processHexColorValue:@"#00334455"]);
    XCTAssertEqualObjects(tvStyle.font, [UIFont fontWithName:@"Arial" size:10]);
}

@end
