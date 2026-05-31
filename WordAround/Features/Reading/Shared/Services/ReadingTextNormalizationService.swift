import Foundation

enum ReadingTextNormalizationService {

    static func normalize(_ raw: String) -> String {
        paragraphs(from: raw).joined(separator: "\n\n")
    }

    static func paragraphs(from raw: String) -> [String] {
        // 1. Reuse the shared cleaner to strip code fences / unwrap JSON strings.
        var text = AIResponseTextCleaner.normalizedText(from: raw)

        // 2. Strip AI intro/outro lines.
        text = removeAIBoilerplate(text)

        // 3. Remove markdown emphasis + placeholder artifacts.
        text = removeMarkdown(text)
        text = removePlaceholders(text)

        // 4. Normalize whitespace and newlines.
        text = normalizeWhitespace(text)

        // 5. Split into paragraphs, splitting oversized blobs by sentence groups.
        let rawParagraphs = splitParagraphs(text)
        let result = rawParagraphs.flatMap { wrapLongParagraph($0) }

        return result.isEmpty ? [text.trimmingCharacters(in: .whitespacesAndNewlines)].filter { !$0.isEmpty } : result
    }

    // MARK: - Steps

    private static func removeAIBoilerplate(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        let prefixes = [
            "here is", "here's", "sure, here", "sure! here", "below is",
            "here is the text", "here is your", "of course"
        ]
        // Drop a single leading boilerplate line if it matches.
        if let first = lines.first?.trimmingCharacters(in: .whitespaces).lowercased(),
           prefixes.contains(where: { first.hasPrefix($0) }),
           first.count < 80 {
            lines.removeFirst()
        }
        return lines.joined(separator: "\n")
    }

    private static func removeMarkdown(_ text: String) -> String {
        var result = text
        // Bold / italic emphasis: keep inner content, drop the markers.
        let patterns = [
            "\\*\\*(.+?)\\*\\*",   // **bold**
            "__(.+?)__",           // __bold__
            "\\*(.+?)\\*",          // *italic*
            "(?<!\\w)_(.+?)_(?!\\w)" // _italic_
        ]
        for pattern in patterns {
            result = replace(pattern: pattern, in: result, with: "$1")
        }
        // Heading markers / blockquotes / leftover bullets at line starts.
        result = replace(pattern: "(?m)^\\s{0,3}#{1,6}\\s*", in: result, with: "")
        result = replace(pattern: "(?m)^\\s{0,3}>\\s?", in: result, with: "")
        result = replace(pattern: "(?m)^\\s{0,3}[-*•]\\s+", in: result, with: "")
        return result
    }

    private static func removePlaceholders(_ text: String) -> String {
        var result = text
        // Literal vocabulary placeholders the model sometimes emits.
        result = replace(pattern: "(?i)\\bword\\s*\\(\\s*translate\\s*\\)", in: result, with: "")
        result = replace(pattern: "(?i)\\[\\s*word\\s*\\]", in: result, with: "")
        result = replace(pattern: "(?i)\\[\\s*translate\\s*\\]", in: result, with: "")
        // Empty parens/brackets left behind after stripping.
        result = replace(pattern: "\\(\\s*\\)", in: result, with: "")
        result = replace(pattern: "\\[\\s*\\]", in: result, with: "")
        return result
    }

    private static func normalizeWhitespace(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        // Collapse runs of spaces/tabs (not newlines).
        result = replace(pattern: "[ \\t]{2,}", in: result, with: " ")
        // Trim trailing spaces on each line.
        result = replace(pattern: "(?m)[ \\t]+$", in: result, with: "")
        // Collapse 3+ newlines to a paragraph break.
        result = replace(pattern: "\\n{3,}", in: result, with: "\n\n")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitParagraphs(_ text: String) -> [String] {
        let byBlank = text.components(separatedBy: "\n\n")
            .map { $0.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if byBlank.count > 1 { return byBlank }

        // No blank-line breaks: fall back to single-newline breaks if present.
        let bySingle = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return bySingle.isEmpty ? [text.trimmingCharacters(in: .whitespaces)] : bySingle
    }

    private static func wrapLongParagraph(_ paragraph: String, maxCharacters: Int = 600) -> [String] {
        guard paragraph.count > maxCharacters else { return [paragraph] }

        let sentences = splitSentences(paragraph)
        guard sentences.count > 1 else { return [paragraph] }

        var chunks: [String] = []
        var current = ""
        for sentence in sentences {
            if current.isEmpty {
                current = sentence
            } else if current.count + sentence.count + 1 <= maxCharacters {
                current += " " + sentence
            } else {
                chunks.append(current)
                current = sentence
            }
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    private static func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character == "." || character == "!" || character == "?" || character == "…" {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { sentences.append(trimmed) }
                current = ""
            }
        }
        let tail = current.trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty { sentences.append(tail) }
        return sentences
    }

    // MARK: - Regex helper

    private static func replace(pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }
}
