import Foundation

enum ReadingFocus: String, Codable, CaseIterable, Equatable {
    case mainIdea
    case vocabulary
    case detailedComprehension
    case grammarAwareness
    case speedFluency

    var title: String {
        switch self {
        case .mainIdea: return "Main Idea"
        case .vocabulary: return "Vocabulary"
        case .detailedComprehension: return "Detailed Comprehension"
        case .grammarAwareness: return "Grammar Awareness"
        case .speedFluency: return "Speed / Fluency"
        }
    }

    static var titles: [String] { allCases.map(\.title) }

    static func from(title: String) -> ReadingFocus {
        allCases.first { $0.title == title } ?? .mainIdea
    }
}
