import Foundation

/// Severity bucket for a review item. Surfaces visually on the review card
/// and can be used by future scheduling tweaks to bias `dueAt` selection.
enum GrammarReviewPriority: String, Codable, CaseIterable, Identifiable, Equatable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:    return "Low"
        case .normal: return "Normal"
        case .high:   return "High"
        }
    }

    var systemImage: String {
        switch self {
        case .low:    return "arrow.down.circle.fill"
        case .normal: return "circle.fill"
        case .high:   return "flame.fill"
        }
    }
}
