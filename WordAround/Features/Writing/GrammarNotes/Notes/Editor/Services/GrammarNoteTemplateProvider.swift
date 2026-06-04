import Foundation

struct GrammarNoteTemplateProvider {
    static let shared = GrammarNoteTemplateProvider()

    let templates: [GrammarNoteTemplate] = [
        GrammarNoteTemplate(
            id: "grammar-rule",
            title: "Rule Template",
            description: "Rule, examples, warning and practice in one clean structure.",
            noteType: .rule,
            tags: ["rule", "structured"],
            blocks: ordered([
                GrammarNoteBlock(type: .heading,  text: "Rule name"),
                GrammarNoteBlock(type: .rule,     text: "When do we use this rule?", secondaryText: "Formula / pattern"),
                GrammarNoteBlock(type: .example,  text: "Correct example",           secondaryText: "Translation or explanation"),
                GrammarNoteBlock(type: .warning,  text: "Common mistake to avoid"),
                GrammarNoteBlock(type: .exercise, text: "Write 3 sentences using this rule.")
            ]),
            estimatedMinutes: 8,
            difficulty: "A1"
        ),
        GrammarNoteTemplate(
            id: "mistake-correction",
            title: "Mistake Correction Template",
            description: "Perfect for saving your own mistakes and fixing them properly.",
            noteType: .mistake,
            tags: ["mistake", "review"],
            blocks: ordered([
                GrammarNoteBlock(type: .heading,   text: "Mistake title"),
                GrammarNoteBlock(type: .quote,     text: "Original sentence with mistake"),
                GrammarNoteBlock(type: .rule,      text: "Corrected sentence", secondaryText: "Why this correction is correct"),
                GrammarNoteBlock(type: .example,   text: "More correct examples"),
                GrammarNoteBlock(type: .checklist, items: ["I understand the mistake", "I can make a similar sentence", "I reviewed it later"])
            ]),
            estimatedMinutes: 6,
            difficulty: "A2"
        ),
        GrammarNoteTemplate(
            id: "comparison",
            title: "Comparison Template",
            description: "Compare two confusing grammar forms without turning your brain into soup.",
            noteType: .comparison,
            tags: ["comparison", "contrast"],
            blocks: ordered([
                GrammarNoteBlock(type: .heading,    text: "A vs B"),
                GrammarNoteBlock(type: .comparison, text: "Form A: meaning and use", secondaryText: "Form B: meaning and use"),
                GrammarNoteBlock(type: .example,    text: "Example for A",            secondaryText: "Example for B"),
                GrammarNoteBlock(type: .warning,    text: "When learners usually mix them up"),
                GrammarNoteBlock(type: .exercise,   text: "Choose A or B in 5 sentences.")
            ]),
            estimatedMinutes: 10,
            difficulty: "A2"
        ),
        GrammarNoteTemplate(
            id: "cheat-sheet",
            title: "Cheat Sheet Template",
            description: "Short, fast, and useful. A miracle, apparently.",
            noteType: .cheatSheet,
            tags: ["cheat-sheet", "quick"],
            blocks: ordered([
                GrammarNoteBlock(type: .heading,    text: "Cheat sheet"),
                GrammarNoteBlock(type: .bulletList, items: ["Key rule", "Useful pattern", "Common exception"]),
                GrammarNoteBlock(type: .divider),
                GrammarNoteBlock(type: .example,    text: "Quick example")
            ]),
            estimatedMinutes: 4,
            difficulty: "A1"
        ),
        GrammarNoteTemplate(
            id: "verb-tense",
            title: "Verb / Tense Template",
            description: "Conjugation, usage, examples and practice for tenses.",
            noteType: .rule,
            tags: ["verbs", "tense"],
            blocks: ordered([
                GrammarNoteBlock(type: .heading,       text: "Tense name"),
                GrammarNoteBlock(type: .rule,          text: "When to use it", secondaryText: "Structure / conjugation pattern"),
                GrammarNoteBlock(type: .numberedList,  items: ["Subject + verb form", "Negative form", "Question form"]),
                GrammarNoteBlock(type: .example,       text: "Example sentences"),
                GrammarNoteBlock(type: .exercise,      text: "Write your own sentence in this tense.")
            ]),
            estimatedMinutes: 12,
            difficulty: "A2"
        ),
        GrammarNoteTemplate(
            id: "quick-quiz-ready",
            title: "Quick Quiz Ready Template",
            description: "Structured for a one-tap quiz from the rule and example.",
            noteType: .rule,
            tags: ["quiz", "practice"],
            blocks: ordered([
                GrammarNoteBlock(type: .heading,  text: "Rule to quiz"),
                GrammarNoteBlock(type: .rule,     text: "Key rule one-liner", secondaryText: "Why it matters"),
                GrammarNoteBlock(type: .example,  text: "Example to recall"),
                GrammarNoteBlock(type: .quiz,     text: "What is the correct form? Tap to add options later.")
            ]),
            estimatedMinutes: 7,
            difficulty: "A2"
        ),
        GrammarNoteTemplate(
            id: "image-based",
            title: "Image-Based Note Template",
            description: "Add a screenshot or chart, then explain it in your own words.",
            noteType: .standard,
            tags: ["image", "visual"],
            blocks: ordered([
                GrammarNoteBlock(type: .heading,   text: "Note title"),
                GrammarNoteBlock(type: .image,     text: "", imageCaption: "Add a chart, table or screenshot"),
                GrammarNoteBlock(type: .paragraph, text: "Explain what the image shows and why it matters."),
                GrammarNoteBlock(type: .example,   text: "Concrete example using the rule from the image.")
            ]),
            estimatedMinutes: 6,
            difficulty: "A1"
        )
    ]

    func templates(for noteType: GrammarNoteType? = nil) -> [GrammarNoteTemplate] {
        guard let noteType, noteType != .standard else { return templates }
        return templates.filter { $0.noteType == noteType }
    }

    func templates(languageCode: String?) -> [GrammarNoteTemplate] {
        guard let languageCode, !languageCode.isEmpty else { return templates }
        return templates.filter { $0.languageCode == nil || $0.languageCode == languageCode }
    }

    func templates(difficulty: String?) -> [GrammarNoteTemplate] {
        guard let difficulty, !difficulty.isEmpty else { return templates }
        return templates.filter { $0.difficulty.caseInsensitiveCompare(difficulty) == .orderedSame }
    }

    func templates(
        noteType: GrammarNoteType? = nil,
        languageCode: String? = nil,
        difficulty: String? = nil,
        searchQuery: String? = nil
    ) -> [GrammarNoteTemplate] {
        var result = templates
        if let noteType, noteType != .standard {
            result = result.filter { $0.noteType == noteType }
        }
        if let languageCode, !languageCode.isEmpty {
            result = result.filter { $0.languageCode == nil || $0.languageCode == languageCode }
        }
        if let difficulty, !difficulty.isEmpty {
            result = result.filter { $0.difficulty.caseInsensitiveCompare(difficulty) == .orderedSame }
        }
        if let trimmed = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !trimmed.isEmpty {
            result = result.filter { template in
                template.title.lowercased().contains(trimmed)
                || template.description.lowercased().contains(trimmed)
                || template.tags.contains { $0.lowercased().contains(trimmed) }
            }
        }
        return result
    }

    private static func ordered(_ blocks: [GrammarNoteBlock]) -> [GrammarNoteBlock] {
        blocks.enumerated().map { index, block in
            var copy = block; copy.order = index; return copy
        }
    }
}
