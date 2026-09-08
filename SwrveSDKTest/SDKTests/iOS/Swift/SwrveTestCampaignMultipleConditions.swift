import Foundation
import XCTest

@testable import SwrveSDK

class SwrveTestCampaignMultipleConditions: XCTestCase {

    override class func setUp() {
        SwrveTestHelper.setUp()
        SwrveTestHelper.createDummyAssets([
            "6c871366c876fdb495d96eff3d2905f9d4594c62",
            "8f984a803374d7c03c97dd122bce3ccf565bbdb5",
            "8721fd4e657980a5e12d498e73aed6e6a565dfca",
            "97c5df26c8e8fcff8dbda7e662d4272a6a94af7e"
        ])

        UIView.setAnimationsEnabled(false)
    }

    override class func tearDown() {
        SwrveTestHelper.tearDown()
    }

    func mockSwrveMessageController() throws -> SwrveMessageController? {

        SwrveSDK.sharedInstance(withAppID: 123, apiKey: "key", config: SwrveConfig())
        guard
            let swrve = SwrveSDK.sharedInstance as? Swrve,
            let controller = swrve.messaging
        else {
            return nil
        }

        let mockedJSON = try getMockDataAsDictionary(fileName: "campaignsMultipleTriggerConditions")
        var date = Date(timeIntervalSince1970: 1362873600)
        date = date.addingTimeInterval(-280)
        controller.initialisedTime = date

        controller.updateCampaigns(mockedJSON, withLoadingPreviousCampaignState: false, notifyCampaignsUpdated: false)

        return controller
    }

    func testMessageTriggerWithHalfConditions() throws {
        let message = try mockSwrveMessageController()?.baseMessage(forEvent: "Swrve.multivalue", withPayload: ["key1": "value1"])
        XCTAssertNil(message, "message displayed, it should be nil")
    }

    func testMessageTriggerWithNoConditions() throws {
        let message = try mockSwrveMessageController()?.baseMessage(forEvent: "Swrve.multivalue", withPayload: nil)
        XCTAssertNil(message, "message displayed, it should be nil")
    }

    func testMessageNoConditionTriggerWithPayload() throws {

        let controller = try mockSwrveMessageController()
        let message = controller?.baseMessage(forEvent: "Swrve.noconditions", withPayload: ["key1": "value1", "key2": "value2"])

        XCTAssertNotNil(message)
    }

    func testMessageSingleConditionTriggerWithPayload() throws {

        let controller = try mockSwrveMessageController()
        let message = controller?.baseMessage(forEvent: "Swrve.noOP", withPayload: ["key1": "value1"])

        XCTAssertNotNil(message)
    }

    func testMessageSingleConditionTriggerWithNonString() throws {

        let controller = try mockSwrveMessageController()
        let message = controller?.baseMessage(forEvent: "Swrve.noOP", withPayload: ["key1": 20])

        XCTAssertNil(message)
    }

    func testMessageSingleConditionTriggerWithNilValuePayload() throws {

        let controller = try mockSwrveMessageController()
        let message = controller?.baseMessage(forEvent: "Swrve.noOP", withPayload: ["key1": NSNull()])

        XCTAssertNil(message)
    }

    func testMessageSingleConditionTriggerWithNullKeyPayload() throws {

        let controller = try mockSwrveMessageController()
        let message = controller?.baseMessage(forEvent: "Swrve.noOP", withPayload: [NSNull(): "value1"])

        XCTAssertNil(message)
    }

    func testMessageSingleConditionTriggerWithoutPayload() throws {

        let controller = try mockSwrveMessageController()
        let message = controller?.baseMessage(forEvent: "Swrve.noOP", withPayload: nil)

        XCTAssertNil(message)
    }

}
