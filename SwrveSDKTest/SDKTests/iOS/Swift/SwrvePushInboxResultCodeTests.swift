import XCTest

class SwrvePushInboxResultCodeTests: XCTestCase {

    func testDescription() {
        XCTAssertEqual(SwrvePushInboxResultCode.SUCCESS.description, "SUCCESS")
        XCTAssertEqual(SwrvePushInboxResultCode.ERROR_UNKNOWN.description, "ERROR_UNKNOWN")
        XCTAssertEqual(SwrvePushInboxResultCode.ERROR.description, "ERROR")
    }
}
