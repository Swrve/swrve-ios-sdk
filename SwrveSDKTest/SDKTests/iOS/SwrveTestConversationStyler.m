#import <XCTest/XCTest.h>
#import "Swrve.h"
#import "SwrveContentVideo.h"
#import "SwrveContentStarRating.h"
#import "SwrveConversationStyler.h"
#import "SwrveTestHelper.h"
#import "SwrveConversationResourceManagement.h"
#import "SwrveLocalStorage.h"

@interface SwrveTestConversationStyler : XCTestCase

@end

@implementation SwrveTestConversationStyler

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

-(void)testStyleButtonSolid {
    CGFloat sizeInPixels = 18.0f;
    CGFloat sizeInPoints = sizeInPixels;

    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"solid") forKey:@"type"];

    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"color") forKey:@"type"];
    [bgDict setValue:(@"#abcdef") forKey:@"value"];
    [styleDict setValue:(bgDict) forKey:@"bg"];

    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];

    [styleDict setValue:(@"") forKey:@"font_file"];
    [styleDict setValue:([NSNumber numberWithDouble:sizeInPixels]) forKey:@"text_size"];

    SwrveConversationUIButton *uiButton = [[SwrveConversationUIButton alloc] init];
    XCTAssertNil(uiButton.backgroundColor);

    [SwrveConversationStyler styleButton:uiButton withStyle:styleDict];

    XCTAssertNotNil(uiButton.backgroundColor);
    UIColor *bgUIColor = [SwrveConversationStyler convertToUIColor:@"#abcdef"];
    XCTAssertTrue(CGColorEqualToColor(uiButton.backgroundColor.CGColor, bgUIColor.CGColor));

    XCTAssertNotNil(uiButton.currentTitleColor);
    UIColor *fgUIColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    XCTAssertTrue(CGColorEqualToColor(uiButton.currentTitleColor.CGColor, fgUIColor.CGColor));

    XCTAssertNotNil(uiButton.titleLabel.font);
    XCTAssertEqual(uiButton.titleLabel.font.pointSize, sizeInPoints);
}

-(void)testSystemFontFromStyle {
    UIFont *fallback = [UIFont boldSystemFontOfSize:10.0];

    // Normal system font
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"_system_font_") forKey:@"font_file"];
    [styleDict setValue:(@"Normal") forKey:@"font_native_style"];
    [styleDict setValue:([NSNumber numberWithDouble:50.0f]) forKey:@"text_size"];
    UIFont *uiFont = [SwrveConversationStyler fontFromStyle:styleDict withFallback:fallback];
    XCTAssertNotNil(uiFont);
    XCTAssertEqual(uiFont.pointSize, 50.0f);
    XCTAssertEqualObjects(uiFont.familyName, [UIFont systemFontOfSize:50.0f].familyName);

    // Bold system font
    styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"_system_font_") forKey:@"font_file"];
    [styleDict setValue:(@"Bold") forKey:@"font_native_style"];
    [styleDict setValue:([NSNumber numberWithDouble:50.0f]) forKey:@"text_size"];
    uiFont = [SwrveConversationStyler fontFromStyle:styleDict withFallback:fallback];
    XCTAssertNotNil(uiFont);
    XCTAssertEqual(uiFont.pointSize, 50.0f);
    XCTAssertEqualObjects(uiFont.familyName, [UIFont boldSystemFontOfSize:50.0f].familyName);

    // Italic system font
    styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"_system_font_") forKey:@"font_file"];
    [styleDict setValue:(@"Italic") forKey:@"font_native_style"];
    [styleDict setValue:([NSNumber numberWithDouble:50.0f]) forKey:@"text_size"];
    uiFont = [SwrveConversationStyler fontFromStyle:styleDict withFallback:fallback];
    XCTAssertNotNil(uiFont);
    XCTAssertEqual(uiFont.pointSize, 50.0f);
    XCTAssertEqualObjects(uiFont.familyName, [UIFont italicSystemFontOfSize:50.0f].familyName);

    // BoldItalic system font
    styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"_system_font_") forKey:@"font_file"];
    [styleDict setValue:(@"BoldItalic") forKey:@"font_native_style"];
    [styleDict setValue:([NSNumber numberWithDouble:50.0f]) forKey:@"text_size"];
    uiFont = [SwrveConversationStyler fontFromStyle:styleDict withFallback:fallback];
    XCTAssertNotNil(uiFont);
    XCTAssertEqual(uiFont.pointSize, 50.0f);

    UILabel * label = [[UILabel alloc] init];
    UIFontDescriptor * fontD = [label.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
    label.font = [UIFont fontWithDescriptor:fontD size:50.f];
    XCTAssertEqualObjects(uiFont.familyName, label.font.familyName);
}

-(void)testAlreadyLoadedFontFromStyle {
    CGFloat sizeInPixels = 50.0f;
    CGFloat sizeInPoints = sizeInPixels;

    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"some_file_name") forKey:@"font_file"];
    [styleDict setValue:(@"Helvetica") forKey:@"font_postscript_name"];
    [styleDict setValue:([NSNumber numberWithDouble:50.0]) forKey:@"text_size"];

    UIFont *fallback = [UIFont boldSystemFontOfSize:10.0];
    UIFont *uiFont = [SwrveConversationStyler fontFromStyle:styleDict withFallback:fallback];

    XCTAssertNotNil(uiFont);
    XCTAssertEqual(uiFont.pointSize, sizeInPoints);
    XCTAssertEqualObjects(uiFont.familyName, [UIFont fontWithName:@"Helvetica" size:sizeInPoints].familyName);
}

- (void)testCustomFontFromStyle {
    CGFloat sizeInPixels = 50.0f;
    CGFloat sizeInPoints = sizeInPixels;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cache = [SwrveLocalStorage swrveCacheFolder];
    if ([fileManager fileExistsAtPath:cache] == NO) {
        [fileManager createDirectoryAtPath:cache withIntermediateDirectories:NO attributes:nil error:nil]; //Create folder
    }
    [SwrveTestHelper deleteFilesInDirectory:cache];

    NSString *fontFile = @"040843601e697027b119f93a3fdb2c9c04d1ea63.otf";
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:fontFile forKey:@"font_file"];
    [styleDict setValue:([NSNumber numberWithDouble:50.0]) forKey:@"text_size"];

    NSError *error;
    NSString *filePath = [cache stringByAppendingPathComponent:fontFile];
    if ([fileManager fileExistsAtPath:filePath] == NO) {
        NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"040843601e697027b119f93a3fdb2c9c04d1ea63" ofType:@"otf"];
        BOOL success = [fileManager copyItemAtPath:srcPath toPath:filePath error:&error];
        NSLog(success ? @"testCustomFontFromStyle:Successfully copied custom font to cache" : @"testCustomFontFromStyle:Error copying custom font to cache");
    }

    UIFont *fallback = [UIFont boldSystemFontOfSize:10.0];
    UIFont *uiFont = [SwrveConversationStyler fontFromStyle:styleDict withFallback:fallback];

    XCTAssertNotNil(uiFont);
    XCTAssertEqual(uiFont.pointSize, sizeInPoints);
    XCTAssertEqualObjects(uiFont.familyName, [UIFont fontWithName:@"Source Sans Pro" size:sizeInPoints].familyName);
}

- (void)testCustomBadFontFromStyle {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cache = [SwrveLocalStorage swrveCacheFolder];
    if ([fileManager fileExistsAtPath:cache] == NO) {
        [fileManager createDirectoryAtPath:cache withIntermediateDirectories:NO attributes:nil error:nil]; //Create folder
    }
    [SwrveTestHelper deleteFilesInDirectory:cache];

    NSString *fontFile = @"campaignConversation.json"; // this isn't a font file so the fallback will be used.
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:fontFile forKey:@"font_file"];
    [styleDict setValue:([NSNumber numberWithDouble:50.0]) forKey:@"text_size"];

    NSError *error;
    NSString *filePath = [cache stringByAppendingPathComponent:fontFile];
    if ([fileManager fileExistsAtPath:filePath] == NO) {
        NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"campaignConversation" ofType:@"json"]; // this is a bad font file on purpose (its json)
        BOOL success = [fileManager copyItemAtPath:srcPath toPath:filePath error:&error];
        NSLog(success ? @"testCustomBadFontFromStyle:Successfully copied campaignConversation" : @"testCustomFontFromStyle:Error copying campaignConversation");
    }

    UIFont *fallback = [UIFont boldSystemFontOfSize:10.0];
    UIFont *uiFont = [SwrveConversationStyler fontFromStyle:styleDict withFallback:fallback];

    XCTAssertNotNil(uiFont);
    XCTAssertEqual(uiFont.pointSize, fallback.pointSize);
    XCTAssertEqualObjects(uiFont.familyName, fallback.familyName);
}

-(void)testStyleButtonSolidTransparent {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"solid") forKey:@"type"];
    
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];
    
    SwrveConversationUIButton *uiButton = [[SwrveConversationUIButton alloc] init];
    XCTAssertNil(uiButton.backgroundColor);
    
    [SwrveConversationStyler styleButton:uiButton withStyle:styleDict];
    
    XCTAssertNotNil(uiButton.backgroundColor);
    XCTAssertTrue(CGColorEqualToColor(uiButton.backgroundColor.CGColor, [UIColor clearColor].CGColor));
    
    XCTAssertNotNil(uiButton.currentTitleColor);
    UIColor *fgUIColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    XCTAssertTrue(CGColorEqualToColor(uiButton.currentTitleColor.CGColor, fgUIColor.CGColor));
}

-(void)testStyleButtonOutline {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"outline") forKey:@"type"];
    
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];
    
    SwrveConversationUIButton *uiButton = [[SwrveConversationUIButton alloc] init];
    XCTAssertNil(uiButton.backgroundColor);
    
    [SwrveConversationStyler styleButton:uiButton withStyle:styleDict];
    
    XCTAssertNotNil(uiButton.backgroundColor);
    XCTAssertTrue(CGColorEqualToColor(uiButton.backgroundColor.CGColor, [UIColor clearColor].CGColor));
    
    XCTAssertNotNil(uiButton.currentTitleColor);
    UIColor *fgUIColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    XCTAssertTrue(CGColorEqualToColor(uiButton.currentTitleColor.CGColor, fgUIColor.CGColor));
    
    XCTAssertEqual([[uiButton layer] borderWidth], 1.5);
    XCTAssertTrue(CGColorEqualToColor([[uiButton layer] borderColor], fgUIColor.CGColor));
}

-(void)testStyleButtonCurved {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"solid") forKey:@"type"];
    [styleDict setValue:(@"50") forKey:@"border_radius"];
    
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"color") forKey:@"type"];
    [bgDict setValue:(@"#abcdef") forKey:@"value"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];
    
    SwrveConversationUIButton *uiButton = [[SwrveConversationUIButton alloc] init];
    [SwrveConversationStyler styleButton:uiButton withStyle:styleDict];
    
    XCTAssertEqual([[uiButton layer] cornerRadius], 11.25);
    
    float borderRadius = [SwrveConversationStyler convertBorderRadius:25.0];
    XCTAssertEqual(borderRadius, 5.625);
    
    borderRadius = [SwrveConversationStyler convertBorderRadius:100.0];
    XCTAssertEqual(borderRadius, 22.5);
    
    borderRadius = [SwrveConversationStyler convertBorderRadius:110.0];
    XCTAssertEqual(borderRadius, 22.5);
    
}

-(void)testSytleButtonCurvedZero {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(@"solid") forKey:@"type"];
    [styleDict setValue:(@"0") forKey:@"border_radius"];
    
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"color") forKey:@"type"];
    [bgDict setValue:(@"#abcdef") forKey:@"value"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];
    
    SwrveConversationUIButton *uiButton = [[SwrveConversationUIButton alloc] init];
    [SwrveConversationStyler styleButton:uiButton withStyle:styleDict];
    
    XCTAssertEqual([[uiButton layer] cornerRadius], 0.0);
}


-(void)testStyleStarRatingTransparent {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];
    
    SwrveContentStarRatingView *uiRatingView = [[SwrveContentStarRatingView alloc] initWithDefaults];
    [SwrveConversationStyler styleStarRating:uiRatingView withStyle:styleDict withStarColor:@"#cc8534"];
    
    XCTAssertNotNil(uiRatingView.backgroundColor);
    XCTAssertTrue(CGColorEqualToColor(uiRatingView.backgroundColor.CGColor, [UIColor clearColor].CGColor));
}


-(void)testStyleStarRatingSolid {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"color") forKey:@"type"];
    [bgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    SwrveContentStarRatingView *uiRatingView = [[SwrveContentStarRatingView alloc] initWithDefaults];
    [SwrveConversationStyler styleStarRating:uiRatingView withStyle:styleDict withStarColor:@"#cc8534"];
    
    UIColor *bgUIColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    
    XCTAssertNotNil(uiRatingView.backgroundColor);
    XCTAssertTrue(CGColorEqualToColor(uiRatingView.backgroundColor.CGColor, bgUIColor.CGColor));
}


-(void)testStyleModalBothColorAndBorderRadius {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    
    NSDictionary *lbDict = [[NSMutableDictionary alloc] init];
    [lbDict setValue:(@"color") forKey:@"type"];
    [lbDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(lbDict) forKey:@"lb"];
    [styleDict setValue:@"100.0" forKey:@"border_radius"];
    
    
    UIView *parentView = [[UIView alloc] init];
    UIView *testVC = [[UIView alloc] init];
    [parentView addSubview:testVC];
    
    XCTAssertNotNil(testVC.superview);
    
    [SwrveConversationStyler styleModalView:testVC withStyle:styleDict];
    
    UIColor *lbUIColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    XCTAssertEqual(testVC.layer.cornerRadius, 22.5f);
    XCTAssertNotNil(parentView.backgroundColor);
    XCTAssertTrue(CGColorEqualToColor(parentView.backgroundColor.CGColor, lbUIColor.CGColor));
    
}

-(void)testStyleModalColorOnly {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    NSDictionary *lbDict = [[NSMutableDictionary alloc] init];
    [lbDict setValue:(@"color") forKey:@"type"];
    [lbDict setValue:(@"#FFcc8534") forKey:@"value"];
    [styleDict setValue:(lbDict) forKey:@"lb"];
    
    UIView *parentView = [[UIView alloc] init];
    UIView *testVC = [[UIView alloc] init];
    [parentView addSubview:testVC];
    
    XCTAssertNotNil(testVC.superview);
    
    [SwrveConversationStyler styleModalView:testVC withStyle:styleDict];
    UIColor *lbUIColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    XCTAssertNotNil(parentView.backgroundColor);
    XCTAssertTrue(CGColorEqualToColor(parentView.backgroundColor.CGColor, lbUIColor.CGColor));
}



-(void)testStyleModalBorderRadiusOnly {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:@"100.0" forKey:@"border_radius"];
    
    UIView *testView = [[UIView alloc] init];
    [SwrveConversationStyler styleModalView:testView withStyle:styleDict];
    XCTAssertEqual(testView.layer.cornerRadius, 22.5f);
}


- (void)testColorConverter {
    UIColor *SixCharHexColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    UIColor *EightCharHexColor = [SwrveConversationStyler convertToUIColor:@"#FFcc8534"]; //FF is alpha 1.0
    
    XCTAssertTrue(CGColorEqualToColor(SixCharHexColor.CGColor, EightCharHexColor.CGColor));
}

 - (void)testImageAssetsLoaded {
    
    UIImage *closeButton = [SwrveConversationResourceManagement imageWithName:@"close_button"];
    XCTAssertNotNil(closeButton);
    
    UIImage *starEmpty = [SwrveConversationResourceManagement imageWithName:@"star_empty"];
    XCTAssertNotNil(starEmpty);
    
    UIImage *starFull = [SwrveConversationResourceManagement imageWithName:@"star_full"];
    XCTAssertNotNil(starFull);
}

@end
