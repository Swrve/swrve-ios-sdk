import XCTest

@testable import SwrveSDK

class SwrveCampaignStatusTests: XCTestCase {

    func testSwrveCampaignStatusRawValues() {
        // Pre swift migration of SwrveCampaignStatus, the Objc values were as below.
        // Important to keep these as is, to ensure caches persist ok when upgrading to the later SDK.
        XCTAssertEqual(SwrveCampaignStatus.unseen.rawValue, 1, "Expected raw value of unseen to be 1")
        XCTAssertEqual(SwrveCampaignStatus.seen.rawValue, 2, "Expected raw value of seen to be 2")
        XCTAssertEqual(SwrveCampaignStatus.deleted.rawValue, 3, "Expected raw value of deleted to be 3")
    }
}
