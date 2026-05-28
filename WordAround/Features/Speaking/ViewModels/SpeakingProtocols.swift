import Foundation

// MARK: - Topic Picker

/// Minimum interface ConversationTopicPickerSheetView needs from a speaking ViewModel.
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

// MARK: - Result View

/// Minimum interface ConversationResultView needs from a speaking ViewModel.
protocol SpeakingResultProvidable: ObservableObject {
    var conversationFeedback: SpeakingConversationFeedback? { get }
    var isGeneratingFeedback: Bool { get }
    var feedbackError: String? { get }
    var messages: [SpeakingConversationMessage] { get }
}
