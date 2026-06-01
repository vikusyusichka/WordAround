import Foundation

enum ReadingFromSetPromptBuilder {
    static func build(from request: ReadingFromSetGenerationRequest) -> String {
        var lines: [String] = []

        lines.append("Generate a \(request.difficulty.rawValue) level reading text in \(request.targetLanguage.title).")
        lines.append("Target length: about \(request.effectiveTargetWordCount) words (\(request.length.title.lowercased())), but write longer if needed to include every vocabulary word.")
        lines.append("It is based on the user's flashcard set \"\(request.setTitle)\" (\(request.words.count) words).")
        lines.append("")
        lines.append("Use the following vocabulary from the set (\(request.words.count) words — include ALL of them):")
        lines.append(vocabularyBlock(for: request))
        lines.append("")
        lines.append("CRITICAL: Every vocabulary word listed above must appear at least once in the reading text. Do not skip any word.")
        lines.append(modeInstruction(for: request.generationMode))
        lines.append("Reading focus: \(request.readingFocus.title).")
        lines.append("")
        lines.append("Formatting rules — follow exactly:")
        lines.append("- Return only the reading text.")
        lines.append("- Do not use Markdown.")
        lines.append("- Do not use bold, italics, headings, or bullet points.")
        lines.append("- Do not include vocabulary labels.")
        lines.append("- Do not write translations in parentheses.")
        lines.append("- Do not include placeholders such as \"**Word (Translate)**\" or \"Word (Translate)\".")
        lines.append("- Write normal paragraphs separated by a blank line.")
        lines.append("- The text must be readable, natural, and coherent.")
        lines.append("- Do not include comprehension questions, explanations, intros, or outros.")
        lines.append("")
        lines.append("Example of BAD output: \"**Word (Translate)** Alex opened the app.\"")
        lines.append("Example of GOOD output: \"Alex opened the app and looked at the first flashcard.\"")

        return lines.joined(separator: "\n")
    }

    private static func vocabularyBlock(for request: ReadingFromSetGenerationRequest) -> String {
        request.words.map { word in
            if let translation = word.translation, !translation.isEmpty {
                return "- \(word.term) (\(translation))"
            }
            return "- \(word.term)"
        }.joined(separator: "\n")
    }

    private static func modeInstruction(for mode: ReadingGenerationStyle) -> String {
        switch mode {
        case .strict:
            return "Generation mode — Strict: use the listed vocabulary as the core of the text; every word must appear at least once."
        case .natural:
            return "Generation mode — Natural: weave every listed word into natural, flowing paragraphs."
        case .mixed:
            return "Generation mode — Mixed: balance natural flow with complete coverage — every listed word must appear at least once."
        }
    }
}
