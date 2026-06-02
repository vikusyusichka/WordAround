import Foundation

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
