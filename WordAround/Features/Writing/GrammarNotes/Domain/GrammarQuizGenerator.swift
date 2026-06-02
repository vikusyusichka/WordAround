import Foundation
import Combine

enum GrammarQuizGeneratorError: LocalizedError {
    case notEnoughContent
    case noMatchingQuestionTypes

    var errorDescription: String? {
        switch self {
        case .notEnoughContent:
            return "Add more note content before creating a quiz. A quiz needs at least two usable blocks (rule, example, comparison, warning, exercise, paragraph or quote)."
        case .noMatchingQuestionTypes:
            return "Not enough matching content was found for the selected question types. Try enabling more question types or add more note content."
        }
    }
}

enum GrammarQuizGenerator {

    static func generate(
        from blocks: [GrammarNoteBlock],
        count: Int,
        types: Set<GrammarQuizQuestionType>
    ) throws -> [GrammarQuizQuestion] {
        let usable = blocks.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && $0.type != .divider
            && $0.type != .image
            && $0.type != .heading
            && $0.type != .subheading
        }
        guard usable.count >= 2 else {
            throw GrammarQuizGeneratorError.notEnoughContent
        }

        let allTexts: [String] = usable.flatMap { block -> [String] in
            var texts: [String] = [block.text]
            if let s = block.secondaryText, !s.isEmpty { texts.append(s) }
            texts += block.items.filter { !$0.isEmpty }
            return texts
        }.filter { !$0.isEmpty }

        var questions: [GrammarQuizQuestion] = []
        var order = 0

        let prioritized = usable.sorted { priority($0.type) < priority($1.type) }

        for block in prioritized {
            guard questions.count < count else { break }
            if let q = question(from: block, allTexts: allTexts, types: types, order: order) {
                questions.append(q)
                order += 1
            }
        }

        guard !questions.isEmpty else {
            throw GrammarQuizGeneratorError.noMatchingQuestionTypes
        }
        return questions
    }

    private static func priority(_ type: GrammarNoteBlockType) -> Int {
        switch type {
        case .rule:       return 0
        case .warning:    return 1
        case .example:    return 2
        case .comparison: return 3
        case .exercise:   return 4
        case .quote:      return 5
        case .paragraph:  return 6
        default:          return 99
        }
    }

    private static func question(
        from block: GrammarNoteBlock,
        allTexts: [String],
        types: Set<GrammarQuizQuestionType>,
        order: Int
    ) -> GrammarQuizQuestion? {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        switch block.type {
        case .rule:
            return ruleQuestion(block: block, allTexts: allTexts, types: types, order: order)
        case .warning:
            return warningQuestion(block: block, types: types, order: order)
        case .example:
            return exampleQuestion(block: block, types: types, order: order)
        case .comparison:
            return comparisonQuestion(block: block, types: types, order: order)
        case .exercise, .quote, .paragraph:
            return paragraphQuestion(block: block, types: types, order: order)
        default:
            return nil
        }
    }

    private static func ruleQuestion(
        block: GrammarNoteBlock,
        allTexts: [String],
        types: Set<GrammarQuizQuestionType>,
        order: Int
    ) -> GrammarQuizQuestion? {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if types.contains(.multipleChoice) {
            let correct = String(text.prefix(90))
            let distractors = allTexts
                .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines) != text && !$0.isEmpty }
                .prefix(3)
                .map { String($0.prefix(90)) }
            if distractors.count >= 2 {
                let options = ([correct] + distractors).sorted()
                return GrammarQuizQuestion(
                    type: .multipleChoice,
                    questionText: "Which of the following states a correct grammar rule?",
                    options: Array(options.prefix(4)),
                    correctAnswer: correct,
                    explanation: block.secondaryText,
                    order: order
                )
            }
        }

        if types.contains(.shortAnswer) {
            let answer = block.secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty ?? text
            let q = block.secondaryText != nil
                ? "Explain this grammar rule: \"\(String(text.prefix(70)))\""
                : "What does this grammar rule state?"
            return GrammarQuizQuestion(
                type: .shortAnswer,
                questionText: q,
                correctAnswer: String(answer.prefix(140)),
                explanation: block.secondaryText,
                order: order
            )
        }

        return nil
    }

    private static func warningQuestion(
        block: GrammarNoteBlock,
        types: Set<GrammarQuizQuestionType>,
        order: Int
    ) -> GrammarQuizQuestion? {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if types.contains(.trueFalse) {
            return GrammarQuizQuestion(
                type: .trueFalse,
                questionText: "True or False: \"\(String(text.prefix(100)))\" is a common grammar mistake.",
                options: ["True", "False"],
                correctAnswer: "True",
                explanation: text,
                order: order
            )
        }

        if types.contains(.shortAnswer) {
            return GrammarQuizQuestion(
                type: .shortAnswer,
                questionText: "Describe this common grammar mistake.",
                correctAnswer: String(text.prefix(140)),
                order: order
            )
        }

        return nil
    }

    private static func exampleQuestion(
        block: GrammarNoteBlock,
        types: Set<GrammarQuizQuestionType>,
        order: Int
    ) -> GrammarQuizQuestion? {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if types.contains(.fillGap) {
            return fillGapQuestion(text: text, explanation: block.secondaryText, order: order)
        }

        if types.contains(.shortAnswer),
           let secondary = block.secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !secondary.isEmpty {
            return GrammarQuizQuestion(
                type: .shortAnswer,
                questionText: "What does this example illustrate: \"\(String(text.prefix(70)))\"?",
                correctAnswer: String(secondary.prefix(140)),
                order: order
            )
        }

        return nil
    }

    private static func comparisonQuestion(
        block: GrammarNoteBlock,
        types: Set<GrammarQuizQuestionType>,
        order: Int
    ) -> GrammarQuizQuestion? {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let secondary = block.secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if types.contains(.multipleChoice), !secondary.isEmpty {
            let options = ([text, secondary, "Neither applies", "Both are correct"]).sorted()
            return GrammarQuizQuestion(
                type: .multipleChoice,
                questionText: "Which form is used for: \"\(String(text.prefix(60)))\"?",
                options: Array(options.prefix(4)),
                correctAnswer: text,
                explanation: "Compare: \(text) vs \(secondary)",
                order: order
            )
        }

        if types.contains(.shortAnswer) {
            let q = secondary.isEmpty
                ? "When do you use: \"\(String(text.prefix(70)))\"?"
                : "What is the difference between \"\(String(text.prefix(40)))\" and \"\(String(secondary.prefix(40)))\"?"
            return GrammarQuizQuestion(
                type: .shortAnswer,
                questionText: q,
                correctAnswer: secondary.isEmpty ? text : "\(text) vs \(secondary)",
                order: order
            )
        }

        return nil
    }

    private static func paragraphQuestion(
        block: GrammarNoteBlock,
        types: Set<GrammarQuizQuestionType>,
        order: Int
    ) -> GrammarQuizQuestion? {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count > 25 else { return nil }

        if types.contains(.fillGap) {
            return fillGapQuestion(text: text, explanation: nil, order: order)
        }

        if types.contains(.shortAnswer) {
            return GrammarQuizQuestion(
                type: .shortAnswer,
                questionText: "Explain in your own words: \"\(String(text.prefix(80)))\"",
                correctAnswer: String(text.prefix(160)),
                order: order
            )
        }

        return nil
    }

    private static func fillGapQuestion(text: String, explanation: String?, order: Int) -> GrammarQuizQuestion? {
        let words = text.split(separator: " ").map(String.init)
        guard words.count >= 4 else { return nil }

        let skipWords: Set<String> = [
            "a", "an", "the", "is", "are", "was", "were", "to", "in",
            "on", "at", "of", "and", "or", "but", "it", "he", "she",
            "we", "they", "do", "did", "have", "had", "i", "you", "be",
            "not", "this", "that", "with", "for", "as", "by", "from"
        ]

        let candidates = words.indices.filter { i in
            i > 0
            && i < words.count - 1
            && words[i].count > 2
            && !skipWords.contains(words[i].lowercased())
            && words[i].allSatisfy { $0.isLetter || $0.isNumber }
        }

        let gapIndex = candidates.first ?? (words.count / 2)
        let removed = words[gapIndex]

        var filled = words
        filled[gapIndex] = "_____"

        return GrammarQuizQuestion(
            type: .fillGap,
            questionText: "Fill in the gap: \(filled.joined(separator: " "))",
            correctAnswer: removed,
            explanation: explanation,
            order: order
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
