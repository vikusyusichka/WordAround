import Foundation

enum GrammarReviewResult: String, Codable, CaseIterable, Identifiable, Equatable {
    case forgot
    case hard
    case good
    case easy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forgot: return "Forgot"
        case .hard:   return "Hard"
        case .good:   return "Good"
        case .easy:   return "Easy"
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
        case .forgot: return 4 * 60 * 60          // 4 hours
        case .hard:   return 1 * 24 * 60 * 60     // 1 day
        case .good:   return 3 * 24 * 60 * 60     // 3 days
        case .easy:   return 7 * 24 * 60 * 60     // 7 days
        }
    }

    var isCorrect: Bool {
        switch self {
        case .easy, .good: return true
        case .hard, .forgot: return false
        }
    }
}
