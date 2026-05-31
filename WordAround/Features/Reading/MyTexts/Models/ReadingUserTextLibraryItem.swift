import Foundation

// MARK: - Bridge between Firestore `ReadingLibraryItem` and session `ReadingUserText`

extension ReadingUserText {
    init(libraryItem item: ReadingLibraryItem) {
        let level = EssayDifficulty(rawValue: item.difficulty)
            ?? EssayDifficulty(rawValue: item.detectedDifficulty)
            ?? .b1
        let detected = EssayDifficulty(rawValue: item.detectedDifficulty)

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
            readingTimeSeconds: item.readingTimeSeconds
        )
    }

    func toLibraryItem(userId: String) -> ReadingLibraryItem {
        ReadingLibraryItem(
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
            selections: [
                "manualDifficulty": level.rawValue,
                "detectedDifficulty": (detectedLevel ?? level).rawValue
            ],
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
}
