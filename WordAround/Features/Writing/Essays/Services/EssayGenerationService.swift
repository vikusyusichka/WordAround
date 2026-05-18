import Foundation

protocol EssayGenerationServicing {
    func generateSuggestedTask(
        language: GrammarLanguage,
        avoidTitles: [String]
    ) async throws -> GeneratedEssayTask

    func generateTaskFromCustomTopic(
        topic: String,
        language: GrammarLanguage
    ) async throws -> GeneratedEssayTask

    func generateHint(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topicTitle: String,
        task: String,
        essayText: String,
        previousHints: [String]
    ) async throws -> EssayGeneratedHint
}

final class EssayGenerationService: EssayGenerationServicing {
    private let client: EssayAIClient

    init(client: EssayAIClient = GeminiEssayAIClient()) {
        self.client = client
    }

    func generateSuggestedTask(
        language: GrammarLanguage,
        avoidTitles: [String]
    ) async throws -> GeneratedEssayTask {
        let task = try await client.generateSuggestedTask(
            language: language,
            avoidTitles: avoidTitles
        )

        return sanitize(task)
    }

    func generateTaskFromCustomTopic(
        topic: String,
        language: GrammarLanguage
    ) async throws -> GeneratedEssayTask {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else {
            throw EssayGenerationServiceError.emptyTopic
        }

        let task = try await client.generateTaskFromCustomTopic(
            topic: trimmedTopic,
            language: language
        )

        return sanitize(task)
    }

    func generateHint(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topicTitle: String,
        task: String,
        essayText: String,
        previousHints: [String]
    ) async throws -> EssayGeneratedHint {
        let hint = try await client.generateHint(
            language: language,
            level: level,
            topicTitle: topicTitle,
            task: task,
            essayText: essayText,
            previousHints: previousHints
        )

        return sanitize(hint, previousHints: previousHints)
    }

    private func sanitize(_ task: GeneratedEssayTask) -> GeneratedEssayTask {
        let fallback = task.detectedLevel.defaultWritingConfiguration
        let title = task.title.isEmpty ? "Essay practice task" : task.title
        let description = task.task.isEmpty ? "Write a short essay about this topic." : task.task

        let minWords = Self.clamped(
            task.wordLimitMin,
            lowerBound: fallback.wordRange.lowerBound,
            upperBound: fallback.wordRange.upperBound
        )

        let maxWords = Self.clamped(
            task.wordLimitMax,
            lowerBound: max(minWords, fallback.wordRange.lowerBound),
            upperBound: fallback.wordRange.upperBound
        )

        let time = Self.clamped(
            task.estimatedTimeMinutes,
            lowerBound: fallback.timeRange.lowerBound,
            upperBound: fallback.timeRange.upperBound
        )

        return GeneratedEssayTask(
            title: title,
            task: description,
            detectedLevel: task.detectedLevel,
            estimatedTimeMinutes: time,
            wordLimitMin: minWords,
            wordLimitMax: maxWords,
            quickTips: task.quickTips
        )
    }

    private func sanitize(
        _ hint: EssayGeneratedHint,
        previousHints: [String]
    ) -> EssayGeneratedHint {
        let cleanedText = hint.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .joined(separator: " ")

        let isDuplicate = previousHints.contains { existing in
            existing.caseInsensitiveCompare(cleanedText) == .orderedSame
        }

        let safeText: String
        if cleanedText.isEmpty || isDuplicate {
            safeText = "Add one clear supporting example."
        } else {
            safeText = String(cleanedText.split(separator: " ").prefix(12).joined(separator: " "))
        }

        return EssayGeneratedHint(text: safeText, category: hint.category)
    }

    private static func clamped(_ value: Int, lowerBound: Int, upperBound: Int) -> Int {
        min(max(value, lowerBound), upperBound)
    }
}

enum EssayGenerationServiceError: LocalizedError {
    case emptyTopic

    var errorDescription: String? {
        switch self {
        case .emptyTopic:
            return "Enter a topic first."
        }
    }
}

private extension EssayDifficulty {
    var defaultWritingConfiguration: (wordRange: ClosedRange<Int>, timeRange: ClosedRange<Int>) {
        switch self {
        case .a1:
            return (40...70, 6...8)
        case .a2:
            return (60...100, 8...10)
        case .b1:
            return (90...150, 10...14)
        case .b2:
            return (140...220, 14...18)
        case .c1:
            return (220...320, 18...25)
        case .native:
            return (300...500, 20...30)
        }
    }
}
