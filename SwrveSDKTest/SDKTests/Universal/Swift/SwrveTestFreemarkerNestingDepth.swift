import XCTest

@testable import SwrveSDK

// MARK: - Deep nesting

class SwrveTestFreemarkerNestingDepth: XCTestCase {

    // MARK: - <#if> nesting

    func testThreeLevelIfNesting() throws {
        let template = """
            <#if a == "1"><#if b == "2"><#if c == "3">deep</#if></#if></#if>
            """
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["a": "1", "b": "2", "c": "3"])
        XCTAssertEqual(result, "deep")
    }

    func testFourLevelIfNesting() throws {
        let template = """
            <#if a == "1"><#if b == "2"><#if c == "3"><#if d == "4">deep</#if></#if></#if></#if>
            """
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["a": "1", "b": "2", "c": "3", "d": "4"])
        XCTAssertEqual(result, "deep")
    }

    func testThreeLevelIfNestingWithElseIf() throws {
        let template = """
            <#if a == "1"><#if b == "2"><#if c == "3">yes<#elseif c == "x">no</#if></#if></#if>
            """
        let result = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["a": "1", "b": "2", "c": "3"])
        XCTAssertEqual(result, "yes")
    }

    func testFourLevelIfNestingElseBranch() throws {
        let template = """
            <#if a == "1"><#if b == "2"><#if c == "3">ok<#else><#if d == "4">deep</#if></#if></#if></#if>
            """
        // then-branch: c matches, else not entered
        let thenResult = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["a": "1", "b": "2", "c": "3", "d": "4"])
        XCTAssertEqual(thenResult, "ok")
        // else-branch: c doesn't match, 4th-level <#if> inside else is actually executed
        let elseResult = try SwrveFreemarkerEvaluator.evaluate(template, properties: ["a": "1", "b": "2", "c": "x", "d": "4"])
        XCTAssertEqual(elseResult, "deep")
    }

    // MARK: - <#switch> nesting

    func testSwitchIfNesting() throws {
        let template = """
            <#switch Recipient.tier><#case "gold"><#if Recipient.balance?number gt 100>VIP<#else>Standard</#if><#break></#switch>
            """
        let result = try SwrveFreemarkerEvaluator.evaluate(
            template,
            properties: ["Recipient.tier": "gold", "Recipient.balance": "200"]
        )
        XCTAssertEqual(result, "VIP")
    }

    func testSwitchIfIfNesting() throws {
        let template = """
            <#switch Recipient.tier><#case "gold"><#if a == "1"><#if b == "2">deep</#if></#if><#break></#switch>
            """
        let result = try SwrveFreemarkerEvaluator.evaluate(
            template,
            properties: ["Recipient.tier": "gold", "a": "1", "b": "2"]
        )
        XCTAssertEqual(result, "deep")
    }

    func testSwitchIfIfIfNesting() throws {
        let template = """
            <#switch Recipient.tier><#case "gold"><#if a == "1"><#if b == "2"><#if c == "3">deep</#if></#if></#if><#break></#switch>
            """
        let result = try SwrveFreemarkerEvaluator.evaluate(
            template,
            properties: ["Recipient.tier": "gold", "a": "1", "b": "2", "c": "3"]
        )
        XCTAssertEqual(result, "deep")
    }
}
