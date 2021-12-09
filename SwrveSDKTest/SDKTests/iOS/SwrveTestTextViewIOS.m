#import <XCTest/XCTest.h>
#import "SwrveTextView.h"


@interface SwrveTestTextViewIOS : XCTestCase

@end

@implementation SwrveTestTextViewIOS

- (void)testSwrveTextViewDownScale{
    NSDictionary *style = @ {
        @"value": @"This text is large and not scrollable so should be resized down",
        @"h_align": @"LEFT",
        @"font_size": @100,
        @"scrollable": @0
    };
    
    SwrveTextViewStyle *tvStyle = [[SwrveTextViewStyle alloc]initWithDictionary:style];
    tvStyle.font = [UIFont systemFontOfSize:0];
    CGRect rect = CGRectMake(0, 0, 1000, 300);
    //ignore calibration
    SwrveTextView *tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:rect];
    XCTAssertEqual(tv.font.pointSize, 86.5);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));
    
    style = @ {
        @"value": @"This text fits and should stay at 10 points",
        @"h_align": @"LEFT",
        @"font_size": @10,
        @"scrollable": @0
    };

    tvStyle = [[SwrveTextViewStyle alloc]initWithDictionary:style];
    tvStyle.font = [UIFont systemFontOfSize:0];
    tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:CGRectMake(0, 0, 1000, 300)];
    XCTAssertEqual(tv.font.pointSize, 10);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));

    style = @ {
        @"value": @"This text is large but its scrollable so it should not be resized and stat at 100 points",
        @"h_align": @"LEFT",
        @"font_size": @100,
        @"scrollable": @1

    };

    tvStyle = [[SwrveTextViewStyle alloc]initWithDictionary:style];
    tvStyle.font = [UIFont systemFontOfSize:0];
    tv = [[SwrveTextView alloc] initWithStyle:tvStyle calbration:[SwrveCalibration new] frame:CGRectMake(0, 0, 1000, 300)];
    XCTAssertEqual(tv.font.pointSize, 100);
    XCTAssertTrue(CGRectEqualToRect(tv.frame, rect));
    XCTAssertTrue(tv.scrollEnabled);
}
@end
