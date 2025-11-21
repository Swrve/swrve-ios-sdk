import XCTest

@testable import SwrveSDK

class MockRestClientNotificationToCampaign: SwrveRESTClient {

    override func sendHttpRequest(_ request: NSMutableURLRequest, completionHandler handler: @escaping (URLResponse?, Data?, Error?) -> Void) {
        var data: Data? = nil
        var error: Error? = nil
        let headers = ["Content-Type": "application/json; charset=utf-8"]
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)

        if let urlString = request.url?.absoluteString {
            if urlString.contains("fc972adec8076d203cbdfd8ca0e4b1bfa483abfb") {
                if let filePath = Bundle.main.path(forResource: "fc972adec8076d203cbdfd8ca0e4b1bfa483abfb", ofType: nil) {
                    data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
                }
            } else if urlString.contains("in_app_campaign_id=295411") {
                if let filePath = Bundle.main.path(forResource: "ad_journey_campaign_message", ofType: "json") {
                    data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
                }
            } else if urlString.contains("batch") {
                data = "{}".data(using: .utf8)
                let userInfo: [String: Any] = [
                    NSLocalizedDescriptionKey: "Operation was unsuccessful.",
                    NSLocalizedFailureReasonErrorKey: "The operation timed out.",
                    NSLocalizedRecoverySuggestionErrorKey: "Have you tried turning it off and on again?"
                ]
                error = NSError(domain: "Swrve", code: 500, userInfo: userInfo)
            }
        }

        handler(response, data, error)
    }
}

class SwrveTestNotificationToCampaign: XCTestCase, SwrvePushResponseDelegate {

    override func setUp() {
        super.setUp()
        SwrveTestHelper.setUp()
        SwrveNotificationManager.updateLastProcessedPushId("")
    }

    override func tearDown() {
        SwrveTestHelper.tearDown()
        super.tearDown()
    }

    private func startSwrveAndProcessPush() -> Swrve {
        let config = SwrveConfig()
        config.autoDownloadCampaignsAndResources = false

        let swrve = SwrveTestHelper.initializeSwrve(withCampaignsFile: "campaignsNone", andConfig: config)
        swrve!.restClient = MockRestClientNotificationToCampaign()

        let payload: [String: Any] = [
            "text": "Test",
            "_p": "123456",
            "_sw": [
                "campaign": ["id": "295411"],
                "subtitle": "Test Subtitle",
                "title": "Test Title",
                "media": [
                    "title": "Test Title",
                    "body": "Test Body",
                    "subtitle": "Test Subtitle"
                ],
                "buttons": [
                    [
                        "title": "IAM",
                        "action_type": "open_campaign",
                        "action": 298233
                    ]
                ],
                "version": 1
            ]
        ]

        swrve!.processNotificationResponse(
            withIdentifier: SwrveNotificationResponseDefaultActionKey, andUserInfo: payload, notificationRequestId: "someId")

        return swrve!
    }

    func testCampaignFromNotification_Shown() {
        let swrve = startSwrveAndProcessPush()

        guard let vc = swrve.messaging else {
            XCTFail("SwrveMessageController is nil")
            return
        }

        guard let mvc = vc.inAppMessageWindow?.rootViewController as? SwrveMessageViewController else {
            XCTFail("SwrveMessageViewController is nil")
            return
        }

        let message = mvc.message
        XCTAssertEqual(message.name, "Double format")
        XCTAssertEqual(message.messageID, 298085)
    }

    func testCampaignFromNotification_WrittenToCache() {
        let swrve = startSwrveAndProcessPush()

        guard
            let campaignFile = SwrveSignatureProtectedFile().protectedFileType(
                Int32(SWRVE_NOTIFICATION_CAMPAIGN_FILE_DEBUG), userID: swrve.userID(), signatureKey: swrve.signatureKey(), errorDelegate: nil)
        else {
            XCTFail("Failed to create campaign file")
            return
        }

        guard let data = (campaignFile as AnyObject).readWithRespectToPlatform() else {
            XCTFail("Failed to read campaign file")
            return
        }

        if let cachedDic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let campaignDic = cachedDic["campaign"] as? [String: Any],
            let additionalInfoDic = cachedDic["additional_info"] as? [String: Any],
            let version = additionalInfoDic["version"] as? Int,
            let message = campaignDic["message"] as? [String: Any],
            let messageId = message["id"] as? Int,
            let name = message["name"] as? String
        {

            // Assertions
            XCTAssertEqual(version, 2)
            XCTAssertEqual(messageId, 298085)
            XCTAssertEqual(name, "Double format")
        } else {
            XCTFail("Failed to parse JSON or expected structure is missing")
        }
    }

    func testCampaignFromNotification_PushEngagedEvent() {
        let swrve = startSwrveAndProcessPush()

        guard let contents = try? Data(contentsOf: swrve.eventFilename) else {
            XCTFail("Event file is nil")
            return
        }

        guard contents.count > 2 else {
            XCTFail("Event file has no content")
            return
        }

        let truncatedContents = contents.dropLast(2)
        guard let fileContents = String(data: truncatedContents, encoding: .utf8) else {
            XCTFail("Failed to decode event file")
            return
        }

        let eventArray = "[\(fileContents)]"
        guard let bodyData = eventArray.data(using: .utf8),
            let body = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [[String: Any]]
        else {
            XCTFail("Failed to parse event array")
            return
        }

        let filtered = body.filter { $0["name"] as? String == "Swrve.Messages.Push-123456.engaged" }
        XCTAssertFalse(filtered.isEmpty, "Missing Swrve.Messages.Push-123456.engaged event")
    }

    func testCampaignFromNotification_ImpressionEvent() {
        let swrve = startSwrveAndProcessPush()

        let expectation = self.expectation(description: "ImpressionEvent")

        SwrveTestHelper.wait(
            forBlock: 0.005,
            conditionBlock: {
                let predicate = NSPredicate(format: "SELF CONTAINS %@", "Swrve.Messages.Message-298085.impression")
                let result = swrve.eventBuffer.filter { predicate.evaluate(with: $0) }
                return result.count == 1
            }, expectation: expectation)

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
