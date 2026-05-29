import Foundation

// MARK: - Category

/// Phrase set categories offered in Shadowing. Presentation metadata
/// (title / systemImage) lives here so pickers and chips stay consistent.
enum ShadowingCategory: String, CaseIterable, Identifiable, Equatable {
    case daily
    case travel
    case cafe
    case interview
    case academic
    case pronunciation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:         return "Daily phrases"
        case .travel:        return "Travel"
        case .cafe:          return "Cafe"
        case .interview:     return "Interview"
        case .academic:      return "Academic"
        case .pronunciation: return "Pronunciation"
        }
    }

    var systemImage: String {
        switch self {
        case .daily:         return "sun.max.fill"
        case .travel:        return "airplane"
        case .cafe:          return "cup.and.saucer.fill"
        case .interview:     return "person.crop.rectangle.fill"
        case .academic:      return "graduationcap.fill"
        case .pronunciation: return "waveform"
        }
    }
}

// MARK: - Phrase

/// A single target phrase the learner listens to and repeats. Pure value
/// type — no business logic. Comparison/scoring lives in `ShadowingAttempt`.
struct ShadowingPhrase: Identifiable, Equatable {
    let id: UUID
    let text: String
    let translation: String?
    let languageCode: String
    let level: EssayDifficulty
    let category: ShadowingCategory
    let tip: String?

    init(
        id: UUID = UUID(),
        text: String,
        translation: String? = nil,
        languageCode: String,
        level: EssayDifficulty,
        category: ShadowingCategory,
        tip: String? = nil
    ) {
        self.id = id
        self.text = text
        self.translation = translation
        self.languageCode = languageCode
        self.level = level
        self.category = category
        self.tip = tip
    }
}
