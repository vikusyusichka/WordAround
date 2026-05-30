import Foundation

// Lightweight UI option enums for the Reading setup screens.
//
// These are presentation-only: each case maps to a display title. The setup
// view models expose the option lists (via `titles`) and store the selected
// title as a `String`, which keeps the shared selectors simple and generic.
// No persistence, no business logic.

protocol ReadingDisplayOption: CaseIterable {
    var title: String { get }
}

extension ReadingDisplayOption {
    /// Display titles in declaration order — convenient for the selectors.
    static var titles: [String] { allCases.map { $0.title } }
}

enum ReadingLevel: ReadingDisplayOption {
    case a1, a2, b1, b2, c1
    var title: String {
        switch self {
        case .a1: return "A1"
        case .a2: return "A2"
        case .b1: return "B1"
        case .b2: return "B2"
        case .c1: return "C1"
        }
    }
}

enum ReadingLength: ReadingDisplayOption {
    case short, medium, long
    var title: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }
}

enum ReadingTopicOption: ReadingDisplayOption {
    case travel, technology, dailyLife, random, custom
    var title: String {
        switch self {
        case .travel: return "Travel"
        case .technology: return "Technology"
        case .dailyLife: return "Daily Life"
        case .random: return "Random"
        case .custom: return "Custom Topic"
        }
    }
}

enum ReadingTextSource: ReadingDisplayOption {
    case pasteText, savedTexts, importPDF, importImage
    var title: String {
        switch self {
        case .pasteText: return "Paste Text"
        case .savedTexts: return "Saved Texts"
        case .importPDF: return "Import PDF"
        case .importImage: return "Import Image"
        }
    }
}

enum ReadingQuestionMode: ReadingDisplayOption {
    case comprehension, mixed, vocabularyFocus
    var title: String {
        switch self {
        case .comprehension: return "Comprehension"
        case .mixed: return "Mixed"
        case .vocabularyFocus: return "Vocabulary Focus"
        }
    }
}

enum ReadingGenerationStyle: ReadingDisplayOption {
    case natural, strict, mixed
    var title: String {
        switch self {
        case .natural: return "Natural Reading"
        case .strict: return "Strict Vocabulary"
        case .mixed: return "Mixed"
        }
    }

    /// Helper text shown under the generation-style selector.
    var helperText: String {
        switch self {
        case .natural: return "Uses set words in a natural text."
        case .strict: return "Uses mostly words from the selected set."
        case .mixed: return "Balances learned words with new vocabulary."
        }
    }

    static func from(title: String) -> ReadingGenerationStyle {
        allCases.first { $0.title == title } ?? .natural
    }
}

enum ReadingStoryType: ReadingDisplayOption {
    case adventure, fantasy, mystery, romance, dailyLife
    var title: String {
        switch self {
        case .adventure: return "Adventure"
        case .fantasy: return "Fantasy"
        case .mystery: return "Mystery"
        case .romance: return "Romance"
        case .dailyLife: return "Daily Life"
        }
    }
}

enum ReadingStoryLength: ReadingDisplayOption {
    case shortStory, multiChapter, infinite
    var title: String {
        switch self {
        case .shortStory: return "Short Story"
        case .multiChapter: return "Multi Chapter"
        case .infinite: return "Infinite Story"
        }
    }
}

enum ReadingSpeedTarget: ReadingDisplayOption {
    case relaxed, balanced, fast, challenge
    var title: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .balanced: return "Balanced"
        case .fast: return "Fast"
        case .challenge: return "Challenge"
        }
    }

    /// Mock words-per-minute target shown in the preview.
    var wpmTarget: Int {
        switch self {
        case .relaxed: return 180
        case .balanced: return 240
        case .fast: return 320
        case .challenge: return 400
        }
    }

    static func from(title: String) -> ReadingSpeedTarget {
        allCases.first { $0.title == title } ?? .balanced
    }
}

enum ReadingTimerStyle: ReadingDisplayOption {
    case noTimer, soft, strict
    var title: String {
        switch self {
        case .noTimer: return "No Timer"
        case .soft: return "Soft Timer"
        case .strict: return "Strict Timer"
        }
    }
}

enum ReadingSpeedLength: ReadingDisplayOption {
    case two, five, ten
    var title: String {
        switch self {
        case .two: return "2 min"
        case .five: return "5 min"
        case .ten: return "10 min"
        }
    }
}

enum ReadingInteractionMode: ReadingDisplayOption {
    case choosePaths, tapWords, solveTasks, mixed
    var title: String {
        switch self {
        case .choosePaths: return "Choose Paths"
        case .tapWords: return "Tap Words"
        case .solveTasks: return "Solve Tasks"
        case .mixed: return "Mixed"
        }
    }
}

enum ReadingComplexity: ReadingDisplayOption {
    case easy, balanced, challenging
    var title: String {
        switch self {
        case .easy: return "Easy"
        case .balanced: return "Balanced"
        case .challenging: return "Challenging"
        }
    }
}
