import Foundation

struct StoryProgress: Codable, Equatable, Hashable {
    var currentChapterIndex: Int
    var completedChaptersCount: Int
    var totalChaptersTarget: Int
    var totalReadingTimeSeconds: Int
    var totalWordsRead: Int
    var overallProgress: Double

    init(
        currentChapterIndex: Int = 0,
        completedChaptersCount: Int = 0,
        totalChaptersTarget: Int = 0,
        totalReadingTimeSeconds: Int = 0,
        totalWordsRead: Int = 0,
        overallProgress: Double = 0
    ) {
        self.currentChapterIndex = currentChapterIndex
        self.completedChaptersCount = completedChaptersCount
        self.totalChaptersTarget = totalChaptersTarget
        self.totalReadingTimeSeconds = totalReadingTimeSeconds
        self.totalWordsRead = totalWordsRead
        self.overallProgress = min(max(overallProgress, 0), 1)
    }

    // MARK: - Display helpers

    var chapterProgressText: String {
        let current = currentChapterIndex + 1
        if totalChaptersTarget > 0 {
            return "Chapter \(current) / \(totalChaptersTarget)"
        }
        return "Chapter \(current)"
    }

    var completedChaptersText: String {
        completedChaptersCount == 1 ? "1 chapter" : "\(completedChaptersCount) chapters"
    }
}
