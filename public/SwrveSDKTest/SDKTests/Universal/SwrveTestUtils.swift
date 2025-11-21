import XCTest

class SwrveTestUtils: XCTestCase {

    func testGetStringFromDic() {
        let dicWithString: [String: Any] = ["value": "123"]
        let dicWithNumber: [String: Any] = ["value": 123]

        XCTAssertEqual(SwrveUtils.getStringFromDic(dicWithString, withKey: "value"), "123")
        XCTAssertEqual(SwrveUtils.getStringFromDic(dicWithNumber, withKey: "value"), "123")
    }

    func testIDFAValid() {
        XCTAssertFalse(SwrveUtils.isValidIDFA(nil))
        XCTAssertFalse(SwrveUtils.isValidIDFA(""))
        XCTAssertFalse(SwrveUtils.isValidIDFA("-------"))
        XCTAssertFalse(SwrveUtils.isValidIDFA("0000000"))
        XCTAssertFalse(SwrveUtils.isValidIDFA("0-0-"))
        XCTAssertFalse(SwrveUtils.isValidIDFA("-0-0-"))
        XCTAssertFalse(SwrveUtils.isValidIDFA("---00"))
        XCTAssertFalse(SwrveUtils.isValidIDFA("00---"))

        // length check for IDFA is > 0
        XCTAssertTrue(SwrveUtils.isValidIDFA("12345-0000"))
    }

    func testSha1() {
        let url = "https://www.url.fake/image.png"
        guard let data = url.data(using: .utf8) else {
            XCTFail("Failed to create data from URL string")
            return
        }
        XCTAssertEqual(SwrveUtils.sha1(data), "52712a2126ee461a792bef8fbf29cec68fdf1225")
    }

    // swiftlint:disable force_cast
    func testCombineDictionary() {
        let dictionary1: [String: String] = ["key1": "replace_me", "key2": "value2"]
        let dictionary2: [String: String] = ["key1": "value1", "key3": "value3"]

        var combinedDictionary = SwrveUtils.combineDictionary(dictionary1, with: dictionary2) as? [String: String]
        let expectedDictionary: [String: String] = ["key1": "value1", "key2": "value2", "key3": "value3"]
        XCTAssertEqual(combinedDictionary, expectedDictionary)

        combinedDictionary = SwrveUtils.combineDictionary(nil, with: dictionary2) as? [String: String]
        XCTAssertEqual(combinedDictionary, dictionary2)

        combinedDictionary = SwrveUtils.combineDictionary(dictionary1, with: nil) as? [String: String]
        XCTAssertEqual(combinedDictionary, dictionary1)

        // Ensure it won't crash
        combinedDictionary = SwrveUtils.combineDictionary(nil, with: nil) as? [String: String]
        XCTAssertEqual(combinedDictionary, [:])
    }
    // swiftlint:enable force_cast
}
