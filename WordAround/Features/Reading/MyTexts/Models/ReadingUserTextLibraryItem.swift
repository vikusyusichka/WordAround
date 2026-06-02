import Foundation

private let sourceMetadataPrefix = "source."

extension ReadingUserText {
    init(libraryItem item: ReadingLibraryItem) {
        let level = EssayDifficulty(rawValue: item.difficulty)
            ?? EssayDifficulty(rawValue: item.detectedDifficulty)
            ?? .b1
        let detected = EssayDifficulty(rawValue: item.detectedDifficulty)
        let metadata = Self.extractSourceMetadata(from: item.selections)

        self.init(
            id: item.id,
            title: item.title,
            content: item.fullText,
            language: item.language,
            level: level,
            wordCount: item.wordCount,
            estimatedReadingMinutes: max(1, item.estimatedMinutes),
            preview: item.preview,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            lastOpenedAt: item.lastOpenedAt,
            progress: item.progress,
            lastReadCharacterIndex: item.lastReadCharacterIndex,
            isCompleted: item.isCompleted,
            completedSessionsCount: item.status == .completed ? 1 : 0,
            averageScore: item.comprehensionScore.map { $0 * 100 },
            readingFocus: ReadingFocus(rawValue: item.readingFocus) ?? .mainIdea,
            enabledQuestionTypes: ReadingQuestionType.from(rawValues: item.enabledQuestionTypes),
            assistance: ReadingAssistanceOptions.from(toggles: item.toggles),
            sourceType: item.sourceType,
            detectedLevel: detected,
            characterCount: item.characterCount,
            status: item.status,
            readingTimeSeconds: item.readingTimeSeconds,
            sourceMetadata: metadata
        )
    }

    func toLibraryItem(userId: String) -> ReadingLibraryItem {
        var selections: [String: String] = [
            "manualDifficulty": level.rawValue,
            "detectedDifficulty": (detectedLevel ?? level).rawValue
        ]
        for (key, value) in sourceMetadata {
            selections[sourceMetadataPrefix + key] = value
        }

        return ReadingLibraryItem(
            id: id,
            userId: userId,
            modeID: ReadingMode.myTextsID,
            title: title,
            preview: preview,
            fullText: content,
            difficulty: level.rawValue,
            estimatedMinutes: estimatedReadingMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastOpenedAt: lastOpenedAt,
            progress: progress,
            comprehensionScore: averageScore.map { min(max($0 / 100, 0), 1) },
            tags: [],
            sourceType: sourceType,
            sourceId: nil,
            status: status,
            selections: selections,
            toggles: assistance.asToggleDictionary(),
            languageCode: languageCode,
            wordCount: wordCount,
            characterCount: characterCount,
            detectedDifficulty: (detectedLevel ?? level).rawValue,
            readingFocus: readingFocus.rawValue,
            enabledQuestionTypes: enabledQuestionTypes.map(\.rawValue).sorted(),
            readingTimeSeconds: readingTimeSeconds,
            lastReadCharacterIndex: lastReadCharacterIndex
        )
    }

    private static func extractSourceMetadata(from selections: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in selections where key.hasPrefix(sourceMetadataPrefix) {
            result[String(key.dropFirst(sourceMetadataPrefix.count))] = value
        }
        return result
    }
}
