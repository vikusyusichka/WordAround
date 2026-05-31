import SwiftUI
import Combine

@MainActor
final class GeneratedReadingSessionViewModel: ObservableObject {
    let setup: ReadingSessionSetup
    let questions = ReadingPlaceholderData.comprehensionQuestions

    @Published var currentQuestionIndex = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var loadingStepIndex = 0

    static let loadingSteps = [
        "Finding a topic...",
        "Creating reading text...",
        "Preparing questions..."
    ]

    init(setup: ReadingSessionSetup) {
        self.setup = setup
    }

    var currentQuestion: ReadingPlaceholderData.Question {
        questions[currentQuestionIndex]
    }

    var progressText: String {
        "\(currentQuestionIndex + 1) / \(questions.count) questions"
    }

    var isLastQuestion: Bool {
        currentQuestionIndex >= questions.count - 1
    }

    var sessionSubtitle: String {
        let level = setup.selection("level", default: "B1")
        let size = setup.selection("size", default: "Medium")
        let topic = setup.selection("topic", default: "Random")
        let topicLabel = topic == ReadingTopicOption.random.title ? "Random topic" : topic
        return "\(level) • \(size) • \(topicLabel)"
    }

    var loadingChips: [String] {
        let level = setup.selection("level", default: "B1")
        let size = setup.selection("size", default: "Medium")
        let topic = setup.selection("topic", default: "Random")
        let topicLabel = topic == ReadingTopicOption.random.title ? "Random topic" : topic
        return [topicLabel, level, size]
    }

    func selectAnswer(_ index: Int) {
        selectedAnswerIndex = index
    }

    func goNext() {
        guard currentQuestionIndex < questions.count - 1 else { return }
        currentQuestionIndex += 1
        selectedAnswerIndex = nil
    }

    func goBack() {
        guard currentQuestionIndex > 0 else { return }
        currentQuestionIndex -= 1
        selectedAnswerIndex = nil
    }

    func advanceLoadingStep() {
        loadingStepIndex = min(loadingStepIndex + 1, Self.loadingSteps.count - 1)
    }
}
