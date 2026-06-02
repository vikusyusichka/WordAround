import Foundation

struct SpeakingConversationFeedback: Equatable, Identifiable {
    let id: UUID
    let overallScore: Int
    let summary: String
    let grammar: SpeakingFeedbackMetric
    let pronunciation: SpeakingFeedbackMetric
    let vocabulary: SpeakingFeedbackMetric
    let fluency: SpeakingFeedbackMetric
    let corrections: [SpeakingCorrection]

    let extraMetrics: [SpeakingFeedbackMetric]

    let transcript: String

    let isFallback: Bool

    init(
        id: UUID = UUID(),
        overallScore: Int,
        summary: String,
        grammar: SpeakingFeedbackMetric,
        pronunciation: SpeakingFeedbackMetric,
        vocabulary: SpeakingFeedbackMetric,
        fluency: SpeakingFeedbackMetric,
        corrections: [SpeakingCorrection],
        extraMetrics: [SpeakingFeedbackMetric] = [],
        transcript: String,
        isFallback: Bool
    ) {
        self.id = id
        self.overallScore = overallScore
        self.summary = summary
        self.grammar = grammar
        self.pronunciation = pronunciation
        self.vocabulary = vocabulary
        self.fluency = fluency
        self.corrections = corrections
        self.extraMetrics = extraMetrics
        self.transcript = transcript
        self.isFallback = isFallback
    }

    var metrics: [SpeakingFeedbackMetric] {
        [grammar, pronunciation, vocabulary, fluency] + extraMetrics
    }
}

struct SpeakingFeedbackMetric: Equatable, Identifiable {
    let id = UUID()

    let title: String

    let rating: String

    let score: Int

    let explanation: String

    let iconName: String

    static func == (lhs: SpeakingFeedbackMetric, rhs: SpeakingFeedbackMetric) -> Bool {
        lhs.title == rhs.title &&
            lhs.rating == rhs.rating &&
            lhs.score == rhs.score &&
            lhs.explanation == rhs.explanation &&
            lhs.iconName == rhs.iconName
    }
}

struct SpeakingCorrection: Equatable, Identifiable {
    let id: String
    let originalText: String
    let correctedText: String
    let explanation: String

    let category: String

    init(
        id: String = UUID().uuidString,
        originalText: String,
        correctedText: String,
        explanation: String,
        category: String
    ) {
        self.id = id
        self.originalText = originalText
        self.correctedText = correctedText
        self.explanation = explanation
        self.category = category
    }
}
