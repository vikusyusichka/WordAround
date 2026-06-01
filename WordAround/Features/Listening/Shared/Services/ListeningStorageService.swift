import Foundation

final class ListeningStorageService: ListeningSessionStoring {
    func fetchSavedSessions() async -> [ListeningSavedSession] {
        SavedPracticePreviewData.savedSessions
    }
}
