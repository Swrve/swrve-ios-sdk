import XCTest

@testable import SwrveSDK

class SwrveUtilsSwiftTests: XCTestCase {

    func testParseIso8601DateGlobal() {
        let isoDate = "2023-09-11T10:15:30Z"
        let result = SwrveUtilsSwift.parseIso8601Date(isoDate, timezoneType: .GLOBAL)
        XCTAssertNotNil(result, "The date should be parsed and not nil")

        let formatter = ISO8601DateFormatter()
        let expectedDate = formatter.date(from: isoDate)
        XCTAssertEqual(result, expectedDate, "Parsed date should match expected date for GLOBAL timezone")
    }

    func testParseIso8601DateLocal() {
        let isoDate = "2023-09-11T10:15:30"
        let result = SwrveUtilsSwift.parseIso8601Date(isoDate, timezoneType: .LOCAL)
        XCTAssertNotNil(result, "The date should be parsed and not nil")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        if let localDate = dateFormatter.date(from: isoDate) {
            let secondsFromGMT = TimeZone.current.secondsFromGMT(for: localDate)
            let expectedDate = localDate.addingTimeInterval(TimeInterval(secondsFromGMT))
            XCTAssertEqual(result, expectedDate, "Parsed date should account for the local timezone offset")
        } else {
            XCTFail("testParseIso8601DateLocal fail")
        }
    }

    func testParseInvalidIsoDateGlobal() {
        var invalidIsoDate = "invalid-date"
        var result = SwrveUtilsSwift.parseIso8601Date(invalidIsoDate, timezoneType: .GLOBAL)
        XCTAssertNil(result, "The result should be nil for an invalid ISO date")

        invalidIsoDate = "2023-09-11T10:15:30"  // missing Z
        result = SwrveUtilsSwift.parseIso8601Date(invalidIsoDate, timezoneType: .GLOBAL)
        XCTAssertNil(result, "The result should be nil because SDK requires a utc date with Z at the end")

        invalidIsoDate = "2023-09-11T10:15:30+blah"  // incorrrect offset
        result = SwrveUtilsSwift.parseIso8601Date(invalidIsoDate, timezoneType: .GLOBAL)
        XCTAssertNil(result, "The result should be nil because we require a utc date with Z at the end")

    }

    func testParseInvalidIsoDateLocal() {
        var invalidIsoDate = "invalid-date"
        var result = SwrveUtilsSwift.parseIso8601Date(invalidIsoDate, timezoneType: .LOCAL)
        XCTAssertNil(result, "The result should be nil for an invalid ISO date")

        invalidIsoDate = "2023-09-11T10:15:30Z"  // with a Z
        result = SwrveUtilsSwift.parseIso8601Date(invalidIsoDate, timezoneType: .LOCAL)
        XCTAssertNil(result, "The result should be nil because SDK requires local date with no Z at the end")

        invalidIsoDate = "2023-09-11T10:15:30+0000"  // missing Z
        result = SwrveUtilsSwift.parseIso8601Date(invalidIsoDate, timezoneType: .LOCAL)
        XCTAssertNil(result, "The result should be nil because SDK requires local date with no offset at the end")
    }
}
