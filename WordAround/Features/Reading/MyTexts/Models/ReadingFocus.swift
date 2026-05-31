import Foundation

/// Practice focus chosen when adding a text. Affects local question mix.
enum ReadingFocus: String, Codable, CaseIterable, Equatable {
    case mainIdea
    case vocabulary
    case detailedComprehension

    var title: String {
        switch self {
        case .mainIdea: return "Main idea"
        case .vocabulary: return "Vocabulary"
        case .detailedComprehension: return "Detailed comprehension"
        }
    }

    static var titles: [String] { allCases.map(\.title) }

    static func from(title: String) -> ReadingFocus {
        allCases.first { $0.title == title } ?? .mainIdea
    }
}
