import Foundation

// MARK: - Configuration

/// Single source of truth for the AI quiz backend.
///
/// The iOS app **never** stores an LLM provider API key. Instead it talks
/// to a backend endpoint (Cloud Function, server, etc.) that owns the
/// key and handles prompt construction.
///
/// To enable AI generation:
///  1. Deploy a backend that accepts `GrammarQuizAIRequest` JSON
///     and responds with `GrammarQuizAIResponseDTO` JSON.
///  2. Set `endpointURL` below to that endpoint's URL.
///
/// Until `endpointURL` is set, the app falls back to
/// `UnconfiguredGrammarQuizAIClient`, which produces a clean user-facing
/// "not configured yet" error and never silently fakes AI.
enum GrammarQuizAIConfiguration {

    /// Backend endpoint URL. Leave `nil` until a real backend exists.
    /// Example value (do NOT enable until backend is deployed):
    /// `URL(string: "https://us-central1-myproject.cloudfunctions.net/generateGrammarQuiz")`
    static let endpointURL: URL? = nil

    /// `true` only when `endpointURL` is configured.
    static var isConfigured: Bool { endpointURL != nil }

    /// Returns a real HTTP client when configured, otherwise a safe
    /// unconfigured stub that throws `notConfigured`.
    static func makeClient() -> GrammarQuizAIClient {
        if let url = endpointURL {
            return GrammarQuizAIHTTPClient(endpointURL: url)
        }
        return UnconfiguredGrammarQuizAIClient()
    }
}

// MARK: - AI generator

/// Bridges `GrammarQuizQuestionGenerating` to the backend AI client.
/// Does NOT save anything to Firebase — only returns validated
/// `[GrammarQuizQuestion]` for the ViewModel to persist.
struct AIGrammarQuizQuestionGenerator: GrammarQuizQuestionGenerating {

    let client: GrammarQuizAIClient

    init(client: GrammarQuizAIClient = GrammarQuizAIConfiguration.makeClient()) {
        self.client = client
    }

    func generateQuestions(
        from note: GrammarNote,
        questionCount: Int,
        allowedTypes: [GrammarQuizQuestionType],
        focusInstructions: String?
    ) async throws -> [GrammarQuizQuestion] {
        let request = GrammarQuizAIPromptBuilder.buildRequest(
            note: note,
            questionCount: questionCount,
            allowedTypes: allowedTypes,
            focusInstructions: focusInstructions
        )

        let dto = try await client.generateQuizQuestions(request: request)

        // Map raw DTO -> domain. Validation happens separately in
        // `GrammarQuizQuestionValidator` so we treat AI output as untrusted.
        return dto.questions.enumerated().map { index, raw in
            let resolvedType = GrammarQuizQuestionType(rawValue: raw.type) ?? .shortAnswer
            return GrammarQuizQuestion(
                type: resolvedType,
                questionText: raw.questionText,
                options: raw.options ?? [],
                correctAnswer: raw.correctAnswer,
                explanation: raw.explanation,
                order: index
            )
        }
    }
}
