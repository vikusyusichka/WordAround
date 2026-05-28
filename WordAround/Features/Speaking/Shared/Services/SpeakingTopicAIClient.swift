import Foundation

enum SpeakingTopicAIClientError: LocalizedError {
    case notConfigured
    case invalidResponse
    case serverError(Int, String)
    case validationFailed(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Topic AI provider is not configured."
        case .invalidResponse:
            return "Topic AI returned an unexpected response."
        case .serverError(let code, let message):
            return message.isEmpty ? "Topic AI request failed (\(code))." : "Topic AI request failed (\(code)): \(message)"
        case .validationFailed(let reason):
            return "Topic AI returned an unusable response: \(reason)"
        case .network(let message):
            return "Network error: \(message)"
        }
    }
}

protocol SpeakingTopicAIClient {
    func generateTopic(
        language: GrammarLanguage,
        level: EssayDifficulty,
        length: ConversationLength,
        avoidTitles: [String]
    ) async throws -> GeneratedConversationTopic
}

extension SpeakingTopicAIClient {

    func generateTopic(
        language: GrammarLanguage,
        level: EssayDifficulty,
        length: ConversationLength
    ) async throws -> GeneratedConversationTopic {
        try await generateTopic(
            language: language,
            level: level,
            length: length,
            avoidTitles: []
        )
    }
}
