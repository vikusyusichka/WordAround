import SwiftUI

/// The stance the learner chooses to defend in a debate. `surpriseMe`
/// is resolved to a concrete `agree`/`disagree` side when the debate
/// starts (see `DebateSession.resolvedSide`).
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

    /// Whether the learner argues *for* the statement. Only meaningful for
    /// the two concrete sides; `surpriseMe` must be resolved first.
    var isForStatement: Bool? {
        switch self {
        case .agree:      return true
        case .disagree:   return false
        case .surpriseMe: return nil
        }
    }

    /// Resolves `surpriseMe` into a concrete side. Concrete sides are
    /// returned unchanged.
    func resolvedConcreteSide() -> DebateSide {
        switch self {
        case .agree, .disagree:
            return self
        case .surpriseMe:
            return Bool.random() ? .agree : .disagree
        }
    }
}
