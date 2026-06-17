import Foundation

/// Evaluates a FreeMarker template subset against a set of user properties.
///
/// **Pipeline**
/// ```
///  template string
///       │
///       ▼
///  FMTokenizer  ──────────────────────  SwrveFreemarkerTokenizer.swift
///  scans for <#…>, </#…>, ${…}
///       │  [FMToken]
///       ▼
///  FMParser  ─────────────────────────  SwrveFreemarkerParser.swift
///  recursive descent → AST               built-ins: SwrveFreemarkerBuiltins.swift
///       │  [FMASTNode]
///       ▼
///  FMEvaluator  ──────────────────────  SwrveFreemarkerEvaluatorImpl.swift
///  walks AST, resolves against properties
///       │
///       ▼
///  rendered string
/// ```
///
/// Shared types (`FMToken`, `FMASTNode`, `FMConditionExpr`, etc.) are defined in this file; date-related types (`FMDateExpr`, `FMCalendarDate`, etc.) are defined in `SwrveFreemarkerBuiltins.swift`.
///
/// **Supported directives:** `<#if>` / `<#elseif>` / `<#else>` / `</#if>`, `<#switch>` / `<#case>` / `<#default>` / `<#break>` / `</#switch>`
/// **Supported interpolations:** `${Recipient.x}`, `${Recipient.x!"default"}`, `${Recipient.x?trim}`, `${Recipient.x?lower_case}`, `${Recipient.x?upper_case}`, `${Recipient.x?trim?lower_case!"default"}` (transforms apply only when key exists; default is returned as-is); `${"literal" + Recipient.x?lower_case + "literal"}` (string concatenation with `+`, `?trim`/`?lower_case`/`?upper_case` allowed on variables); `?has_content` is condition-only and not valid in interpolation
/// **Supported condition operators:** `==`, `!=` (string or numeric — `?number == 10`, `?number != 0`), `??` (exists check), `gt`, `gte`, `lt`, `lte` (numeric and date), `!` (negation), `&&`, `||`
/// **Supported built-ins:** `?number`, `?boolean`, `?trim`, `?lower_case`, `?upper_case`, `?has_content`, `?date`, `?datetime`; chains e.g. `?trim?lower_case?boolean`, `?lower_case?has_content`, `?datetime?date`
/// **Parenthesised default in conditions:** `(key!"default")?boolean`, `(key!"default")?number gte N`, `(key!"default")?date gte .now?date`, `(key!"default")?has_content`
/// **`<#switch>` default:** `<#switch Recipient.tier!"bronze">` falls back to `"bronze"` when key is absent
/// **Concatenation:** `${a+b}` and `${a + b}` are both valid (spaces around `+` are optional)
/// **Special variables:** `.now` (current datetime), `.now?date` (current calendar date)
@objc public class SwrveFreemarkerEvaluator: NSObject {

    /// Injectable time provider for unit tests. Not part of the public API.
    static var nowProvider: () -> Date = { Date() }

    /// Evaluate a FreeMarker template against the given properties using UTC for date comparisons.
    ///
    /// - Parameters:
    ///   - templateString: The template string potentially containing FreeMarker directives. Nil is treated as a missing template and throws.
    ///   - properties: A dictionary of property values. `NSString` values pass through as-is; `NSNumber` values are converted via `stringValue`; all other types are silently dropped.
    /// - Returns: The evaluated string.
    /// - Throws: When the template is nil or malformed (unclosed tags, unsupported directives,
    ///   missing required keys, or type mismatches). The campaign should be suppressed on error.
    @objc public static func evaluate(_ templateString: String?, properties: [String: Any]) throws -> String {
        try evaluate(templateString, properties: properties, useLocalTimezone: false)
    }

    /// Evaluate a FreeMarker template with explicit timezone context for date comparisons.
    ///
    /// - Parameters:
    ///   - templateString: The template string potentially containing FreeMarker directives.
    ///   - properties: A dictionary of property values.
    ///   - useLocalTimezone: Pass `true` for `LOCAL` timezone (device), `false` for `GLOBAL` (UTC).
    @objc public static func evaluate(
        _ templateString: String?,
        properties: [String: Any],
        useLocalTimezone: Bool
    ) throws -> String {
        guard let templateString else {
            throw FreemarkerError("Missing template string")
        }
        let stringProperties = properties.compactMapValues { value -> String? in
            if let s = value as? String { return s }
            if let n = value as? NSNumber {
                // Distinguish Bool from numeric NSNumber — Bool bridges to NSNumber as __NSCFBoolean
                if CFGetTypeID(n) == CFBooleanGetTypeID() { return n.boolValue ? "true" : "false" }
                return n.stringValue
            }
            return nil
        }
        let tokens = try FMTokenizer(templateString).tokenize()
        let nodes = try FMParser(tokens).parse()
        return try FMEvaluator(stringProperties, useLocalTimezone: useLocalTimezone).evaluate(nodes)
    }
}

// MARK: - Error

struct FreemarkerError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
    init(_ message: String) { self.message = message }
}

// MARK: - FMStringTransform

enum FMStringTransform {
    case trim, lowerCase, upperCase
}

// MARK: - FMTokens

enum FMToken {
    case text(String)
    case ifDirective(condition: String)
    case elseIfDirective(condition: String)
    case elseDirective
    case endIf
    case interpolation(String)
    case switchDirective(expr: String)
    case caseDirective(value: String)
    case defaultDirective
    case breakDirective
    case endSwitch
}

// MARK: - AST (Abstract Syntax Tree)

struct FMSwitchCase {
    let value: String
    let body: [FMASTNode]
    let hasBreak: Bool
}

indirect enum FMASTNode {
    case text(String)
    case interpolation(FMInterpolationExpr)
    case ifStatement(condition: FMConditionExpr, thenBody: [FMASTNode], elseIfClauses: [(FMConditionExpr, [FMASTNode])], elseBody: [FMASTNode])
    case switchStatement(variable: String, switchDefault: String?, transforms: [FMStringTransform], cases: [FMSwitchCase], defaultBody: [FMASTNode])
}

enum FMNumericOp {
    case greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, equals, notEquals
}

indirect enum FMConditionExpr {
    case exists(String)
    case equals(String, [FMStringTransform], String)  // variable, transforms, literal
    case equalsWithDefault(String, String, [FMStringTransform], String, Bool)  // variable, default, transforms, literal, parenDefault
    case notEquals(String, [FMStringTransform], String)  // variable, transforms, literal
    case notEqualsWithDefault(String, String, [FMStringTransform], String, Bool)  // variable, default, transforms, literal, parenDefault
    case numericCompare(String, FMNumericOp, Double, [FMStringTransform])  // variable, op, literal, transforms
    case numericCompareWithDefault(String, [FMStringTransform], String, FMNumericOp, Double)  // variable, transforms, default, op, rhs
    case booleanValue(String, [FMStringTransform])  // variable?transforms?boolean
    case booleanValueWithDefault(String, [FMStringTransform], String)  // variable, transforms, default
    case hasContent(String, [FMStringTransform])  // variable?transforms?has_content
    case hasContentWithDefault(String, [FMStringTransform], String)  // variable, transforms, default
    case dateCompare(FMDateExpr, FMNumericOp, FMDateExpr)  // lhs?date op rhs?date, etc.
    case not(FMConditionExpr)  // !condition
    case and(FMConditionExpr, FMConditionExpr)  // left && right
    case or(FMConditionExpr, FMConditionExpr)  // left || right
}

enum FMInterpolationExpr {
    case variable(String, [FMStringTransform])
    case withDefault(String, [FMStringTransform], String)
    case parenDefaultWithTransform(String, [FMStringTransform], String)  // (key!"default")?transforms* — transforms apply to both value and fallback
    case concat([FMConcatPart])  // "literal" + variable + ...
}

enum FMConcatPart {
    case literal(String)
    case variable(String, [FMStringTransform])
    case parenDefault(String, [FMStringTransform], String)  // (key!"default")?transforms* — transforms apply to both value and fallback
}
