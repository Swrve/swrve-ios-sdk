import XCTest

@testable import SwrveSDK

// MARK: - ?trim

class SwrveTestFreemarkerTrimHasContent: XCTestCase {

    func testTrimStripsWhitespace() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "  Alice  "])
        XCTAssertEqual(result, "Alice")
    }

    func testTrimLeadingOnly() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "  Bob"])
        XCTAssertEqual(result, "Bob")
    }

    func testTrimTrailingOnly() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "Carol  "])
        XCTAssertEqual(result, "Carol")
    }

    func testTrimNoWhitespaceUnchanged() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "Dave"])
        XCTAssertEqual(result, "Dave")
    }

    func testTrimMissingKeySuppresses() {
        XCTAssertThrowsError(try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: [:]))
    }

    func testTrimWhitespaceOnlyBecomesEmpty() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "   "])
        XCTAssertEqual(result, "")
    }

    func testTrimStripsNewlines() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "\n  Alice  \n"])
        XCTAssertEqual(result, "Alice")
    }

    func testTrimStripsCRLF() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "\r\n  Bob  \r\n"])
        XCTAssertEqual(result, "Bob")
    }

    func testTrimNewlineOnlyBecomesEmpty() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?trim}", properties: ["Recipient.name": "\n\r\n"])
        XCTAssertEqual(result, "")
    }
}

// MARK: - ?has_content

extension SwrveTestFreemarkerTrimHasContent {

    func testHasContentKeyPresentNonEmpty() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.name?has_content>Hello ${Recipient.name}<#else>Hello there</#if>",
            properties: ["Recipient.name": "Alice"]
        )
        XCTAssertEqual(result, "Hello Alice")
    }

    func testHasContentKeyPresentEmpty() throws {
        // Key exists but value is empty string — ?has_content is false
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.name?has_content>Hi<#else>No name</#if>",
            properties: ["Recipient.name": ""]
        )
        XCTAssertEqual(result, "No name")
    }

    func testHasContentKeyMissing() throws {
        // Missing key — ?has_content is false (does not suppress)
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.name?has_content>Hi<#else>No name</#if>",
            properties: [:]
        )
        XCTAssertEqual(result, "No name")
    }

    func testHasContentNegated() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if !Recipient.name?has_content>No name<#else>Has name</#if>",
            properties: [:]
        )
        XCTAssertEqual(result, "No name")
    }

    func testHasContentDistinctFromExistsOnEmptyString() throws {
        // ?? is true when key exists even if empty; ?has_content is false
        let properties: [String: Any] = ["Recipient.name": ""]
        let existsResult = try SwrveFreemarkerEvaluator.evaluate("<#if Recipient.name??>exists</#if>", properties: properties)
        let hasContentResult = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.name?has_content>non-empty</#if>", properties: properties)
        XCTAssertEqual(existsResult, "exists")
        XCTAssertEqual(hasContentResult, "")
    }

    func testHasContentInInterpolationSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate("${Recipient.name?has_content}", properties: ["Recipient.name": "Alice"]))
    }
}

// MARK: - ?trim?has_content chain

extension SwrveTestFreemarkerTrimHasContent {

    func testTrimHasContentWhitespaceOnlyIsFalse() throws {
        // ?trim?has_content — whitespace-only string treated as empty
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.name?trim?has_content>Hi ${Recipient.name?trim}<#else>Hi there</#if>",
            properties: ["Recipient.name": "   "]
        )
        XCTAssertEqual(result, "Hi there")
    }

    func testTrimHasContentNonEmptyAfterTrim() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.name?trim?has_content>Hi ${Recipient.name?trim}<#else>Hi there</#if>",
            properties: ["Recipient.name": "  Alice  "]
        )
        XCTAssertEqual(result, "Hi Alice")
    }

    func testTrimHasContentMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.name?trim?has_content>Hi<#else>No name</#if>",
                properties: [:]
            )
        )
    }
}

// MARK: - ?trim in equality conditions

extension SwrveTestFreemarkerTrimHasContent {

    func testTrimEqualsMatchAfterTrim() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country?trim == "US">Domestic<#else>International</#if>"#,
            properties: ["Recipient.country": "  US  "]
        )
        XCTAssertEqual(result, "Domestic")
    }

    func testTrimEqualsNoMatchAfterTrim() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country?trim == "US">Domestic<#else>International</#if>"#,
            properties: ["Recipient.country": "  UK  "]
        )
        XCTAssertEqual(result, "International")
    }

    func testTrimEqualsNoWhitespaceBehavesNormally() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country?trim == "US">Domestic<#else>International</#if>"#,
            properties: ["Recipient.country": "US"]
        )
        XCTAssertEqual(result, "Domestic")
    }

    func testTrimNotEqualsMatchAfterTrim() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country?trim != "US">International<#else>Domestic</#if>"#,
            properties: ["Recipient.country": "  UK  "]
        )
        XCTAssertEqual(result, "International")
    }

    func testTrimEqualsMissingKeySuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"<#if Recipient.country?trim == "US">Domestic</#if>"#,
                properties: [:]
            ))
    }
}

// MARK: - ?trim?number chain

extension SwrveTestFreemarkerTrimHasContent {

    func testTrimNumberStripsBeforeParsing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?trim?number gt 100>Eligible<#else>Not eligible</#if>",
            properties: ["Recipient.balance": "  150  "]
        )
        XCTAssertEqual(result, "Eligible")
    }

    func testTrimNumberNoWhitespaceBehavesNormally() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?trim?number gte 100>Eligible<#else>Not eligible</#if>",
            properties: ["Recipient.balance": "100"]
        )
        XCTAssertEqual(result, "Eligible")
    }

    func testTrimNumberStripsNewlineBeforeParsing() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.balance?trim?number gt 100>Eligible<#else>Not eligible</#if>",
            properties: ["Recipient.balance": "\n150\n"]
        )
        XCTAssertEqual(result, "Eligible")
    }

    func testTrimNumberNonParsableAfterTrimSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if Recipient.balance?trim?number gt 100>A</#if>",
                properties: ["Recipient.balance": "  not_a_number  "]
            ))
    }
}

// MARK: - ?trim!"default" chain

extension SwrveTestFreemarkerTrimHasContent {

    func testTrimDefaultKeyPresentTrimsValue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"Hello ${Recipient.name?trim!"there"}"#,
            properties: ["Recipient.name": "  Alice  "]
        )
        XCTAssertEqual(result, "Hello Alice")
    }

    func testTrimDefaultKeyMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"Hello ${Recipient.name?trim!"there"}"#,
                properties: [:]
            )
        )
    }

    func testTrimDefaultDoesNotTriggerOnEmptyString() throws {
        // ! only triggers on missing key — empty string is returned as-is (after trim)
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.name?trim!"fallback"}"#,
            properties: ["Recipient.name": ""]
        )
        XCTAssertEqual(result, "")
    }

    func testTrimDefaultSingleQuotedKeyMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "Hello ${Recipient.name?trim!'there'}",
                properties: [:]
            )
        )
    }
}

// MARK: - ?lower_case / ?upper_case in conditions

class SwrveTestFreemarkerStringTransformConditionals: XCTestCase {

    func testLowerCaseBooleanChainTrue() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?lower_case?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": "TRUE"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testLowerCaseBooleanChainFalse() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?lower_case?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": "FALSE"]
        )
        XCTAssertEqual(result, "no")
    }

    func testUpperCaseBooleanChain() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?upper_case?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": "true"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testTrimLowerCaseBooleanChain() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?trim?lower_case?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": "  TRUE  "]
        )
        XCTAssertEqual(result, "yes")
    }

    func testLowerCaseTrimBooleanChain() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.flag?lower_case?trim?boolean>yes<#else>no</#if>",
            properties: ["Recipient.flag": "  TRUE  "]
        )
        XCTAssertEqual(result, "yes")
    }

    func testLowerCaseHasContentChain() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "<#if Recipient.name?lower_case?has_content>yes<#else>no</#if>",
            properties: ["Recipient.name": "ALICE"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testUpperCaseEqualsChain() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.country?upper_case == "US">yes<#else>no</#if>"#,
            properties: ["Recipient.country": "us"]
        )
        XCTAssertEqual(result, "yes")
    }

    func testLowerCaseEqualsChain() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.tier?lower_case == "gold">Gold<#else>Other</#if>"#,
            properties: ["Recipient.tier": "GOLD"]
        )
        XCTAssertEqual(result, "Gold")
    }
}

// MARK: - ?lower_case / ?upper_case in ${} interpolation

class SwrveTestFreemarkerCaseTransform: XCTestCase {

    func testLowerCaseInterpolation() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.country?lower_case}",
            properties: ["Recipient.country": "US"]
        )
        XCTAssertEqual(result, "us")
    }

    func testUpperCaseInterpolation() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.country?upper_case}",
            properties: ["Recipient.country": "us"]
        )
        XCTAssertEqual(result, "US")
    }

    func testLowerCaseWithDefaultKeyMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"${Recipient.country?lower_case!"unknown"}"#,
                properties: [:]
            )
        )
    }

    func testTrimLowerCaseChainInterpolation() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.status?trim?lower_case}",
            properties: ["Recipient.status": "  ACTIVE  "]
        )
        XCTAssertEqual(result, "active")
    }

    func testLowerCaseTrimChainInterpolation() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            "${Recipient.status?lower_case?trim}",
            properties: ["Recipient.status": "  ACTIVE  "]
        )
        XCTAssertEqual(result, "active")
    }

    func testUpperCaseWithDefaultKeyMissingSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"${Recipient.tier?upper_case!"UNKNOWN"}"#,
                properties: [:]
            )
        )
    }
}
