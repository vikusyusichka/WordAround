import SwiftUI
import Combine

@MainActor
final class MyTextsSessionViewModel: ObservableObject {
    let setup: ReadingSessionSetup
    let questions = ReadingPlaceholderData.myTextsQuestions

    @Published var editorText: String = ReadingPlaceholderData.articleBody
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswerIndex: Int? = nil

    init(setup: ReadingSessionSetup) {
        self.setup = setup
    }

    var wordCount: Int {
        editorText.split(whereSeparator: \.isWhitespace).filter { !$0.isEmpty }.count
    }

    var estimatedLevel: String { "B1" }

    var currentQuestion: ReadingPlaceholderData.Question {
        questions[currentQuestionIndex]
    }

    var progressText: String {
        "Question \(currentQuestionIndex + 1) / \(questions.count)"
    }

    var isLastQuestion: Bool {
        currentQuestionIndex >= questions.count - 1
    }

    var sessionSubtitle: String {
        "Custom text • \(setup.selection("questions", default: "Mixed")) questions"
    }

    func clearText() {
        editorText = ""
    }

    func selectAnswer(_ index: Int) {
        selectedAnswerIndex = index
    }

    func goNext() {
        guard currentQuestionIndex < questions.count - 1 else { return }
        currentQuestionIndex += 1
        selectedAnswerIndex = nil
    }

    func finish() {}
}
