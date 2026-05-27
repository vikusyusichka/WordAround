import Foundation

/// Protocol that any quiz question generator (local or AI) conforms to.
/// Keeps `GrammarNoteQuizViewModel` decoupled from the specific generation
/// strategy and allows easy mocking in previews/tests.
protocol GrammarQuizQuestionGenerating {
    func generateQuestions(
        from note: GrammarNote,
        questionCount: Int,
        allowedTypes: [GrammarQuizQuestionType],
        focusInstructions: String?
    ) async throws -> [GrammarQuizQuestion]
}
