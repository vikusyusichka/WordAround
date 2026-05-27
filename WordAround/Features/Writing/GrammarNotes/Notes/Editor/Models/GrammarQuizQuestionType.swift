import Foundation

enum GrammarQuizQuestionType: String, Codable, CaseIterable, Identifiable, Equatable {
    case multipleChoice
    case trueFalse
    case fillGap
    case shortAnswer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .trueFalse:      return "True / False"
        case .fillGap:        return "Fill Gap"
        case .shortAnswer:    return "Short Answer"
        }
    }

    var systemImage: String {
        switch self {
        case .multipleChoice: return "list.bullet"
        case .trueFalse:      return "checkmark.circle"
        case .fillGap:        return "pencil.line"
        case .shortAnswer:    return "square.and.pencil"
        }
    }
}
