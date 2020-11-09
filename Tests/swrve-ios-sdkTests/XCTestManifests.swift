import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(swrve_ios_sdkTests.allTests),
    ]
}
#endif
