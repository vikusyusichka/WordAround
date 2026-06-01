import Foundation

struct ListeningMistake: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let prompt: String
    let selectedAnswer: String
    let correctAnswer: String
    let explanation: String?
    var questionType: ListeningQuestionType = .details
}

struct ListeningResult: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let comprehensionPercent: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let listeningTimeSeconds: Int
    let speedLabel: String
    let mistakes: [ListeningMistake]
    /// `false` for watch-only sessions (e.g. a captionless video) where no
    /// comprehension score should be shown — only a "practice completed" state.
    var hasQuestions: Bool = true

    var mistakeCount: Int { mistakes.count }
}

struct ListeningQuestion: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    var type: ListeningQuestionType = .details
    var explanation: String? = nil

    var correctAnswer: String {
        options.indices.contains(correctIndex) ? options[correctIndex] : ""
    }
}
