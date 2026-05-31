import SwiftUI
import Combine

@MainActor
final class ReadingFromSetsSessionViewModel: ObservableObject {
    let setup: ReadingSessionSetup
    let questions = Array(ReadingPlaceholderData.comprehensionQuestions.prefix(6))

    @Published var currentQuestionIndex = 0
    @Published var selectedAnswerIndex: Int? = nil

    init(setup: ReadingSessionSetup) {
        self.setup = setup
    }

    var setName: String { ReadingPlaceholderData.setName }
    var styleLabel: String { setup.selection("style", default: "Natural") }
    var wordsUsed: Int { ReadingPlaceholderData.setWordsIncluded }
    var totalWords: Int { ReadingPlaceholderData.setWordCount }

    var currentQuestion: ReadingPlaceholderData.Question {
        questions[currentQuestionIndex]
    }

    var progressText: String {
        "Set words used: \(wordsUsed) / \(totalWords)"
    }

    var questionProgress: String {
        "Question \(currentQuestionIndex + 1) / \(questions.count)"
    }

    var isLastQuestion: Bool {
        currentQuestionIndex >= questions.count - 1
    }

    func selectAnswer(_ index: Int) {
        selectedAnswerIndex = index
    }

    func goNext() {
        guard currentQuestionIndex < questions.count - 1 else { return }
        currentQuestionIndex += 1
        selectedAnswerIndex = nil
    }
}
