import Foundation


protocol SpeakingTopicPickable: ObservableObject {
    var isGeneratingTopic: Bool { get }
    var generatedTopic: GeneratedConversationTopic? { get }
    var topicGenerationError: String? { get }
    var selectedScenario: ConversationScenario? { get }
    var showTopicPicker: Bool { get set }
    var setup: SpeakingConversationSetup { get }
    func generateFreshTopic(forceRefresh: Bool)
    func applyGeneratedTopic()
    func applyStandardScenario(_ scenario: ConversationScenario)
}


protocol SpeakingResultProvidable: ObservableObject {
    var conversationFeedback: SpeakingConversationFeedback? { get }
    var isGeneratingFeedback: Bool { get }
    var feedbackError: String? { get }
    var messages: [SpeakingConversationMessage] { get }
}
