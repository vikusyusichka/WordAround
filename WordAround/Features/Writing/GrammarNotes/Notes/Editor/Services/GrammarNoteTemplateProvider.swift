import Foundation

struct GrammarNoteTemplateProvider {
    static let shared = GrammarNoteTemplateProvider()

    // `let` so the array is built once, not on every access.
    let templates: [GrammarNoteTemplate] = [
        GrammarNoteTemplate(
            id: "grammar-rule",
            title: "Grammar Rule Template",
            description: "Rule, examples, warning and practice in one clean structure.",
            noteType: .rule,
            languageCode: nil,
            blocks: ordered([
                GrammarNoteBlock(type: .heading,  text: "Rule name"),
                GrammarNoteBlock(type: .rule,     text: "When do we use this rule?", secondaryText: "Formula / pattern"),
                GrammarNoteBlock(type: .example,  text: "Correct example",           secondaryText: "Translation or explanation"),
                GrammarNoteBlock(type: .warning,  text: "Common mistake to avoid"),
                GrammarNoteBlock(type: .exercise, text: "Write 3 sentences using this rule.")
            ])
        ),
        GrammarNoteTemplate(
            id: "mistake-correction",
            title: "Mistake Correction Template",
            description: "Perfect for saving your own mistakes and fixing them properly.",
            noteType: .mistake,
            languageCode: nil,
            blocks: ordered([
                GrammarNoteBlock(type: .heading,   text: "Mistake title"),
                GrammarNoteBlock(type: .quote,     text: "Original sentence with mistake"),
                GrammarNoteBlock(type: .rule,      text: "Corrected sentence", secondaryText: "Why this correction is correct"),
                GrammarNoteBlock(type: .example,   text: "More correct examples"),
                GrammarNoteBlock(type: .checklist, items: ["I understand the mistake", "I can make a similar sentence", "I reviewed it later"])
            ])
        ),
        GrammarNoteTemplate(
            id: "comparison",
            title: "Comparison Template",
            description: "Compare two confusing grammar forms without turning your brain into soup.",
            noteType: .comparison,
            languageCode: nil,
            blocks: ordered([
                GrammarNoteBlock(type: .heading,    text: "A vs B"),
                GrammarNoteBlock(type: .comparison, text: "Form A: meaning and use", secondaryText: "Form B: meaning and use"),
                GrammarNoteBlock(type: .example,    text: "Example for A",            secondaryText: "Example for B"),
                GrammarNoteBlock(type: .warning,    text: "When learners usually mix them up"),
                GrammarNoteBlock(type: .exercise,   text: "Choose A or B in 5 sentences.")
            ])
        ),
        GrammarNoteTemplate(
            id: "cheat-sheet",
            title: "Cheat Sheet Template",
            description: "Short, fast, and useful. A miracle, apparently.",
            noteType: .cheatSheet,
            languageCode: nil,
            blocks: ordered([
                GrammarNoteBlock(type: .heading,    text: "Cheat sheet"),
                GrammarNoteBlock(type: .bulletList, items: ["Key rule", "Useful pattern", "Exception"]),
                GrammarNoteBlock(type: .example,    text: "Quick example"),
                GrammarNoteBlock(type: .divider)
            ])
        ),
        GrammarNoteTemplate(
            id: "verb-tense",
            title: "Verb / Tense Template",
            description: "Conjugation, usage, examples and practice for tenses.",
            noteType: .rule,
            languageCode: nil,
            blocks: ordered([
                GrammarNoteBlock(type: .heading,       text: "Tense name"),
                GrammarNoteBlock(type: .rule,          text: "When to use it", secondaryText: "Structure / conjugation pattern"),
                GrammarNoteBlock(type: .numberedList,  items: ["Subject + verb form", "Negative form", "Question form"]),
                GrammarNoteBlock(type: .example,       text: "Example sentences"),
                GrammarNoteBlock(type: .exercise,      text: "Write your own sentence in this tense.")
            ])
        )
    ]

    func templates(for noteType: GrammarNoteType? = nil) -> [GrammarNoteTemplate] {
        guard let noteType, noteType != .standard else { return templates }
        return templates.filter { $0.noteType == noteType }
    }

    // MARK: - Private
    private static func ordered(_ blocks: [GrammarNoteBlock]) -> [GrammarNoteBlock] {
        blocks.enumerated().map { index, block in
            var copy = block; copy.order = index; return copy
        }
    }
}
