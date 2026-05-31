import SwiftUI

struct ReadingSetupConfig {

    struct Section: Identifiable {
        let id: String
        let title: String
        var subtitle: String? = nil
        let kind: Kind
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

    let modeID: String
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
    let chips: (_ selections: [String: String], _ toggles: [String: Bool]) -> [String]
}

// MARK: - Per-mode configurations (mock UI data only)

extension ReadingSetupConfig {

    static let generatedReading = ReadingSetupConfig(
        modeID: "generated-reading",
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

    static let readingFromSets = ReadingSetupConfig(
        modeID: "reading-from-sets",
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
        modeID: "story-mode",
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
        modeID: "speed-reading",
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
        modeID: "interactive-reading",
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

    static func make(forModeID id: String) -> ReadingSetupConfig? {
        switch id {
        case "generated-reading":   return generatedReading
        case "reading-from-sets":   return readingFromSets
        case "story-mode":          return storyMode
        case "speed-reading":       return speedReading
        case "interactive-reading": return interactiveReading
        default:                    return nil
        }
    }
}
