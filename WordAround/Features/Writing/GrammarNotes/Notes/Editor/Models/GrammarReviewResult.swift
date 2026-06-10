import Foundation

enum GrammarReviewResult: String, Codable, CaseIterable, Identifiable, Equatable {
    case forgot
    case hard
    case good
    case easy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forgot: return L10n.string("notesRatingForgot")
        case .hard:   return L10n.string("writeWordsDiffHard")
        case .good:   return L10n.string("notesRatingGood")
        case .easy:   return L10n.string("writeWordsDiffEasy")
        }
    }

    var systemImage: String {
        switch self {
        case .forgot: return "xmark.circle.fill"
        case .hard:   return "exclamationmark.triangle.fill"
        case .good:   return "checkmark.circle.fill"
        case .easy:   return "sparkles"
        }
    }

    var nextInterval: TimeInterval {
        switch self {
        case .forgot: return 4 * 60 * 60
        case .hard:   return 1 * 24 * 60 * 60
        case .good:   return 3 * 24 * 60 * 60
        case .easy:   return 7 * 24 * 60 * 60
        }
    }

    var isCorrect: Bool {
        switch self {
        case .easy, .good: return true
        case .hard, .forgot: return false
        }
    }
}
