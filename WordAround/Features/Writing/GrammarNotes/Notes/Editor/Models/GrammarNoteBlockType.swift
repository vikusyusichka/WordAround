import Foundation

enum GrammarNoteBlockType: String, Codable, CaseIterable, Identifiable, Equatable {
    case paragraph
    case heading
    case subheading
    case bulletList
    case numberedList
    case checklist
    case quote
    case rule
    case example
    case warning
    case comparison
    case exercise
    case quiz
    case image
    case divider

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paragraph: return L10n.string("noteBlockTitleParagraph")
        case .heading: return L10n.string("noteBlockTitleHeading")
        case .subheading: return L10n.string("noteBlockTitleSubheading")
        case .bulletList: return L10n.string("noteBlockTitleBulletList")
        case .numberedList: return L10n.string("noteBlockTitleNumberedList")
        case .checklist: return L10n.string("noteBlockTitleChecklist")
        case .quote: return L10n.string("noteBlockTitleQuote")
        case .rule: return L10n.string("noteBlockTitleRule")
        case .example: return L10n.string("noteBlockTitleExample")
        case .warning: return L10n.string("noteBlockTitleWarning")
        case .comparison: return L10n.string("noteBlockTitleComparison")
        case .exercise: return L10n.string("noteBlockTitleExercise")
        case .quiz: return L10n.string("noteBlockTitleQuiz")
        case .image: return L10n.string("noteBlockTitleImage")
        case .divider: return L10n.string("noteBlockTitleDivider")
        }
    }

    var systemImage: String {
        switch self {
        case .paragraph: return "text.alignleft"
        case .heading: return "textformat.size.larger"
        case .subheading: return "textformat.size"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .checklist: return "checklist"
        case .quote: return "quote.opening"
        case .rule: return "text.book.closed.fill"
        case .example: return "sparkles"
        case .warning: return "exclamationmark.triangle.fill"
        case .comparison: return "arrow.left.arrow.right"
        case .exercise: return "pencil.and.list.clipboard"
        case .quiz: return "questionmark.circle.fill"
        case .image: return "photo.fill"
        case .divider: return "minus"
        }
    }

    var placeholder: String {
        switch self {
        case .paragraph: return L10n.string("noteBlockPhParagraph")
        case .heading: return L10n.string("noteBlockTitleHeading")
        case .subheading: return L10n.string("noteBlockTitleSubheading")
        case .bulletList, .numberedList, .checklist: return L10n.string("noteBlockPhListItem")
        case .quote: return L10n.string("noteBlockPhQuote")
        case .rule: return L10n.string("noteBlockPhRule")
        case .example: return L10n.string("noteBlockPhExample")
        case .warning: return L10n.string("noteBlockPhWarning")
        case .comparison: return L10n.string("noteBlockPhComparisonFirst")
        case .exercise: return L10n.string("noteBlockPhExercise")
        case .quiz: return L10n.string("noteBlockPhQuiz")
        case .image: return L10n.string("noteBlockPhImage")
        case .divider: return ""
        }
    }

    var subtitle: String {
        switch self {
        case .paragraph: return L10n.string("noteBlockSubParagraph")
        case .heading: return L10n.string("noteBlockSubHeading")
        case .subheading: return L10n.string("noteBlockSubSubheading")
        case .bulletList: return L10n.string("noteBlockSubBulletList")
        case .numberedList: return L10n.string("noteBlockSubNumberedList")
        case .checklist: return L10n.string("noteBlockSubChecklist")
        case .quote: return L10n.string("noteBlockSubQuote")
        case .rule: return L10n.string("noteBlockSubRule")
        case .example: return L10n.string("noteBlockSubExample")
        case .warning: return L10n.string("noteBlockSubWarning")
        case .comparison: return L10n.string("noteBlockSubComparison")
        case .exercise: return L10n.string("noteBlockSubExercise")
        case .quiz: return L10n.string("noteBlockSubQuiz")
        case .image: return L10n.string("noteBlockSubImage")
        case .divider: return L10n.string("noteBlockSubDivider")
        }
    }
}
