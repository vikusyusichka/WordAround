import Foundation

/// User-facing creation mode shown in `CreateGrammarQuizSheet`.
/// Selects which generator (or no generator) the ViewModel will use
/// to produce the questions for a new quiz.
enum GrammarQuizCreationMode: String, CaseIterable, Identifiable, Codable, Equatable {
    case manual
    case smartLocal
    case aiGenerated

    var id: String { rawValue }

    /// Long display title, used as accessible label / subtitle headline.
    var title: String {
        switch self {
        case .manual:      return "Manual"
        case .smartLocal:  return "Smart Local"
        case .aiGenerated: return "AI Generated"
        }
    }

    /// Short label used in segmented controls / compact pickers.
    var shortTitle: String {
        switch self {
        case .manual:      return "Manual"
        case .smartLocal:  return "Smart"
        case .aiGenerated: return "AI"
        }
    }

    var subtitle: String {
        switch self {
        case .manual:      return "Create your own questions"
        case .smartLocal:  return "Generate from note content using local rules"
        case .aiGenerated: return "Generate richer questions with AI"
        }
    }

    var iconName: String {
        switch self {
        case .manual:      return "square.and.pencil"
        case .smartLocal:  return "wand.and.stars"
        case .aiGenerated: return "sparkles"
        }
    }

    /// CTA button title in `CreateGrammarQuizSheet` save button.
    var ctaTitle: String {
        switch self {
        case .manual:      return "Create Quiz"
        case .smartLocal:  return "Generate Quiz"
        case .aiGenerated: return "Generate with AI"
        }
    }
}
