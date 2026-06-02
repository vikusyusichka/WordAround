import Foundation
import UIKit

protocol ReadingMyTextsStorageServicing: Sendable {
    func currentUserId() -> String?
    func fetchTexts() async throws -> [ReadingUserText]
    func save(_ text: ReadingUserText) async throws
    func update(_ text: ReadingUserText) async throws
    func delete(id: String) async throws
    func markOpened(textId: String) async throws
    func updateProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async throws
    func markInProgress(textId: String) async throws
    func markCompleted(textId: String, scorePercent: Double, readingTimeSeconds: Int) async throws
    func rename(textId: String, newTitle: String) async throws
    func migrateLocalTextsIfNeeded() async
}

protocol ReadingQuestionGenerating: Sendable {
    func generateQuestions(
        for text: ReadingUserText,
        focus: ReadingFocus,
        enabledTypes: Set<ReadingQuestionType>,
        maxQuestions: Int
    ) async -> [ReadingQuestion]
}

protocol ReadingSessionServicing: Sendable {
    func createSession(from text: ReadingUserText) async -> ReadingSession
    func completeSession(_ session: ReadingSession, answers: [ReadingAnswer], readingTimeSeconds: Int) async -> ReadingResult
    func savePartialProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async
}

protocol ReadingScoringServicing: Sendable {
    func score(session: ReadingSession, answers: [ReadingAnswer], readingTimeSeconds: Int) -> ReadingResult
}

protocol ReadingTextAnalyzing: Sendable {
    func analyze(title: String, content: String, language: GrammarLanguage?, manualLevel: EssayDifficulty?) -> ReadingTextAnalysis
    func wordCount(for content: String) -> Int
    func preview(for content: String, maxLength: Int) -> String
    func estimatedReadingMinutes(wordCount: Int) -> Int
    func estimateLevel(for content: String, wordCount: Int) -> EssayDifficulty
    func sentences(from content: String) -> [String]
}

protocol ReadingOCRServicing: Sendable {
    func extractText(from image: UIImage) async throws -> String
}

protocol ReadingPDFImportServicing: Sendable {
    func extractText(from url: URL) throws -> String
}

protocol ReadingTextStorageServicing: Sendable {
    func fetchTexts() async throws -> [ReadingUserText]
    func saveText(_ text: ReadingUserText) async throws
    func updateText(_ text: ReadingUserText) async throws
    func deleteText(id: String) async throws
    func updateProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async throws
    func markCompleted(textId: String, score: Double?) async throws
    func markOpened(textId: String) async throws
}
