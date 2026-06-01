import Foundation

struct ReadingTextAnalyzerService: ReadingTextAnalyzing, Sendable {
    static let shared = ReadingTextAnalyzerService()

    private let wordsPerMinute = 180

    func analyze(title: String, content: String, language: GrammarLanguage? = nil, manualLevel: EssayDifficulty? = nil) -> ReadingTextAnalysis {
        let normalized = normalize(content)
        let words = wordCount(for: normalized)
        let level = manualLevel ?? estimateLevel(for: normalized, wordCount: words)
        let sentences = sentences(from: normalized)

        return ReadingTextAnalysis(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            normalizedContent: normalized,
            wordCount: words,
            estimatedReadingMinutes: estimatedReadingMinutes(wordCount: words),
            preview: preview(for: normalized),
            estimatedLevel: level,
            sentences: sentences
        )
    }

    func wordCount(for content: String) -> Int {
        content
            .split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }

    func preview(for content: String, maxLength: Int = 120) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.count <= maxLength { return trimmed }
        let prefix = String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        return prefix + "…"
    }

    func estimatedReadingMinutes(wordCount: Int) -> Int {
        max(1, Int(ceil(Double(wordCount) / Double(wordsPerMinute))))
    }

    func estimatedReadingTimeSeconds(wordCount: Int) -> Int {
        max(30, estimatedReadingMinutes(wordCount: wordCount) * 60)
    }

    func estimateLevel(for content: String, wordCount: Int) -> EssayDifficulty {
        let tokens = content
            .lowercased()
            .split { !$0.isLetter }
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { return .a1 }

        let averageLength = Double(tokens.map(\.count).reduce(0, +)) / Double(tokens.count)
        let longWordRatio = Double(tokens.filter { $0.count >= 8 }.count) / Double(tokens.count)
        let avgSentenceLength: Double = {
            let sents = sentences(from: content)
            guard !sents.isEmpty else { return Double(wordCount) }
            let total = sents.reduce(0) { $0 + self.wordCount(for: $1) }
            return Double(total) / Double(sents.count)
        }()

        switch wordCount {
        case ..<40:
            return averageLength < 4.8 ? .a1 : .a2
        case 40..<90:
            return avgSentenceLength < 12 ? .a2 : .b1
        case 90..<220:
            if longWordRatio > 0.18 || avgSentenceLength > 18 { return .b2 }
            return .b1
        case 220..<450:
            if longWordRatio > 0.22 || averageLength > 6.2 { return .c1 }
            return .b2
        default:
            if longWordRatio > 0.28 || averageLength > 6.8 { return .native }
            return .c1
        }
    }

    func sentences(from content: String) -> [String] {
        let normalized = content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        var results: [String] = []
        normalized.enumerateSubstrings(in: normalized.startIndex..<normalized.endIndex, options: .bySentences) { substring, _, _, _ in
            guard let substring else { return }
            let cleaned = substring.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count >= 8 {
                results.append(cleaned)
            }
        }

        if results.isEmpty, !normalized.isEmpty {
            return [normalized]
        }
        return results
    }

    func wordCount(in text: String) -> Int { wordCount(for: text) }
    func preview(from content: String, maxLength: Int = 120) -> String { preview(for: content, maxLength: maxLength) }
    func splitSentences(_ text: String) -> [String] { sentences(from: text) }
    func estimateDifficulty(content: String, wordCountOverride: Int? = nil) -> EssayDifficulty {
        estimateLevel(for: content, wordCount: wordCountOverride ?? wordCount(for: content))
    }

    private func normalize(_ content: String) -> String {
        var lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        while lines.first?.isEmpty == true { lines.removeFirst() }
        while lines.last?.isEmpty == true { lines.removeLast() }

        var collapsed: [String] = []
        var blankRun = 0
        for line in lines {
            if line.isEmpty {
                blankRun += 1
                if blankRun <= 1 { collapsed.append("") }
            } else {
                blankRun = 0
                collapsed.append(line)
            }
        }

        return collapsed.joined(separator: "\n")
    }
}
