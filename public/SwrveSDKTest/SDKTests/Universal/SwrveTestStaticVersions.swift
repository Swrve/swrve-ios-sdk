import XCTest

class SwrveTestStaticVersions: XCTestCase {

    func testVersionStrings() {
        XCTAssertEqual(CAMPAIGN_VERSION, 10)
        XCTAssertEqual(CAMPAIGN_RESPONSE_VERSION, 2)
        XCTAssertEqual(EMBEDDED_CAMPAIGN_VERSION, 4)
        XCTAssertEqual(IN_APP_CAMPAIGN_VERSION, 17)
        XCTAssertEqual(SWRVE_VERSION, 3)
    }
}
