import Foundation

protocol ReadingSessionServicing: Sendable {
    func createSession(from text: ReadingUserText, focus: ReadingFocus?, maxQuestions: Int) async -> ReadingSession
    func completeSession(_ session: ReadingSession, answers: [ReadingAnswer], readingTimeSeconds: Int) async -> ReadingResult
    func savePartialProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async
}

struct ReadingSessionService: ReadingSessionServicing, Sendable {
    static let shared = ReadingSessionService()

    private let questionService: ReadingLocalQuestionGenerating
    private let scoringService: ReadingScoringServicing
    private let storage: ReadingTextStorageServicing

    init(
        questionService: ReadingLocalQuestionGenerating = ReadingLocalQuestionService.shared,
        scoringService: ReadingScoringServicing = ReadingScoringService.shared,
        storage: ReadingTextStorageServicing = ReadingTextStorageService.shared
    ) {
        self.questionService = questionService
        self.scoringService = scoringService
        self.storage = storage
    }

    func createSession(from text: ReadingUserText, focus: ReadingFocus? = nil, maxQuestions: Int = 5) async -> ReadingSession {
        try? await storage.markOpened(textId: text.id)
        let questions = await questionService.generateQuestions(for: text, focus: focus, maxQuestions: maxQuestions)

        return ReadingSession(
            textId: text.id,
            title: text.title,
            content: text.content,
            language: text.language,
            level: text.level,
            wordCount: text.wordCount,
            questions: questions,
            focus: focus
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

        try? await storage.markCompleted(textId: session.textId, score: result.comprehensionPercent)

        return result
    }

    func savePartialProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async {
        try? await storage.updateProgress(
            textId: textId,
            progress: progress,
            lastReadCharacterIndex: lastReadCharacterIndex
        )
    }

    // Legacy synchronous helpers
    func createSession(from text: ReadingUserText) -> ReadingSession {
        let storageSync = ReadingTextStorageService.shared
        if var stored = storageSync.text(withId: text.id) {
            stored.lastOpenedAt = Date()
            stored.updatedAt = Date()
            storageSync.update(stored)
        }
        let questions = ReadingLocalQuestionService.shared.generateQuestions(
            from: text.content,
            title: text.title
        )
        return ReadingSession(
            textId: text.id,
            title: text.title,
            content: text.content,
            language: text.language,
            level: text.level,
            wordCount: text.wordCount,
            questions: questions
        )
    }

    func complete(session: inout ReadingSession, wordCount: Int) -> ReadingResult {
        let result = scoringService.score(session: session, answers: session.answers, readingTimeSeconds: session.readingTimeSeconds)
        session.result = result
        session.completedAt = result.completedAt
        let storageSync = ReadingTextStorageService.shared
        if var stored = storageSync.text(withId: session.textId) {
            stored.progress = 1
            stored.isCompleted = true
            stored.completedSessionsCount += 1
            let prev = stored.averageScore ?? 0
            let count = Double(stored.completedSessionsCount)
            stored.averageScore = ((prev * (count - 1)) + result.comprehensionPercent) / count
            stored.updatedAt = Date()
            storageSync.update(stored)
        }
        return result
    }

    func savePartialProgress(session: ReadingSession, progress: Double) {
        let clamped = min(max(progress, 0), 0.95)
        ReadingTextStorageService.shared.updateProgress(
            textId: session.textId,
            progress: clamped,
            lastReadCharacterIndex: Int(Double(session.content.count) * clamped),
            isCompleted: false
        )
    }
}
