import Foundation

enum GrammarQuizAIPromptBuilder {

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

    static func buildPrompt(from request: GrammarQuizAIRequest) -> String {
        var lines: [String] = []
        lines.append("You are a grammar quiz generator for a language-learning app.")
        lines.append("Stick strictly to the provided note content; never invent grammar unrelated to it.")
        lines.append("")
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
        lines.append("")
        lines.append(responseContract)
        return lines.joined(separator: "\n")
    }
}

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}
