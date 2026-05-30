import SwiftUI

/// Describes everything that differs between Reading setup screens.
///
/// All six modes share one screen (`ReadingSetupView`); only this data changes
/// per mode — header text, accent, the list of setup sections, the preview and
/// the CTA. No business logic lives here.
struct ReadingSetupConfig {

    struct Section: Identifiable {
        let id: String
        let title: String
        var subtitle: String? = nil
        let kind: Kind
        /// Optional helper text computed from the section's current selection.
        var helper: ((String) -> String)? = nil

        enum Kind {
            case segmented(options: [String], columns: Int, defaultSelection: String)
            case toggles([ToggleSpec])
            case infoCard(title: String, subtitle: String, systemImage: String)
        }
    }

    struct ToggleSpec: Identifiable {
        let id: String
        let title: String
        let defaultOn: Bool
    }

    let title: String
    let subtitle: String
    let accent: Color
    let accentDark: Color
    let previewTitle: String
    let previewSubtitle: String
    let previewIcon: String
    let ctaTitle: String
    let ctaIcon: String
    let sections: [Section]
    /// Builds the preview metadata chips from the current selections/toggles.
    let chips: (_ selections: [String: String], _ toggles: [String: Bool]) -> [String]
}

// MARK: - Per-mode configurations (mock UI data only)

extension ReadingSetupConfig {

    static let generatedReading = ReadingSetupConfig(
        title: "Generated Reading",
        subtitle: "A fresh text created for your level.",
        accent: Color(red: 0.42, green: 0.36, blue: 0.86),
        accentDark: Color(red: 0.28, green: 0.22, blue: 0.62),
        previewTitle: "Generated Reading",
        previewSubtitle: "A fresh text created for your level.",
        previewIcon: "sparkles",
        ctaTitle: "Generate Reading",
        ctaIcon: "sparkles",
        sections: [
            Section(id: "level", title: "Reading Level", subtitle: "Choose text difficulty.",
                    kind: .segmented(options: ReadingLevel.titles, columns: 0, defaultSelection: ReadingLevel.b1.title)),
            Section(id: "topic", title: "Topic",
                    kind: .segmented(options: ReadingTopicOption.titles, columns: 2, defaultSelection: ReadingTopicOption.random.title)),
            Section(id: "size", title: "Reading Size",
                    kind: .segmented(options: ReadingLength.titles, columns: 0, defaultSelection: ReadingLength.medium.title)),
        ],
        chips: { sel, _ in
            let topic = sel["topic"] ?? ""
            let topicChip = (topic == ReadingTopicOption.random.title) ? "Random topic" : topic
            return [sel["level"] ?? "", sel["size"] ?? "", topicChip, "8 questions"]
        }
    )

    static let myTexts = ReadingSetupConfig(
        title: "My Texts",
        subtitle: "Paste your own text and read it with help.",
        accent: Color(red: 0.13, green: 0.66, blue: 0.74),
        accentDark: Color(red: 0.06, green: 0.42, blue: 0.50),
        previewTitle: "Custom Reading",
        previewSubtitle: "Your own text with generated reading practice.",
        previewIcon: "doc.text.fill",
        ctaTitle: "Start Reading",
        ctaIcon: "doc.text.fill",
        sections: [
            Section(id: "source", title: "Text Source",
                    kind: .segmented(options: ReadingTextSource.titles, columns: 2, defaultSelection: ReadingTextSource.pasteText.title)),
            Section(id: "questions", title: "Question Mode",
                    kind: .segmented(options: ReadingQuestionMode.titles, columns: 0, defaultSelection: ReadingQuestionMode.mixed.title)),
            Section(id: "assist", title: "Reading Assist",
                    kind: .toggles([
                        ToggleSpec(id: "translations", title: "Translations", defaultOn: true),
                        ToggleSpec(id: "hints", title: "Hints", defaultOn: false),
                        ToggleSpec(id: "highlight", title: "Highlight difficult words", defaultOn: true),
                    ])),
        ],
        chips: { sel, tog in
            [sel["source"] ?? "", "\(sel["questions"] ?? "") questions", (tog["highlight"] ?? false) ? "Highlights on" : "Highlights off"]
        }
    )

    static let readingFromSets = ReadingSetupConfig(
        title: "Reading From Sets",
        subtitle: "Build a reading from your flashcard sets.",
        accent: AppColors.orangeAccent,
        accentDark: AppColors.orangeTitle,
        previewTitle: "Reading From Set",
        previewSubtitle: "A reading built from your flashcard vocabulary.",
        previewIcon: "rectangle.stack.fill",
        ctaTitle: "Generate Reading",
        ctaIcon: "rectangle.stack.fill",
        sections: [
            Section(id: "set", title: "Choose Set",
                    kind: .infoCard(title: "Travel Vocabulary", subtitle: "55 words", systemImage: "rectangle.stack.fill")),
            Section(id: "style", title: "Generation Style",
                    kind: .segmented(options: ReadingGenerationStyle.titles, columns: 2, defaultSelection: ReadingGenerationStyle.natural.title),
                    helper: { ReadingGenerationStyle.from(title: $0).helperText }),
            Section(id: "length", title: "Reading Length",
                    kind: .segmented(options: ReadingLength.titles, columns: 0, defaultSelection: ReadingLength.medium.title)),
        ],
        chips: { sel, _ in
            let short: String
            switch ReadingGenerationStyle.from(title: sel["style"] ?? "") {
            case .natural: short = "Natural"
            case .strict: short = "Strict"
            case .mixed: short = "Mixed"
            }
            return ["Travel Vocabulary", "55 words", short, sel["length"] ?? ""]
        }
    )

    static let storyMode = ReadingSetupConfig(
        title: "Story Mode",
        subtitle: "Read short stories that adapt to you.",
        accent: Color(red: 0.93, green: 0.40, blue: 0.60),
        accentDark: Color(red: 0.62, green: 0.18, blue: 0.42),
        previewTitle: "Story Mode",
        previewSubtitle: "Read a short story and continue through choices.",
        previewIcon: "books.vertical.fill",
        ctaTitle: "Start Story",
        ctaIcon: "books.vertical.fill",
        sections: [
            Section(id: "type", title: "Story Type",
                    kind: .segmented(options: ReadingStoryType.titles, columns: 2, defaultSelection: ReadingStoryType.adventure.title)),
            Section(id: "length", title: "Story Length",
                    kind: .segmented(options: ReadingStoryLength.titles, columns: 0, defaultSelection: ReadingStoryLength.shortStory.title)),
            Section(id: "difficulty", title: "Difficulty",
                    kind: .segmented(options: ReadingLevel.titles, columns: 0, defaultSelection: ReadingLevel.b1.title)),
        ],
        chips: { sel, _ in
            [sel["type"] ?? "", sel["length"] ?? "", sel["difficulty"] ?? "", "Choices"]
        }
    )

    static let speedReading = ReadingSetupConfig(
        title: "Speed Reading",
        subtitle: "Train faster reading with timed pacing.",
        accent: Color(red: 0.95, green: 0.42, blue: 0.40),
        accentDark: Color(red: 0.70, green: 0.16, blue: 0.18),
        previewTitle: "Speed Reading",
        previewSubtitle: "Train reading pace with timed practice.",
        previewIcon: "bolt.fill",
        ctaTitle: "Start Challenge",
        ctaIcon: "bolt.fill",
        sections: [
            Section(id: "target", title: "Reading Speed Target",
                    kind: .segmented(options: ReadingSpeedTarget.titles, columns: 2, defaultSelection: ReadingSpeedTarget.balanced.title)),
            Section(id: "timer", title: "Timer Style",
                    kind: .segmented(options: ReadingTimerStyle.titles, columns: 0, defaultSelection: ReadingTimerStyle.soft.title)),
            Section(id: "length", title: "Reading Length",
                    kind: .segmented(options: ReadingSpeedLength.titles, columns: 0, defaultSelection: ReadingSpeedLength.five.title)),
        ],
        chips: { sel, _ in
            let wpm = ReadingSpeedTarget.from(title: sel["target"] ?? "").wpmTarget
            return [sel["target"] ?? "", sel["timer"] ?? "", sel["length"] ?? "", "\(wpm) WPM target"]
        }
    )

    static let interactiveReading = ReadingSetupConfig(
        title: "Interactive Reading",
        subtitle: "Tap words, answer questions, and explore.",
        accent: AppColors.greenAccent,
        accentDark: AppColors.greenTitle,
        previewTitle: "Interactive Reading",
        previewSubtitle: "Read, tap, choose, and answer as the text evolves.",
        previewIcon: "hand.tap.fill",
        ctaTitle: "Start Interactive Reading",
        ctaIcon: "hand.tap.fill",
        sections: [
            Section(id: "mode", title: "Interaction Mode",
                    kind: .segmented(options: ReadingInteractionMode.titles, columns: 2, defaultSelection: ReadingInteractionMode.mixed.title)),
            Section(id: "complexity", title: "Complexity",
                    kind: .segmented(options: ReadingComplexity.titles, columns: 0, defaultSelection: ReadingComplexity.balanced.title)),
            Section(id: "length", title: "Length",
                    kind: .segmented(options: ReadingLength.titles, columns: 0, defaultSelection: ReadingLength.short.title)),
        ],
        chips: { sel, _ in
            [sel["mode"] ?? "", sel["complexity"] ?? "", sel["length"] ?? "", "15 interactions"]
        }
    )

    /// Config for a home-menu mode id (matches `ReadingMode.id`).
    static func make(forModeID id: String) -> ReadingSetupConfig? {
        switch id {
        case "generated-reading":   return generatedReading
        case "my-texts":            return myTexts
        case "reading-from-sets":   return readingFromSets
        case "story-mode":          return storyMode
        case "speed-reading":       return speedReading
        case "interactive-reading": return interactiveReading
        default:                    return nil
        }
    }
}
