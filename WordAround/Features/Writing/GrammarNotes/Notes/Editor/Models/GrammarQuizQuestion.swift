import Foundation

struct GrammarQuizQuestion: Identifiable, Codable, Equatable {
    var id: String
    var type: GrammarQuizQuestionType
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var userAnswer: String?
    var explanation: String?
    var order: Int

    init(
        id: String = UUID().uuidString,
        type: GrammarQuizQuestionType,
        questionText: String,
        options: [String] = [],
        correctAnswer: String,
        userAnswer: String? = nil,
        explanation: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.type = type
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.userAnswer = userAnswer
        self.explanation = explanation
        self.order = order
    }

    var isCorrect: Bool {
        guard let answer = userAnswer else { return false }
        return answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
