import Foundation

/// Builds the structured request payload that the backend AI endpoint
/// will turn into an LLM prompt. The backend owns the actual prompt
/// engineering and API-key handling. This builder only assembles the
/// note content and quiz parameters in a deterministic, validated way.
enum GrammarQuizAIPromptBuilder {

    /// Backend-facing instruction text. The backend can prepend this to
    /// its system prompt or use it as a contract for what shape the LLM
    /// must produce. Kept here so the iOS app and backend agree on rules.
    static let responseContract: String = """
    Return ONLY a JSON object that matches:
    {"questions":[{"type":"multipleChoice|trueFalse|fillGap|shortAnswer", \
    "questionText":"...","options":["..."],"correctAnswer":"...","explanation":"..."}]}
    Rules:
    - Do not invent grammar unrelated to the provided note content.
    - Avoid vague questions.
    - Every question must have a non-empty correctAnswer.
    - multipleChoice must include exactly 4 distinct options containing the correctAnswer.
    - trueFalse correctAnswer must be exactly "True" or "False" and options must be ["True","False"].
    - fillGap questionText must contain a single blank "_____" and correctAnswer is the missing word.
    - explanation should be one short useful sentence.
    """

    static func buildRequest(
        note: GrammarNote,
        questionCount: Int,
        allowedTypes: [GrammarQuizQuestionType],
        focusInstructions: String?
    ) -> GrammarQuizAIRequest {
        let usableBlocks: [GrammarQuizAIRequest.Block] = note.contentBlocks
            .filter { block in
                !block.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .sorted { $0.order < $1.order }
            .map { block in
                GrammarQuizAIRequest.Block(
                    type: block.type.rawValue,
                    text: block.text,
                    secondaryText: block.secondaryText?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .nonEmptyOrNil,
                    items: block.items.filter { !$0.isEmpty }
                )
            }

        let effectiveTypes: [GrammarQuizQuestionType] = allowedTypes.isEmpty
            ? GrammarQuizQuestionType.allCases
            : allowedTypes

        return GrammarQuizAIRequest(
            noteTitle: note.title.trimmingCharacters(in: .whitespacesAndNewlines),
            noteLanguageCode: note.languageCode.nonEmptyOrNil,
            noteLanguageName: note.languageName.nonEmptyOrNil,
            noteType: note.noteType.rawValue,
            blocks: usableBlocks,
            questionCount: max(1, questionCount),
            allowedTypes: effectiveTypes.map(\.rawValue),
            focusInstructions: focusInstructions?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nonEmptyOrNil
        )
    }
}

// MARK: - File-private string helper

private extension String {
    /// Returns `nil` if the string is empty, otherwise the string itself.
    /// File-private to avoid colliding with similar helpers in other files.
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}
