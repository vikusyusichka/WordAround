import Foundation

struct SpeedReadingResult: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let base: ReadingResult
    let targetWPM: Int
    let timerViolations: Int
    let rating: SpeedReadingRating
    let completedAt: Date

    init(
        id: String = UUID().uuidString,
        base: ReadingResult,
        targetWPM: Int,
        timerViolations: Int,
        rating: SpeedReadingRating,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.base = base
        self.targetWPM = targetWPM
        self.timerViolations = timerViolations
        self.rating = rating
        self.completedAt = completedAt
    }

    var wordsPerMinute: Int { base.wordsPerMinute }
    var comprehensionPercent: Double { base.comprehensionPercent }
    var comprehensionPercentInt: Int { base.comprehensionPercentInt }
    var readingTimeSeconds: Int { base.readingTimeSeconds }
    var correctAnswers: Int { base.correctAnswers }
    var totalQuestions: Int { base.totalQuestions }
    var mistakes: [ReadingMistake] { base.mistakes }
}
