import Foundation

enum ReadingQuestionType: String, Codable, CaseIterable, Equatable {
    case comprehension
    case trueFalse
    case fillGap
    case vocabulary

    var displayTitle: String {
        switch self {
        case .comprehension: return "Comprehension"
        case .trueFalse: return "True / False"
        case .fillGap: return "Fill Gap"
        case .vocabulary: return "Vocabulary"
        }
    }
}

struct ReadingQuestion: Identifiable, Codable, Equatable {
    let id: String
    let type: ReadingQuestionType
    let prompt: String
    let options: [String]
    let correctAnswer: String
    let explanation: String?
    let sourceSentence: String?

    var title: String { type.displayTitle }
}

struct ReadingAnswer: Identifiable, Codable, Equatable {
    let id: String
    let questionId: String
    let selectedAnswer: String
    let isCorrect: Bool

    init(id: String = UUID().uuidString, questionId: String, selectedAnswer: String, isCorrect: Bool) {
        self.id = id
        self.questionId = questionId
        self.selectedAnswer = selectedAnswer
        self.isCorrect = isCorrect
    }
}

struct ReadingMistake: Identifiable, Codable, Equatable {
    let id: String
    let questionId: String
    let prompt: String
    let selectedAnswer: String
    let correctAnswer: String
    let explanation: String?
}

struct ReadingResult: Identifiable, Codable, Equatable {
    let id: String
    let sessionId: String
    let textId: String
    let comprehensionPercent: Double
    let correctAnswers: Int
    let totalQuestions: Int
    let readingTimeSeconds: Int
    let wordsPerMinute: Int
    let mistakes: [ReadingMistake]
    let completedAt: Date

    init(
        id: String = UUID().uuidString,
        sessionId: String,
        textId: String,
        comprehensionPercent: Double,
        correctAnswers: Int,
        totalQuestions: Int,
        readingTimeSeconds: Int,
        wordsPerMinute: Int,
        mistakes: [ReadingMistake],
        completedAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.textId = textId
        self.comprehensionPercent = comprehensionPercent
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.readingTimeSeconds = readingTimeSeconds
        self.wordsPerMinute = wordsPerMinute
        self.mistakes = mistakes
        self.completedAt = completedAt
    }

    var comprehensionPercentInt: Int { Int(comprehensionPercent.rounded()) }
}
