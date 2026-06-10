import Foundation

enum PronunciationItemType: String, Equatable {
    case word
    case minimalPair
    case phrase
    case sound

    var label: String {
        switch self {
        case .word:        return "Word"
        case .minimalPair: return "Minimal pair"
        case .phrase:      return "Phrase"
        case .sound:       return "Sound"
        }
    }

    var systemImage: String {
        switch self {
        case .word:        return "textformat"
        case .minimalPair: return "arrow.left.arrow.right"
        case .phrase:      return "text.quote"
        case .sound:       return "waveform"
        }
    }
}

enum PronunciationDifficulty: String, CaseIterable, Identifiable, Equatable {
    case easy
    case balanced
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy:     return "Easy"
        case .balanced: return "Balanced"
        case .hard:     return "Hard"
        }
    }
}

enum PronunciationFocus: String, CaseIterable, Identifiable, Equatable {
    case vowels
    case consonants
    case minimalPairs
    case difficultWords
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vowels:         return "Vowels"
        case .consonants:     return "Consonants"
        case .minimalPairs:   return "Minimal pairs"
        case .difficultWords: return "Difficult words"
        case .mixed:          return "Mixed"
        }
    }

    var systemImage: String {
        switch self {
        case .vowels:         return "a.circle.fill"
        case .consonants:     return "b.circle.fill"
        case .minimalPairs:   return "arrow.left.arrow.right.circle.fill"
        case .difficultWords: return "character.book.closed.fill"
        case .mixed:          return "shuffle.circle.fill"
        }
    }

    var promptValue: String {
        switch self {
        case .vowels:         return "vowel sounds"
        case .consonants:     return "consonant sounds"
        case .minimalPairs:   return "minimal pairs"
        case .difficultWords: return "difficult words"
        case .mixed:          return "mixed"
        }
    }
}

struct PronunciationItem: Identifiable, Equatable {
    let id: UUID
    let type: PronunciationItemType
    let text: String
    let translation: String?
    let languageCode: String
    let level: EssayDifficulty
    let difficulty: PronunciationDifficulty
    let focusSound: String?
    let tip: String?
    let example: String?

    init(
        id: UUID = UUID(),
        type: PronunciationItemType,
        text: String,
        translation: String? = nil,
        languageCode: String,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty,
        focusSound: String? = nil,
        tip: String? = nil,
        example: String? = nil
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.translation = translation
        self.languageCode = languageCode
        self.level = level
        self.difficulty = difficulty
        self.focusSound = focusSound
        self.tip = tip
        self.example = example
    }

    var hasExample: Bool { (example?.isEmpty == false) }
}
