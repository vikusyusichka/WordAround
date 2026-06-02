import Foundation

enum GrammarQuizCreationMode: String, CaseIterable, Identifiable, Codable, Equatable {
    case manual
    case smartLocal
    case aiGenerated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:      return "Manual"
        case .smartLocal:  return "Smart Local"
        case .aiGenerated: return "AI Generated"
        }
    }

    var shortTitle: String {
        switch self {
        case .manual:      return "Manual"
        case .smartLocal:  return "Smart"
        case .aiGenerated: return "AI"
        }
    }

    var subtitle: String {
        switch self {
        case .manual:      return "Write your own questions."
        case .smartLocal:  return "Generate questions from note content locally."
        case .aiGenerated: return "Generate richer contextual questions using AI."
        }
    }

    var iconName: String {
        switch self {
        case .manual:      return "square.and.pencil"
        case .smartLocal:  return "wand.and.stars"
        case .aiGenerated: return "sparkles"
        }
    }

    var ctaTitle: String {
        switch self {
        case .manual:      return "Create Quiz"
        case .smartLocal:  return "Save Quiz"
        case .aiGenerated: return "Generate Quiz"
        }
    }
}
