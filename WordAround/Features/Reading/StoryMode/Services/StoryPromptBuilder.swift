import Foundation

enum StoryPromptBuilder {

    static func firstChapterPrompt(configuration: StoryModeConfiguration) -> String {
        var lines: [String] = []
        lines.append("Write the opening \(unitNoun(for: configuration)) of an interactive \(configuration.storyType.title.lowercased()) story in \(configuration.language.title).")
        lines.append(lengthInstruction(for: configuration))
        lines.append(difficultyInstruction(for: configuration))
        lines.append("Introduce a main character and a clear situation. End at a natural decision point so the reader can choose what happens next.")
        lines.append("")
        lines.append(formattingRules)
        return lines.joined(separator: "\n")
    }

    static func nextChapterPrompt(session: StorySession, selectedChoice: StoryChoice) -> String {
        let configuration = session.configuration
        var lines: [String] = []
        lines.append("Continue an interactive \(configuration.storyType.title.lowercased()) story in \(configuration.language.title).")
        lines.append(lengthInstruction(for: configuration))
        lines.append(difficultyInstruction(for: configuration))
        lines.append("")
        lines.append("Story so far:")
        lines.append(storyMemory(for: session))
        lines.append("")
        lines.append("The reader chose: \"\(selectedChoice.label)\".")
        lines.append("Write the next \(unitNoun(for: configuration)) that follows naturally from this choice, keeping characters and tone consistent. End at a new decision point.")
        lines.append("")
        lines.append(formattingRules)
        return lines.joined(separator: "\n")
    }

    static func choicesPrompt(chapterText: String, configuration: StoryModeConfiguration, count: Int) -> String {
        var lines: [String] = []
        lines.append("Based on the \(configuration.storyType.title.lowercased()) story passage below, suggest exactly \(count) distinct things the main character could do next.")
        lines.append("Write each option in \(configuration.language.title), as a short action phrase (3 to 8 words).")
        lines.append("Return only the options, one per line. No numbering, no bullets, no extra text.")
        lines.append("")
        lines.append("Passage:")
        lines.append(chapterText)
        return lines.joined(separator: "\n")
    }

    private static func storyMemory(for session: StorySession) -> String {
        let recents = session.chapters.suffix(3)
        guard !recents.isEmpty else { return "(no previous chapters)" }
        return recents.map { chapter in
            var line = "\(chapter.displayTitle): \(chapter.summary)"
            if let made = chapter.madeChoice {
                line += " (reader chose: \(made.label))"
            }
            return line
        }.joined(separator: "\n")
    }

    private static func unitNoun(for configuration: StoryModeConfiguration) -> String {
        switch configuration.storyLength {
        case .shortStory:   return "short story"
        case .multiChapter: return "chapter"
        case .infinite:     return "episode"
        }
    }

    private static func lengthInstruction(for configuration: StoryModeConfiguration) -> String {
        switch configuration.storyLength {
        case .shortStory:
            return "Target length: about 250-350 words — a single, complete short story with a satisfying ending."
        case .multiChapter:
            return "Target length: about 180-260 words for this chapter — part of a longer, continuing story."
        case .infinite:
            return "Target length: about 160-240 words for this episode — part of an open-ended, continuing story."
        }
    }

    private static func difficultyInstruction(for configuration: StoryModeConfiguration) -> String {
        let level = configuration.difficultyTitle
        switch ReadingLevel.from(title: level) {
        case .a1, .a2:
            return "CEFR level \(level): use short sentences, common everyday vocabulary, and the present tense where possible."
        case .b1, .b2:
            return "CEFR level \(level): use medium-length sentences, common connectors, and a broader everyday vocabulary."
        case .c1:
            return "CEFR level \(level): use natural, varied sentence structures and advanced vocabulary."
        }
    }

    private static let formattingRules: String = {
        [
            "Formatting rules — follow exactly:",
            "- Return only the story text.",
            "- Do not use Markdown, bold, italics, headings, or bullet points.",
            "- Do not write a title or chapter heading.",
            "- Do not list the choices — only write the narrative.",
            "- Write normal paragraphs separated by a blank line.",
            "- Do not include intros, outros, or notes to the reader."
        ].joined(separator: "\n")
    }()
}
