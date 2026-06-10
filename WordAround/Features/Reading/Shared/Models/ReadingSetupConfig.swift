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

    static var readingFromSets: ReadingSetupConfig {
        ReadingSetupConfig(
            modeID: "reading-from-sets",
            title: L10n.string("rfsTitle"),
            subtitle: L10n.string("rfsHeroSubtitle"),
            accent: AppColors.orangeAccent,
            accentDark: AppColors.orangeTitle,
            previewTitle: L10n.string("rfsPreviewTitle"),
            previewSubtitle: L10n.string("rfsPreviewSubtitle"),
            previewIcon: "rectangle.stack.fill",
            ctaTitle: L10n.string("rfsCreateFromSet"),
            ctaIcon: "rectangle.stack.fill",
            sections: [],
            chips: { _, _ in [] }
        )
    }

    static var storyMode: ReadingSetupConfig {
        ReadingSetupConfig(
            modeID: "story-mode",
            title: L10n.string("storyModeTitle"),
            subtitle: L10n.string("readingStoryShortSubtitle"),
            accent: Color(red: 0.93, green: 0.40, blue: 0.60),
            accentDark: Color(red: 0.62, green: 0.18, blue: 0.42),
            previewTitle: L10n.string("storyModeTitle"),
            previewSubtitle: L10n.string("readingStoryPreviewSub"),
            previewIcon: "books.vertical.fill",
            ctaTitle: L10n.string("readingStartStory"),
            ctaIcon: "books.vertical.fill",
            sections: [
                Section(id: "type", title: L10n.string("readingStorySectionType"),
                        kind: .segmented(options: ReadingStoryType.titles, columns: 2, defaultSelection: ReadingStoryType.adventure.title)),
                Section(id: "length", title: L10n.string("readingStorySectionLength"),
                        kind: .segmented(options: ReadingStoryLength.titles, columns: 0, defaultSelection: ReadingStoryLength.shortStory.title)),
                Section(id: "difficulty", title: L10n.string("rfsDifficulty"),
                        kind: .segmented(options: ReadingLevel.titles, columns: 0, defaultSelection: ReadingLevel.b1.title)),
                Section(id: "assistance", title: L10n.string("readingAssistanceSection"),
                        kind: .toggles([
                            ToggleSpec(id: "translationOnTap", title: L10n.string("readingToggleTranslateOnTap"), defaultOn: true),
                            ToggleSpec(id: "highlightUnknownWords", title: L10n.string("readingToggleHighlightUnknown"), defaultOn: true),
                            ToggleSpec(id: "vocabularyHints", title: L10n.string("readingToggleVocabularyHints"), defaultOn: true),
                            ToggleSpec(id: "readingTimer", title: L10n.string("readingToggleReadingTimer"), defaultOn: true)
                        ])),
            ],
            chips: { sel, _ in
                var chips = [sel["type"] ?? "", sel["length"] ?? "", sel["difficulty"] ?? ""]
                if ReadingStoryLength.allCases.first(where: { $0.title == sel["length"] }) != .shortStory {
                    chips.append(L10n.string("readingChipChoices"))
                }
                return chips
            }
        )
    }

    static var speedReading: ReadingSetupConfig {
        ReadingSetupConfig(
            modeID: "speed-reading",
            title: L10n.string("readingSpeedReading"),
            subtitle: L10n.string("readingSpeedSubtitle"),
            accent: Color(red: 0.95, green: 0.42, blue: 0.40),
            accentDark: Color(red: 0.70, green: 0.16, blue: 0.18),
            previewTitle: L10n.string("readingSpeedReading"),
            previewSubtitle: L10n.string("readingSpeedPreviewSub"),
            previewIcon: "bolt.fill",
            ctaTitle: L10n.string("readingStartChallenge"),
            ctaIcon: "bolt.fill",
            sections: [
                Section(id: "target", title: L10n.string("readingSpeedSectionTarget"),
                        kind: .segmented(options: ReadingSpeedTarget.titles, columns: 2, defaultSelection: ReadingSpeedTarget.balanced.title)),
                Section(id: "timer", title: L10n.string("readingSpeedSectionTimer"),
                        kind: .segmented(options: ReadingTimerStyle.titles, columns: 0, defaultSelection: ReadingTimerStyle.soft.title)),
                Section(id: "length", title: L10n.string("readingSpeedSectionLength"),
                        kind: .segmented(options: ReadingSpeedLength.titles, columns: 0, defaultSelection: ReadingSpeedLength.five.title)),
            ],
            chips: { sel, _ in
                let wpm = ReadingSpeedTarget.from(title: sel["target"] ?? "").wpmTarget
                return [sel["target"] ?? "", sel["timer"] ?? "", sel["length"] ?? "", String(format: L10n.string("readingWPMTargetFmt"), wpm)]
            }
        )
    }

    static func make(forModeID id: String) -> ReadingSetupConfig? {
        switch id {
        case "reading-from-sets":   return readingFromSets
        case "story-mode":          return storyMode
        case "speed-reading":       return speedReading
        default:                    return nil
        }
    }
}
