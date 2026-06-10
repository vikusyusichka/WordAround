import Foundation

enum ReadingFocus: String, Codable, CaseIterable, Equatable {
    case mainIdea
    case vocabulary
    case detailedComprehension
    case grammarAwareness
    case speedFluency

    var title: String {
        switch self {
        case .mainIdea:              return L10n.string("listenMainIdea")
        case .vocabulary:            return L10n.string("spkVocabulary")
        case .detailedComprehension: return L10n.string("readingFocusDetailed")
        case .grammarAwareness:      return L10n.string("readingFocusGrammar")
        case .speedFluency:          return L10n.string("readingFocusSpeed")
        }
    }

    static var titles: [String] { allCases.map(\.title) }

    static func from(title: String) -> ReadingFocus {
        allCases.first { $0.title == title } ?? .mainIdea
    }
}
