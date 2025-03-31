import XCTest

final class SwrveTestSDKSwiftAPI: XCTestCase {

    func testAllAPISSwift() throws {
        try? SwrveTestHelper.try {

            // Purchase item
            SwrveSDK.purchaseItem("", currency: "", cost: 1, quantity: 1)

            // IAP transactions
            let transaction = SKPaymentTransaction()
            let product = SKProduct()
            let rewards = SwrveIAPRewards()
            SwrveSDK.iap(transaction, product: product)
            SwrveSDK.iap(transaction, product: product, rewards: rewards)

            // Unvalidated IAP
            SwrveSDK.unvalidatedIap(rewards, localCost: 10.0, localCurrency: "USD", productId: "product_id", productIdQuantity: 1)

            // Event tracking
            SwrveSDK.event("eventName")
            SwrveSDK.event("eventName", payload: ["key": "value"])

            // Currency given
            SwrveSDK.currency(given: "currency", givenAmount: 100.0)

            // User update
            SwrveSDK.userUpdate(["attributeKey": "attributeValue"])
            SwrveSDK.userUpdate("userAttribute", with: Date())

            // Refresh campaigns and resources
            SwrveSDK.refreshCampaignsAndResources()

            // Resource manager
            SwrveSDK.resourceManager()

            // User resources

            SwrveSDK.userResources { _, _ in
            }

            SwrveSDK.userResourcesDiff { _, _, _, _, _ in

            }

            // Real-time user properties
            SwrveSDK.realTimeUserProperties { (properties) in
                // Handle real-time user properties callback
            }

            // Event queue
            SwrveSDK.sendQueuedEvents()
            SwrveSDK.saveEventsToDisk()
            SwrveSDK.setEventQueuedCallback { _, _ in
            }

            // Event with no callback
            SwrveSDK.eventWithNoCallback("eventName", payload: ["key": "value"])

            // Shutdown
            SwrveSDK.shutdown()

            #if os(iOS)
            // Device updates
            SwrveSDK.setDeviceToken(Data())
            SwrveSDK.deviceToken()

            // Remote notifications
            SwrveSDK.didReceiveRemoteNotification(["key": "value"]) { (result, userInfo) in
                // Handle background completion handler
            }
            SwrveSDK.sendPushEngagedEvent("pushId")
            SwrveSDK.processNotificationResponse(UNNotificationResponse.testNotificationResponse(with: "Test"))
            #endif

            // Handle deeplinks
            SwrveSDK.handleDeeplink(URL(string: "https://example.com")!)
            SwrveSDK.handleDeferredDeeplink(URL(string: "https://example.com")!)
            SwrveSDK.installAction(URL(string: "https://example.com")!)

            // Identify
            SwrveSDK.identify(
                "externalUserId",
                onSuccess: { (status, swrveUserId) in
                    // Handle success
                },
                onError: { (httpCode, errorMessage) in
                    // Handle error
                })

            // External user ID
            SwrveSDK.externalUserId()

            // Start
            SwrveSDK.start()

            // Check if started
            SwrveSDK.started()

            // Stop tracking
            SwrveSDK.stopTracking()

            let embeddedMessage = SwrveEmbeddedMessage()
            SwrveSDK.embeddedControlMessageImpressionEvent(SwrveEmbeddedMessage())
            SwrveSDK.embeddedMessageWasShown(toUser: embeddedMessage)
            SwrveSDK.embeddedButtonWasPressed(embeddedMessage, buttonName: "buttonName")
            SwrveSDK.personalizeEmbeddedMessageData(embeddedMessage, withPersonalization: ["key": "value"])
            SwrveSDK.personalizeText("text", withPersonalization: ["key": "value"])

            // Message center campaigns
            SwrveSDK.messageCenterCampaigns()
            SwrveSDK.messageCenterCampaigns(withPersonalization: ["key": "value"])
            let campaign = SwrveSDK.messageCenterCampaign(withID: 1, andPersonalization: ["key": "value"])

            #if os(iOS)
            SwrveSDK.messageCenterCampaignsThatSupport(.portrait)
            SwrveSDK.messageCenterCampaignsThatSupport(.portrait, withPersonalization: ["key": "value"])
            #endif

            // Show and remove message center campaign
            SwrveSDK.showMessageCenter(SwrveCampaign(at: Date(), from: [:], campaignType: SWRVE_CAMPAIGN_IAM))
            SwrveSDK.showMessageCenter(SwrveCampaign(at: Date(), from: [:], campaignType: SWRVE_CAMPAIGN_IAM), withPersonalization: ["key": "value"])
            SwrveSDK.removeMessageCenter(SwrveCampaign(at: Date(), from: [:], campaignType: SWRVE_CAMPAIGN_IAM))
            SwrveSDK.markMessageCenterCampaign(asSeen: SwrveCampaign(at: Date(), from: [:], campaignType: SWRVE_CAMPAIGN_IAM))

            // IDFA
            SwrveSDK.idfa("idfa_string")
        }
    }

    func testStartAPI() {
        try? SwrveTestHelper.try {
            SwrveSDK.start(withUserId: "userId")
        }
    }

}

extension UNNotificationResponse {

    static func testNotificationResponse(with payloadFilename: String) -> UNNotificationResponse {
        let request = notificationRequest(with: [:])
        return UNNotificationResponse(coder: TestNotificationCoder(with: request))!
    }

    private static func notificationRequest(with parameters: [AnyHashable: Any]) -> UNNotificationRequest {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Title"
        notificationContent.body = "Body"
        notificationContent.userInfo = parameters

        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)

        let notificationRequest = UNNotificationRequest(identifier: "id", content: notificationContent, trigger: trigger)
        return notificationRequest
    }
}

private class TestNotificationCoder: NSCoder {

    private enum FieldKey: String {
        case date, request, sourceIdentifier, intentIdentifiers, notification, actionIdentifier, originIdentifier, targetConnectionEndpoint,
            targetSceneIdentifier
    }
    private let testIdentifier = "id"
    private let request: UNNotificationRequest
    override var allowsKeyedCoding: Bool { true }

    init(with request: UNNotificationRequest) {
        self.request = request
    }

    override func decodeObject(forKey key: String) -> Any? {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .date:
            return Date()
        case .request:
            return request
        case .sourceIdentifier, .actionIdentifier, .originIdentifier:
            return testIdentifier
        case .notification:
            return UNNotification(coder: self)
        default:
            return nil
        }
    }
}
