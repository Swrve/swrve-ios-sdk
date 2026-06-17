import XCTest

@testable import SwrveSDK

// MARK: - Optional whitespace around == and != operators

class SwrveTestFreemarkerOperatorSpacing: XCTestCase {

    func testEqualsNoSpaces() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country=="UK">Match<#else>No match</#if>"#,
            properties: ["Recipient.country": "UK"]
        )
        XCTAssertEqual(result, "Match")
    }

    func testEqualsNoSpacesNonMatch() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country=="UK">Match<#else>No match</#if>"#,
            properties: ["Recipient.country": "US"]
        )
        XCTAssertEqual(result, "No match")
    }

    func testNotEqualsNoSpaces() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country!="UK">Not UK<#else>UK</#if>"#,
            properties: ["Recipient.country": "US"]
        )
        XCTAssertEqual(result, "Not UK")
    }

    func testEqualsLeadingSpaceOnly() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country =="UK">Match</#if>"#,
            properties: ["Recipient.country": "UK"]
        )
        XCTAssertEqual(result, "Match")
    }

    func testEqualsTrailingSpaceOnly() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country== "UK">Match</#if>"#,
            properties: ["Recipient.country": "UK"]
        )
        XCTAssertEqual(result, "Match")
    }

    func testEqualsNoSpacesWithTrim() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.name?trim=="Alice">Match<#else>No match</#if>"#,
            properties: ["Recipient.name": "  Alice  "]
        )
        XCTAssertEqual(result, "Match")
    }
}
