import Foundation

// MARK: - FMEvaluator

final class FMEvaluator {
    private let properties: [String: String]
    private let useLocalTimezone: Bool

    init(_ properties: [String: String], useLocalTimezone: Bool) {
        self.properties = properties
        self.useLocalTimezone = useLocalTimezone
    }

    // Throw-vs-no-throw policy:
    // - ?? (exists check) and ! (default) are intentionally safe — they exist precisely to handle missing keys.
    // - Bare ${variable}, == / != conditions, and <#switch> expressions throw when the key is missing,
    //   suppressing the campaign. A template that references a key without a safety net is assumed to
    //   require that key to render correctly. Matches standard FreeMarker behaviour.
    func evaluate(_ nodes: [FMASTNode]) throws -> String {
        var result = ""
        for node in nodes {
            switch node {
            case .text(let s):
                result += s
            case .interpolation(let expr):
                result += try evaluateInterpolation(expr)
            case .ifStatement(let condition, let thenBody, let elseIfClauses, let elseBody):
                if try evaluateCondition(condition) {
                    result += try evaluate(thenBody)
                } else if let match = try elseIfClauses.first(where: { try evaluateCondition($0.0) }) {
                    result += try evaluate(match.1)
                } else {
                    result += try evaluate(elseBody)
                }

            case .switchStatement(let variable, let switchDefault, let transforms, let cases, let defaultBody):
                guard let raw = properties[variable] ?? switchDefault else {
                    throw FreemarkerError("Missing required property key in <#switch>: \(variable)")
                }
                let actual = applyTransforms(raw, transforms)
                if let start = cases.firstIndex(where: { actual == $0.value }) {
                    // Execute from the matching case, continuing into subsequent cases until <#break>
                    var broke = false
                    for i in start..<cases.count {
                        result += try evaluate(cases[i].body)
                        if cases[i].hasBreak {
                            broke = true
                            break
                        }
                    }
                    // If no <#break> was encountered, fall through to <#default>
                    if !broke {
                        result += try evaluate(defaultBody)
                    }
                } else {
                    // No matching case — execute <#default>
                    result += try evaluate(defaultBody)
                }
            }
        }
        return result
    }

    private func applyTransforms(_ value: String, _ transforms: [FMStringTransform]) -> String {
        transforms.reduce(value) { v, t in
            switch t {
            case .trim: return v.trimmingCharacters(in: .whitespacesAndNewlines)
            case .lowerCase: return v.lowercased(with: Locale(identifier: "en_US_POSIX"))
            case .upperCase: return v.uppercased(with: Locale(identifier: "en_US_POSIX"))
            }
        }
    }

    private func evaluateInterpolation(_ expr: FMInterpolationExpr) throws -> String {
        switch expr {
        case .variable(let key, let transforms):
            guard let value = properties[key] else {
                throw FreemarkerError("Missing required property key: \(key)")
            }
            return applyTransforms(value, transforms)
        case .withDefault(let key, let transforms, let defaultValue):
            guard let value = properties[key] else {
                if !transforms.isEmpty { throw FreemarkerError("Missing required property key: \(key)") }
                return defaultValue
            }
            return applyTransforms(value, transforms)
        case .parenDefaultWithTransform(let key, let transforms, let defaultValue):
            let value = properties[key] ?? defaultValue
            return applyTransforms(value, transforms)
        case .concat(let parts):
            var result = ""
            for part in parts {
                switch part {
                case .literal(let s): result += s
                case .variable(let key, let transforms):
                    guard let value = properties[key] else {
                        throw FreemarkerError("Missing required property key in concatenation: \(key)")
                    }
                    result += applyTransforms(value, transforms)
                case .parenDefault(let key, let transforms, let defaultValue):
                    let raw = properties[key] ?? defaultValue
                    result += applyTransforms(raw, transforms)
                }
            }
            return result
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func evaluateCondition(_ condition: FMConditionExpr) throws -> Bool {
        switch condition {
        case .exists(let key):
            return properties[key] != nil
        case .equals(let key, let transforms, let value):
            guard let raw = properties[key] else {
                throw FreemarkerError("Missing property key in == condition: \(key)")
            }
            return applyTransforms(raw, transforms) == value
        case .equalsWithDefault(let key, let defaultValue, let transforms, let value, let parenDefault):
            let raw: String
            if let found = properties[key] {
                raw = found
            } else if !parenDefault && !transforms.isEmpty {
                throw FreemarkerError("Missing property key in == condition: \(key)")
            } else {
                raw = defaultValue
            }
            return applyTransforms(raw, transforms) == value
        case .notEquals(let key, let transforms, let value):
            guard let raw = properties[key] else {
                throw FreemarkerError("Missing property key in != condition: \(key)")
            }
            return applyTransforms(raw, transforms) != value
        case .notEqualsWithDefault(let key, let defaultValue, let transforms, let value, let parenDefault):
            let raw: String
            if let found = properties[key] {
                raw = found
            } else if !parenDefault && !transforms.isEmpty {
                throw FreemarkerError("Missing property key in != condition: \(key)")
            } else {
                raw = defaultValue
            }
            return applyTransforms(raw, transforms) != value
        case .numericCompare(let key, let op, let rhs, let transforms):
            guard let raw = properties[key] else {
                throw FreemarkerError("Missing property key in numeric comparison: \(key)")
            }
            let prepared = applyTransforms(raw, transforms).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let lhs = Double(prepared) else {
                throw FreemarkerError("?number: cannot parse '\(prepared)' as a number for key: \(key)")
            }
            if lhs.isNaN || lhs.isInfinite {
                throw FreemarkerError("?number: '\(prepared)' is not a finite number for key: \(key)")
            }
            switch op {
            case .greaterThan: return lhs > rhs
            case .greaterThanOrEqual: return lhs >= rhs
            case .lessThan: return lhs < rhs
            case .lessThanOrEqual: return lhs <= rhs
            case .equals: return lhs == rhs
            case .notEquals: return lhs != rhs
            }
        case .numericCompareWithDefault(let key, let transforms, let defaultValue, let op, let rhs):
            let raw = properties[key] ?? defaultValue
            let prepared = applyTransforms(raw, transforms).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let lhs = Double(prepared) else {
                throw FreemarkerError("?number: cannot parse '\(prepared)' as a number for key: \(key)")
            }
            if lhs.isNaN || lhs.isInfinite {
                throw FreemarkerError("?number: '\(prepared)' is not a finite number for key: \(key)")
            }
            switch op {
            case .greaterThan: return lhs > rhs
            case .greaterThanOrEqual: return lhs >= rhs
            case .lessThan: return lhs < rhs
            case .lessThanOrEqual: return lhs <= rhs
            case .equals: return lhs == rhs
            case .notEquals: return lhs != rhs
            }
        case .booleanValue(let key, let transforms):
            guard let raw = properties[key] else {
                throw FreemarkerError("Missing property key in ?boolean condition: \(key)")
            }
            let effective = applyTransforms(raw, transforms)
            switch effective.lowercased(with: Locale(identifier: "en_US_POSIX")) {
            case "true": return true
            case "false": return false
            default: throw FreemarkerError("?boolean: '\(effective)' is not a valid boolean for key: \(key). Only 'true' or 'false' are accepted.")
            }
        case .booleanValueWithDefault(let key, let transforms, let defaultValue):
            let raw = properties[key] ?? defaultValue
            let effective = applyTransforms(raw, transforms)
            switch effective.lowercased(with: Locale(identifier: "en_US_POSIX")) {
            case "true": return true
            case "false": return false
            default: throw FreemarkerError("?boolean: '\(effective)' is not a valid boolean for key: \(key). Only 'true' or 'false' are accepted.")
            }
        case .hasContent(let key, let transforms):
            guard let value = properties[key] else {
                if !transforms.isEmpty { throw FreemarkerError("Missing property key in ?has_content: \(key)") }
                return false
            }
            return !applyTransforms(value, transforms).isEmpty
        case .hasContentWithDefault(let key, let transforms, let defaultValue):
            let raw = properties[key] ?? defaultValue
            return !applyTransforms(raw, transforms).isEmpty
        case .dateCompare(let lhsExpr, let op, let rhsExpr):
            let lhs = try evaluateFMDateExpr(lhsExpr)
            let rhs = try evaluateFMDateExpr(rhsExpr)
            return try compareDateValues(lhs, op: op, rhs: rhs)
        case .not(let inner):
            return try !evaluateCondition(inner)
        case .and(let left, let right):
            // Short-circuit: if left is false, right is not evaluated
            guard try evaluateCondition(left) else { return false }
            return try evaluateCondition(right)
        case .or(let left, let right):
            // Short-circuit: if left is true, right is not evaluated
            if try evaluateCondition(left) { return true }
            return try evaluateCondition(right)
        }
    }
}

// MARK: - FMEvaluator date helpers

extension FMEvaluator {

    // LOCAL uses `Calendar.current.timeZone` (the device timezone) rather than `TimeZone.current`:
    // both are the device zone in production, but `Calendar.current.timeZone` honours an overridden
    // process default timezone (`NSTimeZone.default`) — which `TimeZone.current` does not — so the
    // LOCAL path is deterministically testable, matching how `SwrveCampaign.secondsSinceMidnight` does
    // its LOCAL date math. GLOBAL pins UTC; ?? .current is an unreachable compile-time fallback for
    // older SDKs that type TimeZone(secondsFromGMT:) as optional.
    fileprivate var timezone: TimeZone { useLocalTimezone ? Calendar.current.timeZone : TimeZone(secondsFromGMT: 0) ?? .current }

    fileprivate func evaluateFMDateExpr(_ expr: FMDateExpr) throws -> FMDateValue {
        switch expr {
        case .property(let variable, let kind):
            guard let raw = properties[variable] else {
                throw FreemarkerError("Missing property key in date comparison: \(variable)")
            }
            return try parseDateString(raw, kind: kind, key: variable)
        case .propertyWithDefault(let variable, let defaultValue, let kind):
            let raw = properties[variable] ?? defaultValue
            return try parseDateString(raw, kind: kind, key: variable)
        case .now(let kind):
            let now = SwrveFreemarkerEvaluator.nowProvider()
            switch kind {
            case .date, .strictDate:
                return .calendarDate(try calendarDate(from: now))
            case .dateTime:
                return .dateTime(now)
            }
        }
    }

    fileprivate func parseDateString(_ s: String, kind: FMDateKind, key: String) throws -> FMDateValue {
        // ISO 8601 datetimes have 'T' at position 10 (YYYY-MM-DDTxx). Using a positional check
        // avoids false positives from property values that merely contain the letter T.
        let isFullDatetime = s.count >= 11 && s[s.index(s.startIndex, offsetBy: 10)] == "T"
        switch kind {
        case .date:
            if isFullDatetime {
                guard let date = parseISO8601Datetime(s) else {
                    throw FreemarkerError("?date: cannot parse '\(s)' as ISO 8601 date or datetime for key: \(key)")
                }
                return .calendarDate(try calendarDate(from: date))
            } else {
                guard let date = parseISO8601DateOnly(s) else {
                    throw FreemarkerError("?date: cannot parse '\(s)' as ISO 8601 date for key: \(key)")
                }
                return .calendarDate(try calendarDate(from: date))
            }
        case .dateTime:
            guard isFullDatetime, let date = parseISO8601Datetime(s) else {
                throw FreemarkerError("?datetime: '\(s)' is not a full ISO 8601 datetime for key: \(key). Date-only strings are not accepted.")
            }
            return .dateTime(date)
        case .strictDate:
            guard isFullDatetime, let date = parseISO8601Datetime(s) else {
                throw FreemarkerError("?datetime?date: '\(s)' is not a full ISO 8601 datetime for key: \(key).")
            }
            return .calendarDate(try calendarDate(from: date))
        }
    }

    fileprivate func calendarDate(from date: Date) throws -> FMCalendarDate {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month, let day = comps.day else {
            throw FreemarkerError("Internal error: failed to extract date components from date value")
        }
        return FMCalendarDate(year: year, month: month, day: day)
    }

    fileprivate func compareDateValues(_ lhs: FMDateValue, op: FMNumericOp, rhs: FMDateValue) throws -> Bool {
        switch (lhs, rhs) {
        case (.calendarDate(let a), .calendarDate(let b)):
            switch op {
            case .greaterThan: return a > b
            case .greaterThanOrEqual: return a >= b
            case .lessThan: return a < b
            case .lessThanOrEqual: return a <= b
            case .equals, .notEquals: throw FreemarkerError("== / != is not supported for date comparisons")
            }
        case (.dateTime(let a), .dateTime(let b)):
            switch op {
            case .greaterThan: return a > b
            case .greaterThanOrEqual: return a >= b
            case .lessThan: return a < b
            case .lessThanOrEqual: return a <= b
            case .equals, .notEquals: throw FreemarkerError("== / != is not supported for date comparisons")
            }
        default:
            throw FreemarkerError(
                "Type mismatch: cannot compare ?date and ?datetime — use .now?date to compare against a ?date expression, or .now against a ?datetime expression"
            )
        }
    }

    fileprivate func parseISO8601Datetime(_ s: String) -> Date? {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fmt.date(from: s) { return date }
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: s)
    }

    fileprivate func parseISO8601DateOnly(_ s: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.timeZone = timezone
        return fmt.date(from: s)
    }
}
