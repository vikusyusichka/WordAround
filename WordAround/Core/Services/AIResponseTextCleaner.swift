import Foundation

enum AIResponseTextCleaner {

    // MARK: - Markdown fences

    static func cleanMarkdownFences(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if s.hasPrefix("```") {
            if let newline = s.firstIndex(of: "\n") {
                s = String(s[s.index(after: newline)...])
            } else {
                s = String(s.dropFirst(3))
            }
        }

        if s.hasSuffix("```") {
            s = String(s.dropLast(3))
        }

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Double-encoded JSON string

    static func unwrapJSONStringIfNeeded(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("\""),
              trimmed.hasSuffix("\""),
              trimmed.count >= 2 else {
            return text
        }
        guard let data = trimmed.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(String.self, from: data) else {
            return text
        }
        return decoded
    }

    // MARK: - First JSON object / array

    static func extractFirstJSONObjectOrArray(_ text: String) -> String {
        let s = text
        guard let firstObject = s.firstIndex(of: "{"),
              let _ = s.firstIndex(of: "}") else {
            if let arr = extractBalancedSpan(in: s, opening: "[", closing: "]") {
                return arr
            }
            return s
        }

        guard let firstArray = s.firstIndex(of: "[") else {
            return extractBalancedSpan(in: s, from: firstObject, opening: "{", closing: "}") ?? s
        }

        if firstObject < firstArray {
            return extractBalancedSpan(in: s, from: firstObject, opening: "{", closing: "}") ?? s
        } else {
            return extractBalancedSpan(in: s, from: firstArray, opening: "[", closing: "]") ?? s
        }
    }

    // MARK: - Compose

    static func normalizedText(from raw: String) -> String {
        let stripped = cleanMarkdownFences(raw)
        let unwrapped = unwrapJSONStringIfNeeded(stripped)
        let restripped = cleanMarkdownFences(unwrapped)
        return restripped
    }

    static func normalizedJSON(from raw: String) -> String {
        let normalized = normalizedText(from: raw)
        return extractFirstJSONObjectOrArray(normalized)
    }

    // MARK: - Internals

    private static func extractBalancedSpan(
        in text: String,
        from start: String.Index? = nil,
        opening: Character,
        closing: Character
    ) -> String? {
        let begin = start ?? text.firstIndex(of: opening)
        guard let begin else { return nil }

        var depth = 0
        var inString = false
        var escape = false
        var idx = begin

        while idx < text.endIndex {
            let c = text[idx]

            if inString {
                if escape {
                    escape = false
                } else if c == "\\" {
                    escape = true
                } else if c == "\"" {
                    inString = false
                }
            } else {
                if c == "\"" {
                    inString = true
                } else if c == opening {
                    depth += 1
                } else if c == closing {
                    depth -= 1
                    if depth == 0 {
                        return String(text[begin...idx])
                    }
                }
            }

            idx = text.index(after: idx)
        }

        return nil
    }
}
