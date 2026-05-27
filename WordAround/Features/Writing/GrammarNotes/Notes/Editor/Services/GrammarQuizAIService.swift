import Foundation

// MARK: - Configuration

/// Single source of truth for the AI quiz backend.
///
/// Selection order at call-time:
///   1. **Configured HTTP endpoint** — `endpointURL` set → POST JSON to backend.
///   2. **On-device Apple Intelligence** — `FoundationModels` available → run
///      generation locally with zero config, no API key, no network.
///   3. **Unconfigured stub** — throws `.notConfigured` so the UI shows the
///      clean "not configured yet" hint.
///
/// The iOS app **never** stores an LLM provider API key directly.
enum GrammarQuizAIConfiguration {

    /// Cloudflare Worker URL that proxies Gemini.
    ///
    /// The iOS app stores ONLY this URL — never the Gemini API key, which
    /// lives as a Cloudflare Worker secret (`GEMINI_API_KEY`) deployed via
    /// `wrangler secret put GEMINI_API_KEY`.
    ///
    /// When the network call fails or the Worker is unreachable, the
    /// client throws and `CreateGrammarQuizSheet` shows a friendly
    /// "Use Smart Local Instead" button — local generation always works.
    static let endpointURL: URL? = URL(
        string: "https://wordaround-gemini-proxy.vikusyusichka-ai.workers.dev"
    )

    /// `true` when either a backend endpoint is set OR on-device Apple
    /// Intelligence is available. Drives the AI-section "ready" badge in
    /// `CreateGrammarQuizSheet`. Main-actor isolated because the
    /// on-device availability check is.
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

    /// User-facing description of the active AI backend. Used by the
    /// sheet's status hint so the user knows where their data goes.
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

    /// Returns the best available client. Picks the configured backend
    /// first (explicit user choice), falls back to on-device Apple
    /// Intelligence, and finally to the `notConfigured` stub.
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

// MARK: - AI generator

/// Bridges `GrammarQuizQuestionGenerating` to the backend AI client.
/// Does NOT save anything to Firebase — only returns validated
/// `[GrammarQuizQuestion]` for the ViewModel to persist.
struct AIGrammarQuizQuestionGenerator: GrammarQuizQuestionGenerating {

    let client: GrammarQuizAIClient

    /// `@MainActor` because `GrammarQuizAIConfiguration.makeClient()` is
    /// MainActor — it may construct an on-device client that touches
    /// `SystemLanguageModel`. Using a `nil` default plus body-resolved
    /// fallback avoids calling that MainActor method from the parameter
    /// default expression's evaluation site, which Swift 6 strict
    /// concurrency refuses to do.
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
