import Foundation

enum ReadingMyTextsPreviewData {
    static let shortText = ReadingUserText(
        title: "Morning Coffee",
        content: "I drink coffee every morning before work.",
        language: .english,
        level: .a1,
        wordCount: 8,
        estimatedReadingMinutes: 1,
        preview: "I drink coffee every morning before work."
    )

    static let mediumText = ReadingUserText(
        title: "A Morning in the City",
        content: """
        Every morning, Maria walks through the bustling streets of Barcelona. The aroma of fresh bread fills the air as cafés open their doors. She passes colourful markets where vendors arrange ripe tomatoes and fragrant herbs.

        Today she has an important meeting downtown. Although the city can feel overwhelming, Maria enjoys observing the rhythm of daily life.
        """,
        language: .english,
        level: .b1,
        wordCount: 52,
        estimatedReadingMinutes: 1,
        preview: "Every morning, Maria walks through the bustling streets of Barcelona. The aroma of fresh bread fills the air…",
        lastOpenedAt: Date().addingTimeInterval(-86400),
        progress: 0.65
    )

    static let completedText = ReadingUserText(
        title: "Weekend Travel Diary",
        content: "We arrived in Lisbon just after sunrise. The tram rattled uphill while pastel buildings glowed in soft light.",
        language: .spanish,
        level: .a2,
        wordCount: 20,
        estimatedReadingMinutes: 1,
        preview: "We arrived in Lisbon just after sunrise…",
        progress: 1,
        isCompleted: true,
        completedSessionsCount: 2,
        averageScore: 82
    )

    static let inProgressText = mediumText

    static let sampleTexts: [ReadingUserText] = [mediumText, completedText, shortText]
}
