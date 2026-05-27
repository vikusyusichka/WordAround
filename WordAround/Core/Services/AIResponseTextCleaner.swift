import Foundation

/// Shared utilities for parsing AI model output coming back through the
/// Cloudflare Worker proxy. The Worker returns `{ "text": "..." }`; that
/// text is whatever the model produced (often JSON, often wrapped in
/// Markdown fences, sometimes prefixed with prose). These helpers turn
/// that into something safe to `JSONDecoder().decode(...)`.
///
/// Designed to be tiny and pure — no Foundation imports beyond `Foundation`,
/// no logging side effects. Callers decide how to log and what to throw.
enum AIResponseTextCleaner {

    // MARK: - Markdown fences

    /// Removes ```json … ```, ```JSON … ```, or ``` … ``` fences. Also
    /// strips leading/trailing whitespace. Robust to fences with or
    /// without a language tag.
    static func cleanMarkdownFences(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Leading fence — may include a language tag like `json` / `JSON`.
        if s.hasPrefix("```") {
            // Drop the first line entirely (handles ```json\n…).
            if let newline = s.firstIndex(of: "\n") {
                s = String(s[s.index(after: newline)...])
            } else {
                s = String(s.dropFirst(3))
            }
        }

        // Trailing fence.
        if s.hasSuffix("```") {
            s = String(s.dropLast(3))
        }

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Double-encoded JSON string

    /// Gemini sometimes returns a JSON STRING ("\"hello\"") instead of a
    /// raw value. If the input looks like that, unwrap it once. Returns
    /// the original string unchanged when no safe unwrap is possible.
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

    /// Extracts the first balanced JSON object `{...}` or array `[...]`
    /// from a longer string. Useful when the model adds prose around the
    /// JSON. Returns the input unchanged when no balanced span is found —
    /// the caller can then attempt to decode and surface a decoding error.
    static func extractFirstJSONObjectOrArray(_ text: String) -> String {
        let s = text
        guard let firstObject = s.firstIndex(of: "{"),
              let _ = s.firstIndex(of: "}") else {
            // No object root — maybe an array root only.
            if let arr = extractBalancedSpan(in: s, opening: "[", closing: "]") {
                return arr
            }
            return s
        }

        guard let firstArray = s.firstIndex(of: "[") else {
            return extractBalancedSpan(in: s, from: firstObject, opening: "{", closing: "}") ?? s
        }

        // Pick whichever root appears FIRST in the string and extract that
        // balanced span.
        if firstObject < firstArray {
            return extractBalancedSpan(in: s, from: firstObject, opening: "{", closing: "}") ?? s
        } else {
            return extractBalancedSpan(in: s, from: firstArray, opening: "[", closing: "]") ?? s
        }
    }

    // MARK: - Compose

    /// One-shot normalizer used by feature clients. Order matters:
    ///   1. Trim whitespace / collapse fences.
    ///   2. Unwrap a double-encoded JSON string if the text is `"…"`.
    ///   3. Strip prose around JSON by extracting the first balanced span.
    /// Returns text safe to feed into `JSONDecoder` (or to consume as plain
    /// text if the caller never expected JSON).
    static func normalizedText(from raw: String) -> String {
        let stripped = cleanMarkdownFences(raw)
        let unwrapped = unwrapJSONStringIfNeeded(stripped)
        // After unwrapping, fences might still be inside — re-strip.
        let restripped = cleanMarkdownFences(unwrapped)
        return restripped
    }

    /// Convenience for JSON-shaped responses: normalize, then aggressively
    /// extract the first JSON object/array. The result is what callers
    /// should decode with `JSONDecoder().decode(T.self, from:)`.
    static func normalizedJSON(from raw: String) -> String {
        let normalized = normalizedText(from: raw)
        return extractFirstJSONObjectOrArray(normalized)
    }

    // MARK: - Internals

    /// Scans `text` from `start` (or its first occurrence of `opening`),
    /// tracking nested brackets to find the matching close. Honors string
    /// literals and escape sequences so `}` inside a `"..."` is ignored.
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
