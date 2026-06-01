import Foundation

enum ReadingTextNormalizationService {

    static func normalize(_ raw: String) -> String {
        paragraphs(from: raw).joined(separator: "\n\n")
    }

    static func paragraphs(from raw: String) -> [String] {
        var text = AIResponseTextCleaner.normalizedText(from: raw)

        text = removeAIBoilerplate(text)

        text = removeMarkdown(text)
        text = removePlaceholders(text)

        text = normalizeWhitespace(text)

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
        if let first = lines.first?.trimmingCharacters(in: .whitespaces).lowercased(),
           prefixes.contains(where: { first.hasPrefix($0) }),
           first.count < 80 {
            lines.removeFirst()
        }
        return lines.joined(separator: "\n")
    }

    private static func removeMarkdown(_ text: String) -> String {
        var result = text
        let patterns = [
            "\\*\\*(.+?)\\*\\*",   // **bold**
            "__(.+?)__",           // __bold__
            "\\*(.+?)\\*",          // *italic*
            "(?<!\\w)_(.+?)_(?!\\w)" // _italic_
        ]
        for pattern in patterns {
            result = replace(pattern: pattern, in: result, with: "$1")
        }
        result = replace(pattern: "(?m)^\\s{0,3}#{1,6}\\s*", in: result, with: "")
        result = replace(pattern: "(?m)^\\s{0,3}>\\s?", in: result, with: "")
        result = replace(pattern: "(?m)^\\s{0,3}[-*•]\\s+", in: result, with: "")
        return result
    }

    private static func removePlaceholders(_ text: String) -> String {
        var result = text
        result = replace(pattern: "(?i)\\bword\\s*\\(\\s*translate\\s*\\)", in: result, with: "")
        result = replace(pattern: "(?i)\\[\\s*word\\s*\\]", in: result, with: "")
        result = replace(pattern: "(?i)\\[\\s*translate\\s*\\]", in: result, with: "")
        result = replace(pattern: "\\(\\s*\\)", in: result, with: "")
        result = replace(pattern: "\\[\\s*\\]", in: result, with: "")
        return result
    }

    private static func normalizeWhitespace(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        result = replace(pattern: "[ \\t]{2,}", in: result, with: " ")
        result = replace(pattern: "(?m)[ \\t]+$", in: result, with: "")
        result = replace(pattern: "\\n{3,}", in: result, with: "\n\n")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitParagraphs(_ text: String) -> [String] {
        let byBlank = text.components(separatedBy: "\n\n")
            .map { $0.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if byBlank.count > 1 { return byBlank }

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
