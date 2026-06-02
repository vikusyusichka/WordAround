import SwiftUI

enum DebateSide: String, CaseIterable, Identifiable, Equatable {
    case agree
    case disagree
    case surpriseMe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .agree:      return "Agree"
        case .disagree:   return "Disagree"
        case .surpriseMe: return "Surprise Me"
        }
    }

    var subtitle: String {
        switch self {
        case .agree:      return "Defend the statement"
        case .disagree:   return "Argue against it"
        case .surpriseMe: return "We pick a side for you"
        }
    }

    var systemImage: String {
        switch self {
        case .agree:      return "hand.thumbsup.fill"
        case .disagree:   return "hand.thumbsdown.fill"
        case .surpriseMe: return "shuffle"
        }
    }

    var isForStatement: Bool? {
        switch self {
        case .agree:      return true
        case .disagree:   return false
        case .surpriseMe: return nil
        }
    }

    func resolvedConcreteSide() -> DebateSide {
        switch self {
        case .agree, .disagree:
            return self
        case .surpriseMe:
            return Bool.random() ? .agree : .disagree
        }
    }
}
