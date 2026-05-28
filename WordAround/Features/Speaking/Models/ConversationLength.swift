import Foundation

enum ConversationLength: String, CaseIterable, Identifiable, Equatable {
    case short
    case medium
    case long

    var id: String { rawValue }

    var minutes: Int {
        switch self {
        case .short:  return 5
        case .medium: return 10
        case .long:   return 15
        }
    }

    var title: String {
        "\(minutes) min"
    }
}
