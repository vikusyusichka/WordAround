import Foundation

enum GrammarQuizQuestionType: String, Codable, CaseIterable, Identifiable, Equatable {
    case multipleChoice
    case trueFalse
    case fillGap
    case shortAnswer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .multipleChoice: return L10n.string("notesQTypeMultiple")
        case .trueFalse:      return L10n.string("notesQTypeTrueFalse")
        case .fillGap:        return L10n.string("notesQTypeFillGap")
        case .shortAnswer:    return L10n.string("notesQTypeShortAnswer")
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
