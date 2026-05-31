import Foundation

struct ReadingDifficultyDetector: Sendable {
    static let shared = ReadingDifficultyDetector()

    func detect(content: String, wordCount: Int? = nil) -> EssayDifficulty {
        let normalized = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return .a1 }

        let words = tokens(in: normalized)
        let count = wordCount ?? words.count
        guard count > 0 else { return .a1 }

        let avgWordLength = Double(words.map(\.count).reduce(0, +)) / Double(words.count)
        let uniqueRatio = Double(Set(words).count) / Double(words.count)
        let longWordRatio = Double(words.filter { $0.count >= 8 }.count) / Double(words.count)
        let punctuationScore = punctuationComplexity(in: normalized)
        let avgSentenceLength = averageSentenceLength(in: normalized, wordCount: count)

        var score = 0.0
        score += min(Double(count) / 120.0, 2.0)
        score += min(avgWordLength / 3.0, 1.5)
        score += min(avgSentenceLength / 8.0, 1.5)
        score += min(longWordRatio * 4.0, 1.5)
        score += min(uniqueRatio * 2.0, 1.0)
        score += punctuationScore

        switch score {
        case ..<2.2: return .a1
        case ..<3.4: return .a2
        case ..<4.6: return .b1
        case ..<5.8: return .b2
        default: return .c1
        }
    }

    private func tokens(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter }
            .map(String.init)
            .filter { $0.count >= 2 }
    }

    private func averageSentenceLength(in text: String, wordCount: Int) -> Double {
        let sentences = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !sentences.isEmpty else { return Double(wordCount) }
        let total = sentences.reduce(0) { partial, sentence in
            partial + sentence.split { $0.isWhitespace }.filter { !$0.isEmpty }.count
        }
        return Double(total) / Double(sentences.count)
    }

    private func punctuationComplexity(in text: String) -> Double {
        let complex: Set<Character> = [",", ";", ":", "—", "–", "(", ")"]
        let count = text.filter { complex.contains($0) }.count
        return min(Double(count) / 12.0, 1.2)
    }
}
