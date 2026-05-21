import Foundation

struct EssayScoringInput {
    let text: String
    let topic: String
    let wordRange: ClosedRange<Int>
    let grammarIssues: [GrammarIssue]
    let usedHints: Int
    let usedTranslations: Int
    let usedSynonyms: Int
    let difficulty: EssayDifficulty
}

final class EssayScoringService {

    func score(input: EssayScoringInput) -> EssayScore {
        let words = normalizedWords(from: input.text)
        let wordCount = words.count

        let grammarScore = calculateGrammarScore(
            issues: input.grammarIssues,
            wordCount: wordCount,
            difficulty: input.difficulty
        )

        let vocabularyScore = calculateVocabularyScore(
            issues: input.grammarIssues,
            words: words,
            difficulty: input.difficulty
        )

        let lengthScore = calculateLengthScore(
            wordCount: wordCount,
            range: input.wordRange
        )

        let complexityScore = calculateComplexityScore(
            text: input.text,
            words: words,
            difficulty: input.difficulty
        )

        let relevanceScore = calculateRelevanceScore(
            words: words,
            topic: input.topic
        )

        let independenceScore = calculateIndependenceScore(
            usedHints: input.usedHints,
            usedTranslations: input.usedTranslations,
            usedSynonyms: input.usedSynonyms,
            difficulty: input.difficulty
        )

        let weighted =
            Double(grammarScore) * 0.30 +
            Double(vocabularyScore) * 0.14 +
            Double(lengthScore) * 0.12 +
            Double(complexityScore) * 0.14 +
            Double(relevanceScore) * 0.22 +
            Double(independenceScore) * 0.08

        let issuePenalty = calculateIssuePenalty(
            issues: input.grammarIssues,
            wordCount: wordCount,
            difficulty: input.difficulty
        )

        var total = Int((weighted - issuePenalty).rounded())

        if relevanceScore < 25 {
            total = min(total, 42)
        } else if relevanceScore < 45 {
            total = min(total, 58)
        } else if relevanceScore < 60 {
            total = min(total, 72)
        }

        total = clamp(total)

        return EssayScore(
            total: total,
            grammar: grammarScore,
            vocabulary: vocabularyScore,
            length: lengthScore,
            complexity: complexityScore,
            relevance: relevanceScore,
            independence: independenceScore,
            cefrLevel: estimateCEFR(
                total: total,
                complexity: complexityScore,
                grammar: grammarScore,
                relevance: relevanceScore
            ),
            qualityLabel: estimateQualityLabel(total: total)
        )
    }

    private func calculateGrammarScore(
        issues: [GrammarIssue],
        wordCount: Int,
        difficulty: EssayDifficulty
    ) -> Int {
        guard wordCount > 0 else { return 0 }

        let grammarCount = issues.filter { $0.category == .grammar }.count
        let density = Double(grammarCount) / Double(wordCount)

        let score = 100.0 - density * 720.0 * difficulty.strictnessMultiplier
        return clamp(Int(score.rounded()))
    }

    private func calculateVocabularyScore(
        issues: [GrammarIssue],
        words: [String],
        difficulty: EssayDifficulty
    ) -> Int {
        guard !words.isEmpty else { return 0 }

        let vocabIssueCount = issues.filter {
            $0.category == .vocabulary || $0.category == .style
        }.count

        let uniqueRatio = Double(Set(words).count) / Double(words.count)
        let longWordRatio = Double(words.filter { $0.count >= 7 }.count) / Double(words.count)

        let richnessScore = min(100.0, uniqueRatio * 130.0)
        let precisionScore = 100.0 - Double(vocabIssueCount) / Double(words.count) * 600.0
        let advancedWordScore = min(100.0, 45.0 + longWordRatio * 180.0)

        let score = richnessScore * 0.45 + precisionScore * 0.40 + advancedWordScore * 0.15

        return clamp(Int(score.rounded()))
    }

    private func calculateLengthScore(
        wordCount: Int,
        range: ClosedRange<Int>
    ) -> Int {
        guard wordCount > 0 else { return 0 }

        let minWords = range.lowerBound
        let maxWords = range.upperBound
        let ideal = Double(minWords + maxWords) / 2.0
        let halfRange = Double(maxWords - minWords) / 2.0

        if wordCount < minWords {
            let ratio = Double(wordCount) / Double(minWords)
            return clamp(Int((ratio * 72.0).rounded()))
        }

        if wordCount > maxWords {
            let excess = Double(wordCount - maxWords)
            let penalty = min(55.0, excess * 1.6)
            return clamp(Int((78.0 - penalty).rounded()))
        }

        let distanceFromIdeal = abs(Double(wordCount) - ideal)
        let normalizedDistance = halfRange == 0 ? 0 : distanceFromIdeal / halfRange

        let score = 96.0 - normalizedDistance * 18.0
        return clamp(Int(score.rounded()))
    }

    private func calculateComplexityScore(
        text: String,
        words: [String],
        difficulty: EssayDifficulty
    ) -> Int {
        guard words.count > 5 else { return 15 }

        let sentences = text
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let sentenceCount = max(1, sentences.count)
        let averageSentenceLength = Double(words.count) / Double(sentenceCount)

        let sentenceScore = scoreSentenceLength(
            averageSentenceLength,
            difficulty: difficulty
        )

        let connectorScore = calculateConnectorScore(text: text)
        let structureScore = calculateStructureScore(text: text)

        let score =
            sentenceScore * 0.45 +
            connectorScore * 0.30 +
            structureScore * 0.25

        return clamp(Int(score.rounded()))
    }

    private func calculateRelevanceScore(
        words: [String],
        topic: String
    ) -> Int {
        guard !words.isEmpty else { return 0 }

        let wordSet = Set(words)
        let topicProfile = TopicProfile.profile(for: topic)

        let requiredMatches = topicProfile.requiredKeywords.filter { wordSet.contains($0) }.count
        let supportingMatches = topicProfile.supportingKeywords.filter { wordSet.contains($0) }.count
        let taskMatches = topicProfile.taskKeywords.filter { wordSet.contains($0) }.count

        let requiredRatio = topicProfile.requiredKeywords.isEmpty
            ? 0.0
            : Double(requiredMatches) / Double(topicProfile.requiredKeywords.count)

        let supportingRatio = topicProfile.supportingKeywords.isEmpty
            ? 0.0
            : Double(supportingMatches) / Double(topicProfile.supportingKeywords.count)

        let taskRatio = topicProfile.taskKeywords.isEmpty
            ? 0.0
            : Double(taskMatches) / Double(topicProfile.taskKeywords.count)

        var score =
            requiredRatio * 55.0 +
            supportingRatio * 25.0 +
            taskRatio * 20.0

        if requiredMatches == 0 {
            score = min(score, 28.0)
        }

        if requiredMatches == 0 && supportingMatches <= 1 {
            score = min(score, 18.0)
        }

        return clamp(Int(score.rounded()))
    }

    private func calculateIndependenceScore(
        usedHints: Int,
        usedTranslations: Int,
        usedSynonyms: Int,
        difficulty: EssayDifficulty
    ) -> Int {
        let penalty =
            Double(usedHints) * 5.0 +
            Double(usedTranslations) * 9.0 +
            Double(usedSynonyms) * 7.0

        let adjustedPenalty = penalty * difficulty.strictnessMultiplier

        return clamp(Int((100.0 - adjustedPenalty).rounded()))
    }

    private func calculateIssuePenalty(
        issues: [GrammarIssue],
        wordCount: Int,
        difficulty: EssayDifficulty
    ) -> Double {
        guard wordCount > 0 else { return 0 }

        let issueDensity = Double(issues.count) / Double(wordCount)
        let penalty = Double(issues.count) * 1.7 + issueDensity * 110.0

        return min(38.0, penalty * difficulty.strictnessMultiplier)
    }

    private func scoreSentenceLength(
        _ average: Double,
        difficulty: EssayDifficulty
    ) -> Double {
        let range = difficulty.targetSentenceLengthRange

        if average >= range.lowerBound && average <= range.upperBound {
            return 92
        }

        if average < range.lowerBound {
            return max(25.0, average / range.lowerBound * 85.0)
        }

        let overflow = average - range.upperBound
        return max(35.0, 90.0 - overflow * 5.0)
    }

    private func calculateConnectorScore(text: String) -> Double {
        let lower = text.lowercased()

        let connectors = [
            "because",
            "however",
            "although",
            "therefore",
            "first",
            "second",
            "finally",
            "also",
            "for example",
            "in my opinion",
            "on the other hand",
            "after that",
            "usually",
            "sometimes"
        ]

        let matches = connectors.filter { lower.contains($0) }.count
        return min(100.0, 35.0 + Double(matches) * 10.0)
    }

    private func calculateStructureScore(text: String) -> Double {
        let paragraphs = text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let sentenceCount = text
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count

        var score = 35.0

        if sentenceCount >= 4 { score += 25 }
        if paragraphs.count >= 2 { score += 20 }
        if text.contains(",") { score += 10 }
        if text.contains(".") { score += 10 }

        return min(100.0, score)
    }

    private func estimateCEFR(
        total: Int,
        complexity: Int,
        grammar: Int,
        relevance: Int
    ) -> String {
        if relevance < 35 {
            return "A1"
        }

        if total >= 88 && complexity >= 80 && grammar >= 82 {
            return "C1"
        }

        if total >= 76 {
            return "B2"
        }

        if total >= 62 {
            return "B1"
        }

        if total >= 45 {
            return "A2"
        }

        return "A1"
    }

    private func estimateQualityLabel(total: Int) -> String {
        switch total {
        case 85...100:
            return "Excellent"
        case 70..<85:
            return "Very good"
        case 50..<70:
            return "Good"
        default:
            return "Needs work"
        }
    }

    private func normalizedWords(from text: String) -> [String] {
        text
            .lowercased()
            .split { !$0.isLetter }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}

private struct TopicProfile {
    let requiredKeywords: Set<String>
    let supportingKeywords: Set<String>
    let taskKeywords: Set<String>

    static func profile(for topic: String) -> TopicProfile {
        let lower = topic.lowercased()

        if lower.contains("season") {
            return TopicProfile(
                requiredKeywords: ["season", "spring", "summer", "autumn", "fall", "winter"],
                supportingKeywords: ["weather", "warm", "cold", "rainy", "sunny", "snow", "wind", "temperature"],
                taskKeywords: ["favorite", "like", "prefer", "activities", "activity", "because", "outside"]
            )
        }

        if lower.contains("routine") || lower.contains("day") {
            return TopicProfile(
                requiredKeywords: ["routine", "day", "morning", "afternoon", "evening"],
                supportingKeywords: ["wake", "breakfast", "study", "work", "lunch", "dinner", "sleep"],
                taskKeywords: ["usually", "always", "sometimes", "first", "after", "then"]
            )
        }

        if lower.contains("trip") || lower.contains("travel") {
            return TopicProfile(
                requiredKeywords: ["trip", "travel", "journey", "went", "visited"],
                supportingKeywords: ["city", "place", "hotel", "museum", "beach", "mountain", "street"],
                taskKeywords: ["remember", "happened", "special", "because", "experience"]
            )
        }

        if lower.contains("place") || lower.contains("city") {
            return TopicProfile(
                requiredKeywords: ["place", "city", "street", "park", "building", "area"],
                supportingKeywords: ["beautiful", "crowded", "quiet", "old", "new", "interesting"],
                taskKeywords: ["see", "feel", "like", "visit", "describe"]
            )
        }

        if lower.contains("person") || lower.contains("admire") {
            return TopicProfile(
                requiredKeywords: ["person", "mother", "father", "friend", "teacher", "sister", "brother"],
                supportingKeywords: ["kind", "smart", "strong", "patient", "helpful", "honest"],
                taskKeywords: ["admire", "inspire", "because", "example", "personality"]
            )
        }

        let fallback = topic
            .lowercased()
            .split { !$0.isLetter }
            .map(String.init)
            .filter { $0.count > 3 }

        return TopicProfile(
            requiredKeywords: Set(fallback),
            supportingKeywords: [],
            taskKeywords: []
        )
    }
}

private extension EssayDifficulty {
    var strictnessMultiplier: Double {
        switch self {
        case .a1: return 0.70
        case .a2: return 0.85
        case .b1: return 1.00
        case .b2: return 1.15
        case .c1: return 1.30
        case .native: return 1.50
        }
    }

    var targetSentenceLengthRange: ClosedRange<Double> {
        switch self {
        case .a1: return 5...11
        case .a2: return 7...14
        case .b1: return 9...18
        case .b2: return 11...22
        case .c1: return 13...26
        case .native: return 15...30
        }
    }
}
