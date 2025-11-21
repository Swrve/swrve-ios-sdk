import XCTest

class SwrveTestABTestDetails: XCTestCase {

    func testABTestDetails() {
        let config = SwrveConfig()
        config.abTestDetailsEnabled = true

        guard let swrve = SwrveTestHelper.initializeSwrve(withCampaignsFile: "abTestDetails", andConfig: config) else {
            XCTFail("Failed to initialize Swrve")
            return
        }

        // Assert it has the loaded AB Test Details
        guard let abTestDetails = swrve.resourceManager?.abTestDetails() else {
            XCTFail("AB Test Details are nil")
            return
        }

        XCTAssertEqual(abTestDetails.count, 2)

        for details in abTestDetails {
            if details.name == "AB test Name 1" {
                XCTAssertEqual(details.id, "12")
                XCTAssertEqual(details.caseIndex, 1)
            } else if details.name == "AB test Name 2" {
                XCTAssertEqual(details.id, "13")
                XCTAssertEqual(details.caseIndex, 4)
            } else {
                XCTFail("Unexpected Name")
            }
        }
    }
}
