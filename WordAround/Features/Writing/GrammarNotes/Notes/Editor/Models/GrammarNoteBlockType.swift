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
        case .paragraph: return "Text"
        case .heading: return "Heading"
        case .subheading: return "Subheading"
        case .bulletList: return "Bullet List"
        case .numberedList: return "Numbered List"
        case .checklist: return "Checklist"
        case .quote: return "Quote"
        case .rule: return "Rule"
        case .example: return "Example"
        case .warning: return "Warning"
        case .comparison: return "Comparison"
        case .exercise: return "Exercise"
        case .quiz: return "Quiz"
        case .image: return "Image"
        case .divider: return "Divider"
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
        case .paragraph: return "Write your explanation..."
        case .heading: return "Heading"
        case .subheading: return "Subheading"
        case .bulletList, .numberedList, .checklist: return "List item"
        case .quote: return "Original sentence or quote..."
        case .rule: return "Explain the grammar rule..."
        case .example: return "Add examples..."
        case .warning: return "Common mistake or warning..."
        case .comparison: return "First side"
        case .exercise: return "Practice instruction..."
        case .quiz: return "Question"
        case .image: return "Image caption"
        case .divider: return ""
        }
    }

    var subtitle: String {
        switch self {
        case .paragraph: return "Normal note text"
        case .heading: return "Main section title"
        case .subheading: return "Smaller section title"
        case .bulletList: return "Useful unordered points"
        case .numberedList: return "Step-by-step points"
        case .checklist: return "Track rules or mistakes"
        case .quote: return "Sentence worth remembering"
        case .rule: return "Highlighted grammar rule"
        case .example: return "Examples"
        case .warning: return "Common mistake warning"
        case .comparison: return "Compare two forms"
        case .exercise: return "Practice task"
        case .quiz: return "Question block for later quiz"
        case .image: return "Photo with caption"
        case .divider: return "Visual separator"
        }
    }
}
