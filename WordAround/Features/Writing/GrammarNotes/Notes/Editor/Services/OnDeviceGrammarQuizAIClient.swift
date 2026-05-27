import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)

// MARK: - Guided-generation schema (file scope)

/// Apple's `@Generable` macro generates a runtime `GenerationSchema` that
/// the FoundationModels framework constructs from OUTSIDE this file when
/// `session.respond(to:, generating:)` is invoked. That means the type
/// must be at least `internal` — `fileprivate`/`private` break the schema
/// resolution with "is inaccessible due to ..." errors.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct OnDeviceQuizPayload {
    @Guide(description: "Quiz questions in the order they should appear.")
    let questions: [OnDeviceQuizQuestion]
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct OnDeviceQuizQuestion {
    @Guide(description: "One of: multipleChoice, trueFalse, fillGap, shortAnswer.")
    let type: String

    @Guide(description: "The question as the learner will see it. For fillGap, include the blank ___.")
    let questionText: String

    @Guide(description: "For multipleChoice: 4 distinct options including the correct one. For trueFalse: [\"True\", \"False\"]. For fillGap/shortAnswer: empty array.")
    let options: [String]

    @Guide(description: "The correct answer. For multipleChoice must match one of the options.")
    let correctAnswer: String

    @Guide(description: "One short useful sentence explaining the answer.")
    let explanation: String
}

// MARK: - Client

/// On-device AI quiz generator powered by Apple Intelligence
/// (`FoundationModels`). Zero configuration: no API key, no backend,
/// no network — the model runs locally on the user's device.
///
/// `@MainActor` because `SystemLanguageModel.default` and
/// `LanguageModelSession` are themselves main-actor isolated. Calling
/// sites already live on the main actor (view models / views), so this
/// is the cheapest correct annotation.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
final class OnDeviceGrammarQuizAIClient: GrammarQuizAIClient {

    init() {}

    nonisolated func generateQuizQuestions(
        request: GrammarQuizAIRequest
    ) async throws -> GrammarQuizAIResponseDTO {
        // Hop to main actor to touch the `FoundationModels` types, which
        // are themselves `@MainActor` isolated. The HTTP path doesn't
        // need this, but on-device generation requires it.
        try await MainActor.run {
            try Self.assertAvailable()
        }

        return try await self.run(request: request)
    }

    private func run(
        request: GrammarQuizAIRequest
    ) async throws -> GrammarQuizAIResponseDTO {
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: Instructions(Self.systemInstructions)
        )

        let prompt = Self.makeUserPrompt(request: request)

        do {
            let response = try await session.respond(
                to: prompt,
                generating: OnDeviceQuizPayload.self
            )
            return Self.convert(response.content)
        } catch {
            #if DEBUG
            print("[OnDeviceAI] generation failed:", error)
            #endif
            throw GrammarQuizAIClientError.invalidResponse
        }
    }

    private static func assertAvailable() throws {
        guard case .available = SystemLanguageModel.default.availability else {
            throw GrammarQuizAIClientError.notConfigured
        }
    }

    // MARK: - Prompt construction

    /// Shared system prompt — uses the same response contract as the HTTP
    /// path so both backends produce comparable output shapes.
    private static let systemInstructions: String = """
        You are a grammar quiz generator that produces structured JSON for a
        language-learning app. Stick strictly to the provided note content;
        never invent grammar unrelated to it. Avoid vague questions. Every
        question must have a non-empty correctAnswer.

        \(GrammarQuizAIPromptBuilder.responseContract)
        """

    /// Per-call user prompt — formatted as a short briefing rather than
    /// JSON so the on-device model has the easiest time understanding it.
    private static func makeUserPrompt(request: GrammarQuizAIRequest) -> String {
        var lines: [String] = []
        lines.append("Note title: \(request.noteTitle)")
        if let lang = request.noteLanguageName, !lang.isEmpty {
            lines.append("Target language: \(lang)")
        }
        if let type = request.noteType, !type.isEmpty {
            lines.append("Note type: \(type)")
        }
        if let focus = request.focusInstructions, !focus.isEmpty {
            lines.append("Focus: \(focus)")
        }
        lines.append("Generate exactly \(request.questionCount) questions using only these types: \(request.allowedTypes.joined(separator: ", ")).")
        lines.append("")
        lines.append("Note content blocks:")
        for block in request.blocks {
            var entry = "- [\(block.type)] \(block.text)"
            if let secondary = block.secondaryText, !secondary.isEmpty {
                entry += " — alt: \(secondary)"
            }
            if !block.items.isEmpty {
                entry += " — items: \(block.items.joined(separator: " / "))"
            }
            lines.append(entry)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Conversion

    private static func convert(_ payload: OnDeviceQuizPayload) -> GrammarQuizAIResponseDTO {
        let questions = payload.questions.map { raw in
            GrammarQuizAIResponseDTO.Question(
                type: raw.type,
                questionText: raw.questionText,
                options: raw.options.isEmpty ? nil : raw.options,
                correctAnswer: raw.correctAnswer,
                explanation: raw.explanation.isEmpty ? nil : raw.explanation
            )
        }
        return GrammarQuizAIResponseDTO(questions: questions)
    }
}

// MARK: - Availability check

@available(iOS 26.0, macOS 26.0, *)
@MainActor
enum OnDeviceQuizAI {
    /// `true` when Apple Intelligence is set up and the system language
    /// model is ready to serve requests. Main-actor isolated because
    /// `SystemLanguageModel.availability` itself is.
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }
}

#endif
