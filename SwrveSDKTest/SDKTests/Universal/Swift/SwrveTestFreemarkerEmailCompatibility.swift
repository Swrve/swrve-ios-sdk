import XCTest

@testable import SwrveSDK

/// Validates FreeMarker expression compatibility using a real template and generated output from
/// Accelerator's Email channel. The template was extracted from a working Email campaign and the
/// expected output files represent what Accelerator produced for two property profiles.
///
/// These tests complement the conformance suite (SwrveTestFreemarkerConformance) which is more
/// comprehensive and was generated against the reference FreeMarker Java library.
class SwrveTestFreemarkerEmailCompatibility: XCTestCase {

    // All recipient properties present, including uppercase boolean "TRUE" as Email surfaces it.
    private let allProps: [String: String] = [
        "Recipient.FIRST_NAME": "  John  ",
        "Recipient.LOYALTY_POINTS": "1200",
        "Recipient.COUNTRY": "US",
        "Recipient.PROMO_CODE": "SAVE20",
        "Recipient.IS_PREMIUM": "TRUE"
            // Recipient.NONEXISTENT_PROP intentionally absent
    ]

    // Partial properties to exercise fallback and missing-property handling.
    private let missingProps: [String: String] = [
        "Recipient.FIRST_NAME": " Jane ",
        "Recipient.LOYALTY_POINTS": "850",
        "Recipient.COUNTRY": "UK"
            // Recipient.PROMO_CODE, IS_PREMIUM, NONEXISTENT_PROP intentionally absent
    ]

    func testEmailTemplateWithAllProperties() throws {
        let template = try readResource("freemarker_email_template")
        let expected = try readResource("freemarker_email_expected_all_props")
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: allProps)
        XCTAssertEqual(result, expected)
    }

    func testEmailTemplateWithMissingProperties() throws {
        let template = try readResource("freemarker_email_template")
        let expected = try readResource("freemarker_email_expected_missing_props")
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: missingProps)
        XCTAssertEqual(result, expected)
    }

    private func readResource(_ name: String) throws -> String {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: name, withExtension: "txt"),
            "\(name).txt not found in test bundle"
        )
        return try String(contentsOf: url, encoding: .utf8)
    }
}
