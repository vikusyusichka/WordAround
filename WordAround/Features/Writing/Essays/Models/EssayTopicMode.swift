import Foundation

enum EssayTopicMode: String, CaseIterable, Identifiable, Equatable {
    case suggested = "Suggested"
    case custom = "My topic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .suggested: return L10n.string("essayTopicSuggested")
        case .custom:    return L10n.string("essayTopicCustom")
        }
    }
}
