import Foundation

enum SpeakingFeedbackAIClientError: LocalizedError {
    case notConfigured
    case invalidResponse
    case serverError(Int, String)
    case validationFailed(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI feedback backend is not configured."
        case .invalidResponse:
            return "AI feedback returned an unexpected response."
        case .serverError(let code, let message):
            return message.isEmpty ? "AI feedback failed (\(code))." : "AI feedback failed (\(code)): \(message)"
        case .validationFailed(let reason):
            return "AI feedback returned an unusable response: \(reason)"
        case .network(let message):
            return "Network error: \(message)"
        }
    }
}

struct SpeakingFeedbackAIResponseDTO: Decodable {
    let overallScore: Int
    let summary: String
    let grammar: MetricDTO
    let pronunciation: MetricDTO
    let vocabulary: MetricDTO
    let fluency: MetricDTO
    let corrections: [CorrectionDTO]

    /// Debate-only metrics. Optional so non-debate responses decode
    /// unchanged; present only when `includeDebateMetrics` was requested.
    let argumentQuality: MetricDTO?
    let persuasiveness: MetricDTO?
    let structure: MetricDTO?

    struct MetricDTO: Decodable {
        let rating: String
        let score: Int
        let explanation: String
    }

    struct CorrectionDTO: Decodable {
        let originalText: String
        let correctedText: String
        let explanation: String
        let category: String?
    }
}

struct SpeakingFeedbackRequest {
    let language: GrammarLanguage
    let level: EssayDifficulty
    let scenarioOrTopicTitle: String
    let scenarioOrTopicContext: String

    let messages: [SpeakingConversationMessage]

    /// When true the evaluator is asked to also produce the three debate
    /// metrics (argument quality, persuasiveness, structure).
    let includeDebateMetrics: Bool

    init(
        language: GrammarLanguage,
        level: EssayDifficulty,
        scenarioOrTopicTitle: String,
        scenarioOrTopicContext: String,
        messages: [SpeakingConversationMessage],
        includeDebateMetrics: Bool = false
    ) {
        self.language = language
        self.level = level
        self.scenarioOrTopicTitle = scenarioOrTopicTitle
        self.scenarioOrTopicContext = scenarioOrTopicContext
        self.messages = messages
        self.includeDebateMetrics = includeDebateMetrics
    }
}

protocol SpeakingFeedbackAIClient {
    func generateFeedback(_ request: SpeakingFeedbackRequest) async throws -> SpeakingFeedbackAIResponseDTO
}
