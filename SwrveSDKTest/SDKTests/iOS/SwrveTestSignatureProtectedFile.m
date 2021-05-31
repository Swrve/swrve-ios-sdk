#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSignatureProtectedFile.h"
#import "SwrveProtocol.h"
#import "SwrveUtils.h"
#import "SwrveLocalStorage.h"
#import "SwrveSDK.h"
#import "SwrveProfileManager.h"
#import "SwrveMessageController.h"


@interface Swrve ()
@property(atomic) SwrveMessageController *messaging;
@property(atomic) SwrveProfileManager *profileManager;
@property(atomic) SwrveSignatureProtectedFile *resourcesFile;
@property(atomic) SwrveSignatureProtectedFile *resourcesDiffFile;
@property(atomic) SwrveSignatureProtectedFile *realTimeUserPropertiesFile;
@property(atomic) NSURL *eventFilename;
@end


@interface SwrveMessageController ()
@property (nonatomic, retain) SwrveSignatureProtectedFile *campaignFile;
@end

@interface SwrveTestSignatureProtectedFile : XCTestCase
@end

@implementation SwrveTestSignatureProtectedFile

- (void)testFilenames {
    id localStorage = OCMClassMock([SwrveLocalStorage class]);
    OCMStub([localStorage swrveUserId]).andReturn(@"SomeID");
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    NSString *expectedResourceFile = [swrveMock resourcesFile].filename.absoluteString.lastPathComponent;
    NSString *expectedResourceDiffFile = [swrveMock resourcesDiffFile].filename.absoluteString.lastPathComponent;
    NSString *expectedCampaignFile = [swrveMock messaging].campaignFile.filename.absoluteString.lastPathComponent;
    NSString *expectedEventFile = [swrveMock eventFilename].absoluteString.lastPathComponent;
    
    XCTAssertTrue([expectedResourceFile isEqualToString:@"SomeIDsrcngt2.txt"],@"Value: %@", expectedResourceFile);
    XCTAssertTrue([expectedResourceDiffFile isEqualToString:@"SomeIDrsdfngt2.txt"],@"Value: %@", expectedResourceDiffFile);
    XCTAssertTrue([expectedCampaignFile isEqualToString:@"SomeIDcmcc2.json"],@"Value: %@", expectedCampaignFile);
    XCTAssertTrue([expectedEventFile isEqualToString:@"SomeIDswrve_events.txt"],@"Value: %@", expectedEventFile);
}

- (void)testSignatureProtectedFile_ResourceFile {
    
    NSString * testUserID = @"TestUserID";
    NSString * testSignatureKey = @"TestSignatureKey";
    
    SwrveSignatureProtectedFile *protectedFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_RESOURCE_FILE
                                                                                                  userID:testUserID
                                                                                            signatureKey:testSignatureKey
                                                                                           errorDelegate:nil];
    // Normal File
    NSURL * fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage userResourcesFilePathForUserId:testUserID]];
    NSString * expectedURL  = [fileURL absoluteString];
    NSString * generatedURL = [[protectedFile filename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
    
    // Signature File
    fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage userResourcesSignatureFilePathForUserId:testUserID]];
    expectedURL  = [fileURL absoluteString];
    generatedURL = [[protectedFile signatureFilename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
}

- (void)testSignatureProtectedFile_ResourceFileDiff {
    
    NSString *testUserID = @"TestUserID";
    NSString *testSignatureKey = @"TestSignatureKey";
    
    SwrveSignatureProtectedFile * protectedFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_RESOURCE_DIFF_FILE
                                                                                                   userID:testUserID
                                                                                             signatureKey:testSignatureKey
                                                                                            errorDelegate:nil];
    // Normal File
    NSURL *fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage userResourcesDiffFilePathForUserId:testUserID]];
    NSString *expectedURL  = [fileURL absoluteString];
    NSString *generatedURL = [[protectedFile filename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
    
    // Signature File
    fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage userResourcesDiffSignatureFilePathForUserId:testUserID]];
    expectedURL  = [fileURL absoluteString];
    generatedURL = [[protectedFile signatureFilename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
}

- (void)testSignatureProtectedFile_CampaignFile {
    
    NSString *testUserID = @"TestUserID";
    NSString *testSignatureKey = @"TestSignatureKey";
    
    SwrveSignatureProtectedFile * protectedFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_CAMPAIGN_FILE
                                                                                                   userID:testUserID
                                                                                             signatureKey:testSignatureKey
                                                                                            errorDelegate:nil];
    // Normal File
    NSURL *fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage campaignsFilePathForUserId:testUserID]];
    NSString *expectedURL  = [fileURL absoluteString];
    NSString *generatedURL = [[protectedFile filename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
    
    // Signature File
    fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage campaignsSignatureFilePathForUserId:testUserID]];
    expectedURL  = [fileURL absoluteString];
    generatedURL = [[protectedFile signatureFilename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
}

- (void)testSignatureProtectedFile_NoticationCampaignFile {
    
    NSString *testUserID = @"TestUserID";
    NSString *testSignatureKey = @"TestSignatureKey";
    
    SwrveSignatureProtectedFile * protectedFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE
                                                                                                   userID:testUserID
                                                                                             signatureKey:testSignatureKey
                                                                                            errorDelegate:nil];
    // Normal File
    NSURL *fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage offlineCampaignsFilePathForUserId:testUserID]];
    NSString *expectedURL  = [fileURL absoluteString];
    NSString *generatedURL = [[protectedFile filename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
    
    // Signature File
    fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage offlineCampaignsSignatureFilePathForUserId:testUserID]];
    expectedURL  = [fileURL absoluteString];
    generatedURL = [[protectedFile signatureFilename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
}

- (void)testSignatureProtectedFile_NoticationDebugCampaignFile {
    
    NSString *testUserID = @"TestUserID";
    NSString *testSignatureKey = @"TestSignatureKey";
    
    SwrveSignatureProtectedFile * protectedFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_NOTIFICATION_CAMPAIGN_FILE_DEBUG
                                                                                                   userID:testUserID
                                                                                             signatureKey:testSignatureKey
                                                                                            errorDelegate:nil];
    // Normal File
    NSURL *fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage debugCampaignsNoticationFilePathForUserId:testUserID]];
    NSString *expectedURL  = [fileURL absoluteString];
    NSString *generatedURL = [[protectedFile filename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
    
    // Signature File
    fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage debugCampaignsNotificationSignatureFilePathForUserId:testUserID]];
    expectedURL  = [fileURL absoluteString];
    generatedURL = [[protectedFile signatureFilename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);

}

- (void)testSignatureProtectedFile_AdCampaignFile {
    
    NSString *testUserID = @"TestUserID";
    NSString *testSignatureKey = @"TestSignatureKey";
    
    SwrveSignatureProtectedFile * protectedFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_AD_CAMPAIGN_FILE
                                                                                                   userID:testUserID
                                                                                             signatureKey:testSignatureKey
                                                                                            errorDelegate:nil];
    // Normal File
    NSURL *fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage campaignsAdFilePathForUserId:testUserID]];
    NSString *expectedURL  = [fileURL absoluteString];
    NSString *generatedURL = [[protectedFile filename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
    
    // Signature File
    fileURL = [NSURL fileURLWithPath:[SwrveLocalStorage campaignsAdSignatureFilePathForUserId:testUserID]];
    expectedURL  = [fileURL absoluteString];
    generatedURL = [[protectedFile signatureFilename] absoluteString];
    XCTAssertTrue([expectedURL isEqualToString:generatedURL]);
}

@end
