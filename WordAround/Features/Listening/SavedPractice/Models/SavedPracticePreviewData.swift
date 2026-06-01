import Foundation

enum SavedPracticePreviewData {
    static let continueSession = ListeningSavedSession(
        id: "continue-1",
        title: "A Morning in the City",
        modeTitle: "Listen from Text",
        languageTitle: "English",
        levelTitle: "B1",
        score: nil,
        progress: 0.45,
        status: "In progress",
        dateText: "Yesterday",
        isInProgress: true
    )

    static let savedSessions: [ListeningSavedSession] = [
        continueSession,
        ListeningSavedSession(
            id: "saved-2",
            title: "Weekend Travel Podcast",
            modeTitle: "Import Audio",
            languageTitle: "English",
            levelTitle: "B2",
            score: 78,
            progress: 1,
            status: "Completed",
            dateText: "3 days ago",
            isInProgress: false
        ),
        ListeningSavedSession(
            id: "saved-3",
            title: "Daily Life in Tokyo",
            modeTitle: "Video Listening",
            languageTitle: "English",
            levelTitle: "A2",
            score: 91,
            progress: 1,
            status: "Completed",
            dateText: "Last week",
            isInProgress: false
        )
    ]
}
