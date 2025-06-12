import XCTest

@testable import SwrveSDK

class MockSwrve: NSObject, SwrveProtocol {

    var config: SwrveConfig!
    var appID: Int
    var apiKey: String!
    var resourceManager: SwrveResourceManager!

    var lastPushNotificationEngagedPushId: String?
    var lastPushNotificationEngagedPayload: [AnyHashable: Any]?

    required init!(appID swrveAppID: Int32, apiKey swrveAPIKey: String!) {
        appID = Int(swrveAppID)
    }

    required init!(appID swrveAppID: Int32, apiKey swrveAPIKey: String!, config swrveConfig: SwrveConfig!) {
        appID = Int(swrveAppID)
    }

    func purchaseItem(_ itemName: String!, currency itemCurrency: String!, cost itemCost: Int32, quantity itemQuantity: Int32) -> Int32 {
        0
    }

    func iap(_ transaction: SKPaymentTransaction!, product: SKProduct!) -> Int32 {
        0
    }

    func iap(_ transaction: SKPaymentTransaction!, product: SKProduct!, rewards: SwrveIAPRewards!) -> Int32 {
        0
    }

    func unvalidatedIap(_ rewards: SwrveIAPRewards!, localCost: Double, localCurrency: String!, productId: String!, productIdQuantity: Int32) -> Int32
    {
        0
    }

    func event(_ eventName: String!) -> Int32 {
        0
    }

    func event(_ eventName: String!, payload eventPayload: [AnyHashable: Any]!) -> Int32 {
        0
    }

    func currency(given givenCurrency: String!, givenAmount: Double) -> Int32 {
        0
    }

    func userUpdate(_ attributes: [AnyHashable: Any]!) -> Int32 {
        0
    }

    func userUpdate(_ name: String!, with date: Date!) -> Int32 {
        0
    }

    func refreshContent(_ listener: (any SwrveRefreshContentDelegate)!) {
    }

    func userResources(_ callbackBlock: SwrveUserResourcesCallback!) {
    }

    func userResourcesDiff(listener: SwrveUserResourcesDiffListener!) {
    }

    func realTimeUserProperties(_ callbackBlock: SwrveRealTimeUserPropertiesCallback!) {
    }

    func sendQueuedEvents() {
    }

    func saveEventsToDisk() {
    }

    func setEventQueuedCallback(_ callbackBlock: SwrveEventQueuedCallback!) {
    }

    func eventWithNoCallback(_ eventName: String!, payload eventPayload: [AnyHashable: Any]!) -> Int32 {
        0
    }

    func shutdown() {
    }

    func sendDeviceUpdate() {
    }

    func setDeviceToken(_ deviceToken: Data!) {
    }

    func deviceToken() -> String! {
        ""
    }

    func sendPushNotificationEngagedEvent(_ pushId: String!, withPayload payload: [AnyHashable: Any]!) {
        self.lastPushNotificationEngagedPushId = pushId
        self.lastPushNotificationEngagedPayload = payload
    }

    #if os(iOS)
    func processNotificationResponse(_ response: UNNotificationResponse!) {
    }
    #endif

    func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any]!, withBackgroundCompletionHandler completionHandler: ((UIBackgroundFetchResult, [AnyHashable: Any]?) -> Void)!
    ) -> Bool {
        false
    }

    func handleDeeplink(_ url: URL!) {
    }

    func handleDeferredDeeplink(_ url: URL!) {
    }

    func installAction(_ url: URL!) {
    }

    func userID() -> String! {
        ""
    }

    func identify(_ externalUserId: String!, onSuccess: ((String?, String?) -> Void)!, onError: ((Int, String?) -> Void)!) {
    }

    func externalUserId() -> String! {
        ""
    }

    func start() {
    }

    func start(withUserId userId: String!) {
    }

    func started() -> Bool {
        false
    }

    func stopTracking() {
    }

    func embeddedControlMessageImpressionEvent(_ message: SwrveEmbeddedMessage!) {
    }

    func embeddedMessageWasShown(toUser message: SwrveEmbeddedMessage!) {
    }

    func embeddedButtonWasPressed(_ message: SwrveEmbeddedMessage!, buttonName button: String!) {
    }

    func personalizeEmbeddedMessageData(_ message: SwrveEmbeddedMessage!, withPersonalization personalizationProperties: [AnyHashable: Any]!)
        -> String!
    {
        ""
    }

    func personalizeText(_ text: String!, withPersonalization personalizationProperties: [AnyHashable: Any]!) -> String! {
        ""
    }

    func messageCenterCampaigns() -> [SwrveCampaign]! {
        nil
    }

    func messageCenterCampaigns(withPersonalization personalization: [AnyHashable: Any]!) -> [SwrveCampaign]! {
        nil
    }

    func messageCenterCampaign(withID campaignID: UInt, andPersonalization personalization: [AnyHashable: Any]!) -> SwrveCampaign! {
        nil
    }

    #if os(iOS)
    func messageCenterCampaignsThatSupport(_ orientation: UIInterfaceOrientation) -> [SwrveCampaign]! {
        nil
    }

    func messageCenterCampaignsThatSupport(_ orientation: UIInterfaceOrientation, withPersonalization personalization: [AnyHashable: Any]!)
        -> [SwrveCampaign]!
    {
        nil
    }

    func inAppMessageCenterCampaigns(with orientation: UIInterfaceOrientation, withPersonalization personalization: [AnyHashable: Any]!)
        -> [SwrveInAppCampaign]!
    {
        nil
    }

    #endif

    func embeddedMessageCenterCampaigns() -> [SwrveEmbeddedMessage]! {
        nil
    }

    func showMessageCenter(_ campaign: SwrveCampaign!) -> Bool {
        false
    }

    func showMessageCenter(_ campaign: SwrveCampaign!, withPersonalization personalization: [AnyHashable: Any]!) -> Bool {
        false
    }

    func removeMessageCenter(_ campaign: SwrveCampaign!) {
    }

    func removeMessageCenterCampaign(withID campaignID: UInt) {
    }

    func markMessageCenterCampaign(asSeen campaign: SwrveCampaign!) {
    }

    func markMessageCenterCampaignAsSeen(withID campaignID: UInt) {
    }

    func idfa(_ idfa: String!) {
    }

    func pushInboxMessages() -> [SwrvePushInboxMessage]! {
        nil
    }

    func readPushInboxMessage(_ messageId: UInt64, listener: (any SwrvePushInboxDelegate)!) {
    }

    func deletePushInboxMessage(_ messageId: UInt64, listener: (any SwrvePushInboxDelegate)!) {
    }

    func engagePushInboxMessage(_ messageId: UInt64, listener: (any SwrvePushInboxDelegate)!) {
    }

    func pushInboxUpdateListener(_ listener: (any SwrvePushInboxUpdateDelegate)!) {
    }

    func dismissMessageWindow() {
    }

    func updateLanguage(_ language: String!) {
    }
}

class SwrveSDKTests: XCTestCase {

    #if os(iOS)
    func testSendPushEngagedEvent() {

        let mockSwrve = MockSwrve(appID: 123, apiKey: "apiKey")
        SwrveSDK.sharedInstance = mockSwrve

        SwrveSDK.sendPushEngagedEvent("testPushId", "testTrackingData", "testPlatform")

        XCTAssertEqual(mockSwrve!.lastPushNotificationEngagedPushId, "testPushId")
        if let payload = mockSwrve!.lastPushNotificationEngagedPayload {
            XCTAssertEqual(payload.count, 2)
            XCTAssertEqual(payload[SwrveNotificationTrackingDataKey] as? String, "testTrackingData")
            XCTAssertEqual(payload[SwrveNotificationPlatformKey] as? String, "testPlatform")
        } else {
            XCTFail("Payload is nil")
        }
    }

    func testSendPushEngagedEventWithDeeplink() {

        let mockSwrve = MockSwrve(appID: 123, apiKey: "apiKey")
        SwrveSDK.sharedInstance = mockSwrve

        SwrveSDK.sendPushEngagedEvent("testPushId", "testTrackingData", "testPlatform", "swrve://deeplink")

        XCTAssertEqual(mockSwrve!.lastPushNotificationEngagedPushId, "testPushId")
        if let payload = mockSwrve!.lastPushNotificationEngagedPayload {
            XCTAssertEqual(payload.count, 3)
            XCTAssertEqual(payload[SwrveNotificationTrackingDataKey] as? String, "testTrackingData")
            XCTAssertEqual(payload[SwrveNotificationPlatformKey] as? String, "testPlatform")
            XCTAssertEqual(payload["deeplink"] as? String, "swrve://deeplink")
        } else {
            XCTFail("Payload is nil")
        }
    }
    #endif

}
