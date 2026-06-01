import SwiftUI

enum ReadingFromSetSessionMapper {
    static func userText(from item: ReadingLibraryItem) -> ReadingUserText {
        let cleanText = ReadingTextNormalizationService.normalize(item.fullText)
        let wordCount = item.wordCount > 0
            ? item.wordCount
            : cleanText.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count
        let metadata = item.selections.reduce(into: [String: String]()) { result, pair in
            let prefix = "source."
            guard pair.key.hasPrefix(prefix) else { return }
            result[String(pair.key.dropFirst(prefix.count))] = pair.value
        }

        return ReadingUserText(
            id: item.id,
            title: item.title,
            content: cleanText,
            language: item.language,
            level: EssayDifficulty(rawValue: item.difficulty) ?? .b1,
            wordCount: wordCount,
            estimatedReadingMinutes: max(item.estimatedMinutes, 1),
            preview: item.preview,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            lastOpenedAt: item.lastOpenedAt,
            progress: item.progress,
            isCompleted: item.isCompleted,
            averageScore: item.comprehensionScore,
            readingFocus: ReadingFocus(rawValue: item.readingFocus) ?? .mainIdea,
            sourceType: .flashcardSet,
            status: item.status,
            sourceMetadata: metadata
        )
    }
}

extension ReadingSessionView {
    init(item: ReadingLibraryItem) {
        self.init(userText: ReadingFromSetSessionMapper.userText(from: item))
    }
}
