import Foundation

struct ReadingSessionService: ReadingSessionServicing, Sendable {
    static let shared = ReadingSessionService()

    private let questionService: ReadingQuestionGenerating
    private let scoringService: ReadingScoringServicing
    private let storage: ReadingMyTextsStorageServicing

    init(
        questionService: ReadingQuestionGenerating = ReadingQuestionService.shared,
        scoringService: ReadingScoringServicing = ReadingScoringService.shared,
        storage: ReadingMyTextsStorageServicing = ReadingMyTextsStorageService.shared
    ) {
        self.questionService = questionService
        self.scoringService = scoringService
        self.storage = storage
    }

    func createSession(from text: ReadingUserText) async -> ReadingSession {
        try? await storage.markInProgress(textId: text.id)
        let maxQuestions = text.readingFocus == .vocabulary ? 8 : 7
        let questions = await questionService.generateQuestions(
            for: text,
            focus: text.readingFocus,
            enabledTypes: text.enabledQuestionTypes,
            maxQuestions: maxQuestions
        )

        return ReadingSession(
            textId: text.id,
            title: text.title,
            content: text.content,
            language: text.language,
            level: text.level,
            wordCount: text.wordCount,
            questions: questions,
            focus: text.readingFocus
        )
    }

    func completeSession(_ session: ReadingSession, answers: [ReadingAnswer], readingTimeSeconds: Int) async -> ReadingResult {
        var mutableSession = session
        mutableSession.answers = answers
        mutableSession.readingTimeSeconds = readingTimeSeconds

        let result = scoringService.score(
            session: mutableSession,
            answers: answers,
            readingTimeSeconds: readingTimeSeconds
        )
        mutableSession.result = result
        mutableSession.completedAt = result.completedAt

        try? await storage.markCompleted(
            textId: session.textId,
            scorePercent: result.comprehensionPercent,
            readingTimeSeconds: readingTimeSeconds
        )

        return result
    }

    func savePartialProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async {
        try? await storage.updateProgress(
            textId: textId,
            progress: progress,
            lastReadCharacterIndex: lastReadCharacterIndex
        )
    }
}
