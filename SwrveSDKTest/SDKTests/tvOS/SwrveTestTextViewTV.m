#import <XCTest/XCTest.h>
#import "SwrveTextView.h"

@interface SwrveTestTextViewTV : XCTestCase

@end

@implementation SwrveTestTextViewTV

- (void)testSwrveTextViewDownScale{
    NSDictionary *style = @ {
        @"value": @"This text is large and not scrollable so should be resized down",
        @"h_align": @"LEFT",
        @"font_size": @100,
        @"scrollable": @1
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
    XCTAssertFalse(tv.scrollEnabled);
}

@end
