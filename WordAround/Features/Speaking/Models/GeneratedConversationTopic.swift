import Foundation

struct GeneratedConversationTopic: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let description: String
    let firstAIMessage: String
    let promptContext: String
    let category: String

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        firstAIMessage: String,
        promptContext: String,
        category: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.firstAIMessage = firstAIMessage
        self.promptContext = promptContext
        self.category = category
    }
}

struct GeneratedConversationTopicCacheKey: Hashable {
    let language: GrammarLanguage
    let level: EssayDifficulty
    let length: ConversationLength
}
