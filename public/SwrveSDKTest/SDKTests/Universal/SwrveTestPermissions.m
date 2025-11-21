#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"
#import <AppTrackingTransparency/ATTrackingManager.h>

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>

#if TARGET_OS_IOS
#import <Contacts/Contacts.h>
#endif

#if TARGET_OS_TV
#import "SwrveSDK_tvOSTests-Swift.h"
#else
#import "SwrveSDK_iOSTests-Swift.h"
#endif

@interface Swrve ()
- (void)mergeWithCurrentDeviceInfo:(NSDictionary *)attributes;
- (NSDictionary *)deviceInfo;
@end


@interface SwrveTestPermissions : XCTestCase <SwrvePermissionsDelegate>

@end

@implementation SwrveTestPermissions

- (void)testAdTrackingPermission {
    if (@available(iOS 14,tvOS 14, *)) {
        id mockManager = OCMClassMock([ATTrackingManager class]);
        OCMStub(ClassMethod([mockManager requestTrackingAuthorizationWithCompletionHandler:([OCMArg invokeBlockWithArgs:@3, nil])]));
        OCMStub(ClassMethod([mockManager trackingAuthorizationStatus])).andReturn(ATTrackingManagerAuthorizationStatusAuthorized);
        
        SwrveConfig *config = [SwrveConfig new];
        config.permissionsDelegate = self;
        
        Swrve *swrveMock = [SwrveTestHelper swrveBasicMockResponse];
        swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
        }];

        NSDictionary *deviceInfo = [swrveMock deviceInfo];
        XCTAssertEqualObjects(deviceInfo[@"swrve.permission.ios.ad_tracking"], @"authorized");
    }
}

- (SwrvePermissionState)adTrackingPermissionState {
    if (@available(iOS 14, tvOS 14, *)) {
        ATTrackingManagerAuthorizationStatus authStatus = [ATTrackingManager trackingAuthorizationStatus];
        switch (authStatus) {
            case ATTrackingManagerAuthorizationStatusAuthorized:
                return SwrvePermissionStateAuthorized;
            case ATTrackingManagerAuthorizationStatusDenied:
            case ATTrackingManagerAuthorizationStatusRestricted:
                return SwrvePermissionStateDenied;
            case ATTrackingManagerAuthorizationStatusNotDetermined:
                return SwrvePermissionStateUnknown;
        }
    }
    return SwrvePermissionStateUnsupported;
}

#if TARGET_OS_IOS


- (void)testContactsPermission {
    id contactsMock = OCMClassMock([CNContactStore class]);
    OCMStub([contactsMock authorizationStatusForEntityType:CNEntityTypeContacts]).andReturn(CNAuthorizationStatusAuthorized);
    
    SwrveConfig *config = [SwrveConfig new];
    config.permissionsDelegate = self;

    Swrve *swrveMock = [SwrveTestHelper swrveBasicMockResponse];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
    
    NSDictionary *deviceInfo = [swrveMock deviceInfo];
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.contacts"], @"authorized");
}

- (SwrvePermissionState)contactPermissionState {
    CNAuthorizationStatus authStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    switch (authStatus) {
        case CNAuthorizationStatusAuthorized:
            return SwrvePermissionStateAuthorized;
        case CNAuthorizationStatusDenied:
        case CNAuthorizationStatusRestricted:
            return SwrvePermissionStateDenied;
        case CNAuthorizationStatusNotDetermined:
            return SwrvePermissionStateUnknown;
        case CNAuthorizationStatusLimited:
            return SwrvePermissionStateAuthorized;
    }
}
#endif

- (void)testCameraPermission {
    id cameraMock = OCMClassMock([AVCaptureDevice class]);
    OCMStub([cameraMock authorizationStatusForMediaType:AVMediaTypeVideo]).andReturn(AVAuthorizationStatusAuthorized);
    
    SwrveConfig *config = [SwrveConfig new];
    config.permissionsDelegate = self;
    Swrve *swrveMock = [SwrveTestHelper swrveBasicMockResponse];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
    NSDictionary *deviceInfo = [swrveMock deviceInfo];
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.camera"], @"authorized");
}

- (SwrvePermissionState)cameraPermissionState {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authStatus) {
        case AVAuthorizationStatusAuthorized:
            return SwrvePermissionStateAuthorized;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            return SwrvePermissionStateDenied;
        case AVAuthorizationStatusNotDetermined:
            return SwrvePermissionStateUnknown;
    }
}

- (void)testStringFromPermissionState {
    XCTAssertEqualObjects(stringFromPermissionState(SwrvePermissionStateUnknown), @"unknown");
    XCTAssertEqualObjects(stringFromPermissionState(SwrvePermissionStateUnsupported), @"unsupported");
    XCTAssertEqualObjects(stringFromPermissionState(SwrvePermissionStateDenied), @"denied");
    XCTAssertEqualObjects(stringFromPermissionState(SwrvePermissionStateAuthorized), @"authorized");

    // Test for invalid state
    SwrvePermissionState invalidState = (SwrvePermissionState)999;
    XCTAssertNil(stringFromPermissionState(invalidState));
}

@end
