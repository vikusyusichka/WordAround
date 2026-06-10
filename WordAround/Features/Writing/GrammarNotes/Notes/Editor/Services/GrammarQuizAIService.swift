import Foundation

enum GrammarQuizAIConfiguration {

    static let endpointURL: URL? = URL(
        string: "https://wordaround-gemini-proxy.vikusyusichka-ai.workers.dev"
    )

    @MainActor
    static var isConfigured: Bool {
        if endpointURL != nil { return true }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return OnDeviceQuizAI.isAvailable
        }
        #endif
        return false
    }

    @MainActor
    static var statusDescription: String {
        if endpointURL != nil {
            return "AI generation sends note content to your backend."
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), OnDeviceQuizAI.isAvailable {
            return "Generated on-device with Apple Intelligence. Nothing leaves your phone."
        }
        #endif
        return "AI generation requires Apple Intelligence or backend configuration."
    }

    @MainActor
    static func makeClient() -> GrammarQuizAIClient {
        if let url = endpointURL {
            return GrammarQuizAIHTTPClient(endpointURL: url)
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), OnDeviceQuizAI.isAvailable {
            return OnDeviceGrammarQuizAIClient()
        }
        #endif
        return UnconfiguredGrammarQuizAIClient()
    }
}

struct AIGrammarQuizQuestionGenerator: GrammarQuizQuestionGenerating {

    let client: GrammarQuizAIClient

    @MainActor
    init(client: GrammarQuizAIClient? = nil) {
        self.client = client ?? GrammarQuizAIConfiguration.makeClient()
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
