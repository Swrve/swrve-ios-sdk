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

    func testFormatPayloadForDisplayNil() {
        let result = SwrveUtilsSwift.formatPayloadForDisplay(nil)
        XCTAssertEqual(result, "nil", "Should return 'nil' for nil payload")
    }

    func testFormatPayloadForDisplayEmpty() {
        let result = SwrveUtilsSwift.formatPayloadForDisplay([:])
        XCTAssertEqual(result, "[]", "Should return empty brackets for empty dictionary")
    }

    func testFormatPayloadForDisplayStringAndNumber() {
        let payload: [AnyHashable: Any] = ["key": "value", "num": 123]
        let result = SwrveUtilsSwift.formatPayloadForDisplay(payload)
        // Order is sorted by key, so 'key' then 'num'
        XCTAssertEqual(result, "['key': 'value', 'num': 123]", "Should format string and number values correctly")
    }

    func testFormatPayloadForDisplayMixedKeyTypes() {
        let payload: [AnyHashable: Any] = ["a": 1, 2: "b"]
        let result = SwrveUtilsSwift.formatPayloadForDisplay(payload)
        // Sorted keys: 2, "a"
        XCTAssertEqual(result, "[2: 'b', 'a': 1]", "Should handle mixed key types and sort correctly")
    }

    func testFormatPayloadForDisplayBoolAndString() {
        let payload: [AnyHashable: Any] = ["flag": true, "desc": "on"]
        let result = SwrveUtilsSwift.formatPayloadForDisplay(payload)
        // Sorted keys: "desc", "flag"
        XCTAssertEqual(result, "['desc': 'on', 'flag': true]", "Should format bool and string values correctly")
    }
}
