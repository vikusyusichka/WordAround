import Foundation

struct StorySession: Identifiable, Equatable {
    let id: String
    let userId: String
    var configuration: StoryModeConfiguration
    var title: String
    var progress: StoryProgress
    var status: ReadingLibraryItemStatus
    var chapters: [StoryChapter]
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        userId: String,
        configuration: StoryModeConfiguration,
        title: String? = nil,
        progress: StoryProgress = StoryProgress(),
        status: ReadingLibraryItemStatus = .new,
        chapters: [StoryChapter] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.configuration = configuration
        self.title = title ?? configuration.generatedTitle
        self.progress = progress
        self.status = status
        self.chapters = chapters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
    }

    // MARK: - Derived

    var currentChapter: StoryChapter? {
        guard !chapters.isEmpty else { return nil }
        let index = min(max(progress.currentChapterIndex, 0), chapters.count - 1)
        return chapters[index]
    }

    var hasGeneratedContent: Bool {
        chapters.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: - Conversion to/from ReadingLibraryItem

    func toLibraryItem(toggles: [String: Bool] = [:]) -> ReadingLibraryItem {
        ReadingLibraryItem(
            id: id,
            userId: userId,
            modeID: "story-mode",
            title: title,
            preview: storyPreview,
            fullText: Self.encodeChapters(chapters),
            difficulty: configuration.difficultyTitle,
            estimatedMinutes: estimatedMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastOpenedAt: lastOpenedAt,
            progress: progress.overallProgress,
            tags: [configuration.storyType.title, configuration.storyLength.title],
            sourceType: .story,
            status: status,
            selections: configuration.asSelections.merging(progressSelections) { $1 },
            toggles: toggles,
            languageCode: configuration.language.rawValue
        )
    }

    static func from(item: ReadingLibraryItem) -> StorySession {
        let config = StoryModeConfiguration.from(selections: item.selections)
        let chapterIndex = Int(item.selections["currentChapterIndex"] ?? "0") ?? 0
        let completedCount = Int(item.selections["completedChapters"] ?? "0") ?? 0
        let totalTarget = Int(item.selections["totalChapters"] ?? "0") ?? 0

        let progress = StoryProgress(
            currentChapterIndex: chapterIndex,
            completedChaptersCount: completedCount,
            totalChaptersTarget: totalTarget,
            overallProgress: item.progress
        )

        return StorySession(
            id: item.id,
            userId: item.userId,
            configuration: config,
            title: item.title,
            progress: progress,
            status: item.status,
            chapters: decodeChapters(item.fullText),
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            lastOpenedAt: item.lastOpenedAt
        )
    }

    // MARK: - Chapter serialisation (JSON in ReadingLibraryItem.fullText)

    private static func encodeChapters(_ chapters: [StoryChapter]) -> String {
        guard !chapters.isEmpty else { return "" }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(chapters),
              let json = String(data: data, encoding: .utf8) else { return "" }
        return json
    }

    private static func decodeChapters(_ raw: String) -> [StoryChapter] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("["), let data = trimmed.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([StoryChapter].self, from: data)) ?? []
    }

    // MARK: - Private helpers

    private var storyPreview: String {
        if let chapter = currentChapter, !chapter.text.isEmpty {
            return chapter.summary
        }
        return "\(configuration.storyType.title) story — \(configuration.difficultyTitle) level. \(configuration.storyLength.title)."
    }

    private var estimatedMinutes: Int {
        switch configuration.storyLength {
        case .shortStory:   return 5
        case .multiChapter: return 15
        case .infinite:     return 10
        }
    }

    private var progressSelections: [String: String] {
        [
            "currentChapterIndex": String(progress.currentChapterIndex),
            "completedChapters":   String(progress.completedChaptersCount),
            "totalChapters":       String(progress.totalChaptersTarget)
        ]
    }
}
