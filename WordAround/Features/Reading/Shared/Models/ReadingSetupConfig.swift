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

extension ReadingSetupConfig {

    static let readingFromSets = ReadingSetupConfig(
        modeID: "reading-from-sets",
        title: "Reading From Sets",
        subtitle: "Build a reading from your flashcard sets.",
        accent: AppColors.orangeAccent,
        accentDark: AppColors.orangeTitle,
        previewTitle: "Reading From Set",
        previewSubtitle: "A reading built from your flashcard vocabulary.",
        previewIcon: "rectangle.stack.fill",
        ctaTitle: "Create From Set",
        ctaIcon: "rectangle.stack.fill",
        sections: [],
        chips: { _, _ in [] }
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
            Section(id: "assistance", title: "Reading assistance",
                    kind: .toggles([
                        ToggleSpec(id: "translationOnTap", title: "Translate on tap", defaultOn: true),
                        ToggleSpec(id: "highlightUnknownWords", title: "Highlight unknown words", defaultOn: true),
                        ToggleSpec(id: "vocabularyHints", title: "Vocabulary hints", defaultOn: true),
                        ToggleSpec(id: "readingTimer", title: "Reading timer", defaultOn: true)
                    ])),
        ],
        chips: { sel, _ in
            var chips = [sel["type"] ?? "", sel["length"] ?? "", sel["difficulty"] ?? ""]
            if ReadingStoryLength.allCases.first(where: { $0.title == sel["length"] }) != .shortStory {
                chips.append("Choices")
            }
            return chips
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

    static func make(forModeID id: String) -> ReadingSetupConfig? {
        switch id {
        case "reading-from-sets":   return readingFromSets
        case "story-mode":          return storyMode
        case "speed-reading":       return speedReading
        default:                    return nil
        }
    }
}
