import Foundation

/// Local, deterministic quiz question generator.
/// Thin wrapper around the existing `GrammarQuizGenerator` so the ViewModel
/// can call any generator through the same `GrammarQuizQuestionGenerating`
/// protocol. Does not perform any network or AI calls.
struct LocalGrammarQuizQuestionGenerator: GrammarQuizQuestionGenerating {

    func generateQuestions(
        from note: GrammarNote,
        questionCount: Int,
        allowedTypes: [GrammarQuizQuestionType],
        focusInstructions: String?
    ) async throws -> [GrammarQuizQuestion] {
        let typesSet: Set<GrammarQuizQuestionType> = allowedTypes.isEmpty
            ? Set(GrammarQuizQuestionType.allCases)
            : Set(allowedTypes)

        return try GrammarQuizGenerator.generate(
            from: note.contentBlocks,
            count: max(1, questionCount),
            types: typesSet
        )
    }
}
