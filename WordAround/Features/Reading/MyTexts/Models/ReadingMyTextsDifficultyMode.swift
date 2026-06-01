import Foundation

enum ReadingMyTextsDifficultyMode: String, CaseIterable {
    case autoDetect
    case manual

    var title: String {
        switch self {
        case .autoDetect: return "Auto detect"
        case .manual: return "Choose manually"
        }
    }

    static var titles: [String] { allCases.map(\.title) }

    static func from(title: String) -> ReadingMyTextsDifficultyMode {
        allCases.first { $0.title == title } ?? .autoDetect
    }
}

enum ReadingManualLevel: String, CaseIterable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"

    var essayDifficulty: EssayDifficulty {
        switch self {
        case .a1: return .a1
        case .a2: return .a2
        case .b1: return .b1
        case .b2: return .b2
        case .c1: return .c1
        }
    }

    static var titles: [String] { allCases.map(\.rawValue) }

    static func from(title: String) -> ReadingManualLevel {
        allCases.first { $0.rawValue == title } ?? .b1
    }
}
