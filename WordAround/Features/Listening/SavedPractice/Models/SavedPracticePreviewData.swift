import Foundation

enum SavedPracticePreviewData {
    static let persistedSessions: [ListeningPersistedSession] = [
        ListeningPersistedSession(
            id: "continue-1",
            modeID: "listen-from-text",
            title: "A Morning in the City",
            language: .english,
            level: .b1,
            createdAt: Date().addingTimeInterval(-86_400),
            updatedAt: Date().addingTimeInterval(-3_600),
            durationSeconds: 180,
            elapsedSeconds: 80,
            progress: 0.45,
            playbackPosition: 80,
            text: ListeningPlaceholderData.sampleText,
            showTextWhileListening: true,
            addQuestions: true,
            questions: ListeningPlaceholderData.sampleQuestions,
            selectedAnswers: ["q1": 1],
            status: .inProgress
        ),
        ListeningPersistedSession(
            id: "saved-2",
            modeID: "import-audio",
            title: "Weekend Travel Podcast",
            language: .english,
            level: .b2,
            createdAt: Date().addingTimeInterval(-3 * 86_400),
            updatedAt: Date().addingTimeInterval(-3 * 86_400),
            durationSeconds: 272,
            elapsedSeconds: 272,
            progress: 1,
            addQuestions: true,
            questions: ListeningPlaceholderData.sampleQuestions,
            selectedAnswers: ["q1": 1, "q2": 1, "q3": 0],
            result: ListeningPlaceholderData.sampleResult,
            status: .completed
        ),
    ]

    static var savedSessions: [ListeningSavedSession] {
        persistedSessions.map { $0.toSavedSession() }
    }

    static var continueSession: ListeningSavedSession {
        persistedSessions.first { $0.isInProgress }!.toSavedSession()
    }
}
