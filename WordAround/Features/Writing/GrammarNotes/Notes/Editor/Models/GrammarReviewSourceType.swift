import Foundation

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
