import Foundation

enum SpeakingConversationContext: Equatable {
    case scenario(ConversationScenario)
    case generatedTopic(GeneratedConversationTopic)

    var title: String {
        switch self {
        case .scenario(let s):       return s.title
        case .generatedTopic(let t): return t.title
        }
    }

    var description: String {
        switch self {
        case .scenario(let s):       return s.description
        case .generatedTopic(let t): return t.description
        }
    }

    var promptContext: String {
        switch self {
        case .scenario(let s):       return s.promptContext
        case .generatedTopic(let t): return t.promptContext
        }
    }

    var systemImage: String {
        switch self {
        case .scenario(let s):       return s.systemImage
        case .generatedTopic:        return "sparkles"
        }
    }

    var category: String {
        switch self {
        case .scenario(let s):       return s.category
        case .generatedTopic(let t): return t.category
        }
    }

    func firstAIMessage(for language: GrammarLanguage) -> String {
        switch self {
        case .scenario(let s):       return s.suggestedFirstMessage(for: language)
        case .generatedTopic(let t): return t.firstAIMessage
        }
    }
}
