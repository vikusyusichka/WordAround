import Foundation

protocol ReadingScoringServicing: Sendable {
    func score(session: ReadingSession, answers: [ReadingAnswer], readingTimeSeconds: Int) -> ReadingResult
}

struct ReadingScoringService: ReadingScoringServicing, Sendable {
    static let shared = ReadingScoringService()

    func score(session: ReadingSession, answers: [ReadingAnswer], readingTimeSeconds: Int) -> ReadingResult {
        let total = session.questions.count
        let correct = answers.filter(\.isCorrect).count
        let percent: Double = total > 0
            ? (Double(correct) / Double(total)) * 100
            : 0

        let minutes = max(Double(readingTimeSeconds) / 60.0, 1.0 / 60.0)
        let wpm = Int((Double(session.wordCount) / minutes).rounded())

        let mistakes: [ReadingMistake] = answers.compactMap { answer in
            guard !answer.isCorrect,
                  let question = session.questions.first(where: { $0.id == answer.questionId }) else {
                return nil
            }
            return ReadingMistake(
                id: answer.id,
                questionId: question.id,
                prompt: question.prompt,
                selectedAnswer: answer.selectedAnswer,
                correctAnswer: question.correctAnswer,
                explanation: question.explanation
            )
        }

        return ReadingResult(
            sessionId: session.id,
            textId: session.textId,
            comprehensionPercent: percent,
            correctAnswers: correct,
            totalQuestions: total,
            readingTimeSeconds: readingTimeSeconds,
            wordsPerMinute: wpm,
            mistakes: mistakes
        )
    }

    // Legacy
    func score(session: ReadingSession, wordCount: Int) -> ReadingResult {
        score(session: session, answers: session.answers, readingTimeSeconds: session.readingTimeSeconds)
    }
}
