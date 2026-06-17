import Foundation

// MARK: - FMTokenizer

final class FMTokenizer {
    private let input: String

    init(_ input: String) { self.input = input }

    // Returns true when the character at `start` is preceded only by spaces/tabs back to the
    // start of its line (or to the start of the input). When true, the trailing newline after the
    // directive close is stripped — mirroring FreeMarker's directive-only-line whitespace rule.
    private func isDirectiveOnOwnLine(from start: String.Index) -> Bool {
        var i = start
        while i > input.startIndex {
            i = input.index(before: i)
            let c = input[i]
            if c == "\n" || c == "\r" { return true }
            if c != " " && c != "\t" { return false }
        }
        return true
    }

    private func skipLineBreak(remaining: inout Substring, directiveStart: String.Index) {
        guard isDirectiveOnOwnLine(from: directiveStart) else { return }
        if remaining.hasPrefix("\r\n") {
            remaining = remaining.dropFirst()  // \r\n is one grapheme cluster in Swift
        } else if remaining.first == "\n" || remaining.first == "\r" {
            remaining = remaining.dropFirst()
        }
    }

    /// Returns the range of the first `}` that is not inside a single- or double-quoted string.
    private func findClosingBrace(in s: Substring) -> Range<Substring.Index>? {
        var inQuotes = false
        var quoteChar: Character = "\""
        var i = s.startIndex
        while i < s.endIndex {
            let c = s[i]
            if inQuotes {
                if c == quoteChar { inQuotes = false }
            } else if c == "\"" || c == "'" {
                inQuotes = true
                quoteChar = c
            } else if c == "}" {
                return i..<s.index(after: i)
            }
            i = s.index(after: i)
        }
        return nil
    }

    /// Returns the range of the first `>` that is not inside a single- or double-quoted string.
    private func findClosingAngle(in s: Substring) -> Range<Substring.Index>? {
        var inQuotes = false
        var quoteChar: Character = "\""
        var i = s.startIndex
        while i < s.endIndex {
            let c = s[i]
            if inQuotes {
                if c == quoteChar { inQuotes = false }
            } else if c == "\"" || c == "'" {
                inQuotes = true
                quoteChar = c
            } else if c == ">" {
                return i..<s.index(after: i)
            }
            i = s.index(after: i)
        }
        return nil
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func tokenize() throws -> [FMToken] {
        var tokens: [FMToken] = []
        var remaining = input[input.startIndex...]

        while !remaining.isEmpty {
            // </#  is checked before <# because both are distinct prefixes — this is just conventional ordering (closing before opening).
            if remaining.hasPrefix("</#") {
                let directiveStart = remaining.startIndex
                guard let end = findClosingAngle(in: remaining) else {
                    throw FreemarkerError("Unclosed closing directive")
                }
                let inner = String(remaining[remaining.index(remaining.startIndex, offsetBy: 3)..<end.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
                if inner == "if" {
                    tokens.append(.endIf)
                } else if inner == "switch" {
                    tokens.append(.endSwitch)
                } else {
                    throw FreemarkerError("Unsupported closing directive: </#\(inner)>")
                }
                remaining = remaining[end.upperBound...]
                skipLineBreak(remaining: &remaining, directiveStart: directiveStart)

            } else if remaining.hasPrefix("<#") {
                let directiveStart = remaining.startIndex
                guard let end = findClosingAngle(in: remaining) else {
                    throw FreemarkerError("Unclosed directive tag")
                }
                let inner = String(remaining[remaining.index(remaining.startIndex, offsetBy: 2)..<end.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
                if inner == "else" {
                    tokens.append(.elseDirective)
                } else if inner == "default" {
                    tokens.append(.defaultDirective)
                } else if inner == "break" {
                    tokens.append(.breakDirective)
                } else if inner.hasPrefix("if ") || inner.hasPrefix("if\t") {
                    let condition = String(inner.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    tokens.append(.ifDirective(condition: condition))
                } else if inner.hasPrefix("elseif ") || inner.hasPrefix("elseif\t") {
                    let condition = String(inner.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                    tokens.append(.elseIfDirective(condition: condition))
                } else if inner.hasPrefix("switch ") || inner.hasPrefix("switch\t") {
                    let expr = String(inner.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                    tokens.append(.switchDirective(expr: expr))
                } else if inner.hasPrefix("case ") || inner.hasPrefix("case\t") {
                    let value = String(inner.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    tokens.append(.caseDirective(value: value))
                } else {
                    throw FreemarkerError("Unsupported directive: <#\(inner)>")
                }
                remaining = remaining[end.upperBound...]
                skipLineBreak(remaining: &remaining, directiveStart: directiveStart)

            } else if remaining.hasPrefix("${") {
                guard let end = findClosingBrace(in: remaining) else {
                    throw FreemarkerError("Unclosed interpolation ${ }")
                }
                let expr = String(remaining[remaining.index(remaining.startIndex, offsetBy: 2)..<end.lowerBound])
                tokens.append(.interpolation(expr))
                remaining = remaining[end.upperBound...]

            } else {
                // Advance to the next special marker
                let markers = ["<#", "</#", "${"]
                var nearest: String.Index?
                for marker in markers {
                    if let r = remaining.range(of: marker),
                        nearest.map({ r.lowerBound < $0 }) ?? true
                    {
                        nearest = r.lowerBound
                    }
                }
                if let next = nearest {
                    tokens.append(.text(String(remaining[..<next])))
                    remaining = remaining[next...]
                } else {
                    tokens.append(.text(String(remaining)))
                    break
                }
            }
        }

        return tokens
    }
}
