import XCTest

@testable import SwrveSDK

class SwrveTestFreemarkerValidateBareKey: XCTestCase {

    // MARK: - Parenthesised bare variable suppresses (validateBareKey)

    func testBareParenInterpolationSuppresses() {
        // ${(Recipient.name)} — grouping parens with no ! inside: key lookup would use "(Recipient.name)" literally
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate("${(Recipient.name)}", properties: ["Recipient.name": "Alice"])
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("parentheses"))
        }
    }

    func testBareParenDefaultInterpolationSuppresses() {
        // ${(Recipient.name)!"friend"} — bang is outside the parens, not inside: not the legitimate (key!"default") form
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                #"${(Recipient.name)!"friend"}"#,
                properties: ["Recipient.name": "Alice"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("parentheses"))
        }
    }

    func testBareParenExistsCheckSuppresses() {
        // <#if (Recipient.name)??>  — lookup would use "(Recipient.name)" literally, always missing
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if (Recipient.name)??>yes<#else>no</#if>",
                properties: ["Recipient.name": "Alice"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("parentheses"))
        }
    }

    func testBareParenSwitchExpressionSuppresses() {
        // <#switch (Recipient.tier)> — paren-containing key in switch expression; should suppress
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#switch (Recipient.tier)><#case \"gold\">Gold<#break><#default>Other</#switch>",
                properties: ["Recipient.tier": "gold"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("parentheses"))
        }
    }

    func testBareParenNumericEqualsSuppresses() {
        // Paren-containing key on ?number == path — must suppress (parity with gt/lt path)
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if (Recipient.x)?number == 10>yes</#if>",
                properties: ["Recipient.x": "10"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("parentheses"))
        }
    }

    func testBareParenNumericNotEqualsSuppresses() {
        XCTAssertThrowsError(
            try SwrveFreemarkerEvaluator.evaluate(
                "<#if (Recipient.x)?number != 10>yes</#if>",
                properties: ["Recipient.x": "10"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("parentheses"))
        }
    }

    // MARK: - Legitimate paren-default form must not be broken

    func testLegitimateParenDefaultStillWorks() throws {
        // (Recipient.name!"friend") — bang inside parens: the one legitimate form, must not be broken
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${(Recipient.name!"friend")}"#,
            properties: [:]
        )
        XCTAssertEqual(result, "friend")
    }

    func testLegitimateParenDefaultKeyPresentStillWorks() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${(Recipient.name!"friend")}"#,
            properties: ["Recipient.name": "Alice"]
        )
        XCTAssertEqual(result, "Alice")
    }

    // MARK: - Parens inside quoted default must not suppress

    func testParenInsideQuotedDefaultNotSuppressed() throws {
        // Parens are in the default *string*, not the key — validateBareKey must not fire
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.terms!"(see terms)"}"#,
            properties: [:]
        )
        XCTAssertEqual(result, "(see terms)")
    }

    func testParenInsideQuotedDefaultKeyPresentNotSuppressed() throws {
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"${Recipient.terms!"(see terms)"}"#,
            properties: ["Recipient.terms": "ok"]
        )
        XCTAssertEqual(result, "ok")
    }

    func testParenInsideConditionDefaultNotSuppressed() throws {
        // Default value containing parens used in a condition — must not suppress
        let result = try SwrveFreemarkerEvaluator.evaluate(
            #"<#if Recipient.label!"(n/a)" == "(n/a)">yes</#if>"#,
            properties: [:]
        )
        XCTAssertEqual(result, "yes")
    }
}
