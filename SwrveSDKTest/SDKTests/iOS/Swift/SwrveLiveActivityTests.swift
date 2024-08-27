import ActivityKit
import XCTest

@testable import SwrveSDK

@available(iOS 16.2, *)
final class SwrveLiveActivityTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        // Clear UserDefaults after each test
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
        UserDefaults.standard.synchronize()
    }

    func testLiveActivitiesDeviceProps_Default() {
        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")
        SwrveSDKSwift.registerLiveActivity(ofType: TestAttributes.self)

        let sdk = SwrveCommon.sharedInstance()
        let liveActivityPermission = sdk?.deviceInfo()?["swrve.permission.ios.live_activities"] as? String
        let frequentUpdatePermision = sdk?.deviceInfo()?["swrve.permission.ios.live_activities_frequent_updates"] as? String

        XCTAssertEqual(liveActivityPermission, "authorized")
        XCTAssertEqual(frequentUpdatePermision, "denied")
    }

    func testLiveActivitiesDeviceProps_True() {
        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")

        let storage = SwrveLiveActivityStorage()
        storage.saveActivitiesEnabled(true)
        storage.saveFrequentPushEnabled(true)

        let sdk = SwrveCommon.sharedInstance()
        let liveActivityPermission = sdk?.deviceInfo()?["swrve.permission.ios.live_activities"] as? String
        let frequentUpdatePermision = sdk?.deviceInfo()?["swrve.permission.ios.live_activities_frequent_updates"] as? String

        XCTAssertEqual(liveActivityPermission, "authorized")
        XCTAssertEqual(frequentUpdatePermision, "authorized")
    }

    func testLiveActivitiesDeviceProps_False() {
        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")

        let storage = SwrveLiveActivityStorage()
        storage.saveActivitiesEnabled(false)
        storage.saveFrequentPushEnabled(false)

        let sdk = SwrveCommon.sharedInstance()
        let liveActivityPermission = sdk?.deviceInfo()?["swrve.permission.ios.live_activities"] as? String
        let frequentUpdatePermision = sdk?.deviceInfo()?["swrve.permission.ios.live_activities_frequent_updates"] as? String

        XCTAssertEqual(liveActivityPermission, "denied")
        XCTAssertEqual(frequentUpdatePermision, "denied")
    }

    func testDeviceEvent() {

        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")

        let storage = SwrveLiveActivityStorage()
        storage.savePushToStartToken("pushToStartTokenValue")

        let sdk = SwrveCommon.sharedInstance()
        let pst = sdk?.deviceInfo()?["swrve.push_to_start_token"] as? String

        if #available(iOS 17.2, *) {
            XCTAssertEqual(pst, "pushToStartTokenValue")
        } else {
            XCTAssertEqual(pst, nil)
        }
    }

    func testActivityNameRetunsCorrectValue() {
        let activityName = SwrveLiveActivity.activityName(for: Activity<TestAttributes>.self)
        XCTAssertEqual("Activity<TestAttributes>", activityName)
    }

    func testConvertsAttributesPropertyToDict() {
        let attribute = TestAttributes(
            activityId: "activityId1",
            staleDate: 1710348210,
            staticAttribute1: "attribute1"
        )

        let dict = attribute.dict
        XCTAssertEqual(attribute.activityId, dict?["activityId"] as? String)
        XCTAssertEqual(attribute.staleDate, dict?["staleDate"] as? Double)
        XCTAssertEqual(attribute.staticAttribute1, dict?["staticAttribute1"] as? String)
    }

    func testMD5HashOfDictionaryKeys() {
        let attributes: [String: Any] = [
            "imageLeft": "Everton",
            "teamNameLeft": "Everton",
            "imageRight": "Chelsea",
            "teamNameRight": "Chelsea",
            "gameName": "match_56",
            "stale_date": 1710348210
        ]

        let computedHashedKeys = attributes.keys.sorted().joined(separator: ", ").md5()
        let expectedHashedKeys = "58dfef4742e876055c5055d65f09beb5"

        XCTAssertEqual(computedHashedKeys, expectedHashedKeys, "The MD5 hash of the dictionary keys does not match the expected value.")
    }

    func testSendStartEventFiredWithDuplicateActvityIdButDifferentGuid() {
        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")

        let userDefaults = UserDefaults.standard
        let activityData = SwrveLiveActivityData(id: "uniqueActivityId1", activityId: "activityId1", activityName: "my activity")
        let sut = SwrveLiveActivityStorage(userDefaults: userDefaults, storageKey: "SwrveTrackedActivites")
        sut.save(activityData)

        let event = SwrveLiveActivity.sendStartEvent(
            activityId: "activityId1",
            uniqueActivityId: "uniqueActivityId2",
            attributesType: TestAttributes.self,
            staticContentDict: ["key1": "value"],
            dynamicContentDict: ["key2": "value2"]
        )

        XCTAssertNotNil(event)
    }

    func testSendStartEventNotFiredWithDuplicateActvityIdAndDuplicateGuid() {
        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")

        let userDefaults = UserDefaults.standard
        let activityData = SwrveLiveActivityData(id: "uniqueActivityId1", activityId: "activityId1", activityName: "my activity")
        let sut = SwrveLiveActivityStorage(userDefaults: userDefaults, storageKey: "SwrveTrackedActivites")
        sut.save(activityData)

        let event = SwrveLiveActivity.sendStartEvent(
            activityId: "activityId1",
            uniqueActivityId: "uniqueActivityId1",
            attributesType: TestAttributes.self,
            staticContentDict: ["key1": "value"],
            dynamicContentDict: ["key2": "value2"]
        )

        XCTAssertNil(event)
    }

    func testSendStartEventNotFiredWhenSDKNotStarted() {
        SwrveTestHelper.destroySharedInstance()

        let event = SwrveLiveActivity.sendStartEvent(
            activityId: "activityId1",
            uniqueActivityId: "uniqueActivityId",
            attributesType: TestAttributes.self,
            staticContentDict: ["key1": "value"],
            dynamicContentDict: ["key2": "value2"]
        )
        XCTAssertEqual(event, nil)
    }

    func testSendStartEvent() {
        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")

        let event = SwrveLiveActivity.sendStartEvent(
            activityId: "activityId1",
            uniqueActivityId: "uniqueActivityId",
            attributesType: TestAttributes.self,
            staticContentDict: ["key1": "value"],
            dynamicContentDict: ["key2": "value2"]
        )
        XCTAssertEqual(event?["name"] as? String, "Swrve.live_activity_started")
        let payload = event?["payload"] as AnyObject as? [String: Any]
        XCTAssertEqual(payload?["unique_activity_id"] as? String, "uniqueActivityId")
        XCTAssertEqual(payload?["activity_id"] as? String, "activityId1")
        XCTAssertEqual(payload?["attributes_type"] as? String, "TestAttributes")
    }

    func testSendUpdateEventNotFiredWhenSDKNotStarted() {
        SwrveTestHelper.destroySharedInstance()
        let event = SwrveLiveActivity.sendUpdateEvent(activityId: "activityId1", type: "ended", uniqueActivityId: "76478236478")
        XCTAssertEqual(event, nil)
    }

    func testSendUpdateEvent() {
        SwrveSDK.sharedInstance(withAppID: 1234, apiKey: "apiKey")

        let event = SwrveLiveActivity.sendUpdateEvent(activityId: "activityId1", type: "ended", uniqueActivityId: "76478236478")
        XCTAssertEqual(event?["name"] as? String, "Swrve.live_activity_update")
        let paylod = event?["payload"] as AnyObject as? [String: Any]
        XCTAssertEqual(paylod?["unique_activity_id"] as? String, "76478236478")
        XCTAssertEqual(paylod?["activity_id"] as? String, "activityId1")
    }

    func testQueueEventAddRequiredKeyValuesToRootEventJson() {
        let event = SwrveLiveActivity.sendEvent(name: "TestEvent", payload: ["key": "value"])
        XCTAssertEqual(event["name"] as? String, "TestEvent")
        XCTAssertEqual(event["user_initiated"] as? String, "false")
        XCTAssertEqual(event["payload"] as? [String: String], ["key": "value"])
    }

}

// Mock object
@available(iOS 16.2, *)
extension SwrveLiveActivityTests {
    struct TestAttributes: SwrveLiveActivityAttributes {
        public struct ContentState: Codable, Hashable {
            var dynamicAttribute1: String
        }
        var activityId: String
        var staleDate: Double?
        var staticAttribute1: String
    }
}
