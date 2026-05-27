import Foundation

/// Origin of a `GrammarReviewItem`. Determines:
///  - which icon/label to show on the review card
///  - which "Open …" action is available inside the review session
///  - which deterministic id is used (so the same source never spawns duplicates)
enum GrammarReviewSourceType: String, Codable, CaseIterable, Identifiable, Equatable {
    case note
    case mistake
    case quiz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .note:    return "Note"
        case .mistake: return "Mistake"
        case .quiz:    return "Quiz"
        }
    }

    var systemImage: String {
        switch self {
        case .note:    return "doc.text.fill"
        case .mistake: return "exclamationmark.bubble.fill"
        case .quiz:    return "questionmark.circle.fill"
        }
    }
}
