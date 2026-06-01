import Foundation

struct ListeningMistake: Identifiable, Equatable, Hashable {
    let id: String
    let prompt: String
    let selectedAnswer: String
    let correctAnswer: String
    let explanation: String?
}

struct ListeningResult: Identifiable, Equatable, Hashable {
    let id: String
    let comprehensionPercent: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let listeningTimeSeconds: Int
    let speedLabel: String
    let mistakes: [ListeningMistake]

    var mistakeCount: Int { mistakes.count }
}

struct ListeningQuestion: Identifiable, Equatable {
    let id: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
}
