import SwiftUI

enum GrammarNoteType: String, Codable, CaseIterable, Identifiable, Equatable {
    case standard
    case mistake
    case rule
    case comparison
    case cheatSheet
    case exercise

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .mistake: return "Mistake"
        case .rule: return "Rule"
        case .comparison: return "Comparison"
        case .cheatSheet: return "Cheat Sheet"
        case .exercise: return "Exercise"
        }
    }

    var systemImage: String {
        switch self {
        case .standard: return "doc.text.fill"
        case .mistake: return "exclamationmark.triangle.fill"
        case .rule: return "text.book.closed.fill"
        case .comparison: return "arrow.left.arrow.right"
        case .cheatSheet: return "bolt.fill"
        case .exercise: return "checklist.checked"
        }
    }

    var colorHex: String {
        switch self {
        case .standard: return "#4F7CFF"
        case .mistake: return "#F4729A"
        case .rule: return "#7C5CFF"
        case .comparison: return "#38BDF8"
        case .cheatSheet: return "#F59E0B"
        case .exercise: return "#22C55E"
        }
    }

    var tintColor: Color {
        switch self {
        case .standard:
            return AppColors.primaryBlue
        case .mistake:
            return Color(red: 0.96, green: 0.45, blue: 0.60)
        case .rule:
            return Color(red: 0.49, green: 0.36, blue: 1.00)
        case .comparison:
            return Color(red: 0.22, green: 0.74, blue: 0.97)
        case .cheatSheet:
            return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .exercise:
            return Color(red: 0.13, green: 0.77, blue: 0.37)
        }
    }
}
