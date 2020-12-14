#import <XCTest/XCTest.h>

#import "SwrveConversationAtomFactory.h"
#import "SwrveContentHTML.h"
#import "SwrveContentStarRating.h"
#import "SwrveInputMultiValue.h"
#import "SwrveTestHelper.h"

#import <OCMock/OCMock.h>

#if TARGET_OS_IOS /** exclude tvOS **/
@interface SwrveTestConversationAtomFactory : XCTestCase

@end

@implementation SwrveTestConversationAtomFactory

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];    
}

- (void)testParseForHTMLContent {
    
    NSDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setValue:kSwrveContentTypeHTML forKey:@"type"];
    [dict setValue:@"cool-html-content" forKey:@"value"];
    
    
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];
    
    [dict setValue:styleDict forKey:@"style"];
    
    
    NSMutableArray<SwrveConversationAtom *> *atoms =  [SwrveConversationAtomFactory atomsForDictionary:dict];
    
    XCTAssertNotNil(atoms);
    XCTAssertTrue([atoms count] == 1, @"atom count should be no greater than 1");
    XCTAssertTrue([[atoms firstObject] isKindOfClass:[SwrveContentHTML class]]);
}

- (void)testParseStarRating {
    
    NSDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setValue:@"1427895211406-name" forKey:@"tag"];
    [dict setValue:kSwrveContentStarRating forKey:@"type"];
    [dict setValue:@"cool-html-content" forKey:@"value"];
    [dict setValue:@"#abcdef" forKey:@"star_color"];
    
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];

    [styleDict setValue:@"" forKey:@"font_file"];
    [styleDict setValue:@"" forKey:@"text_size"];

    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];
    
    [dict setValue:styleDict forKey:@"style"];
    
    NSMutableArray<SwrveConversationAtom *> *atoms =  [SwrveConversationAtomFactory atomsForDictionary:dict];
    
    XCTAssertNotNil(atoms);
    XCTAssertTrue([atoms count] == 2, @"atom count should be no greater or less than 2");
    XCTAssertTrue([[atoms firstObject] isKindOfClass:[SwrveContentHTML class]]);
    XCTAssertTrue([[atoms lastObject] isKindOfClass:[SwrveContentStarRating class]]);
    
    
    SwrveContentHTML *html = (SwrveContentHTML *)[atoms firstObject];
    XCTAssertEqualObjects(html.value, @"cool-html-content");
    XCTAssertEqualObjects(html.tag, @"1427895211406-name");
    XCTAssertEqualObjects(html.style, styleDict);
    
    SwrveContentStarRating *starRating = (SwrveContentStarRating *)[atoms lastObject];
    XCTAssertEqualObjects(starRating.starColor, @"#abcdef");
    XCTAssertEqualObjects(html.tag, @"1427895211406-name");
    XCTAssertEqualObjects(starRating.style, styleDict);
    
}

@end
#endif /** exclude tvOS **/
