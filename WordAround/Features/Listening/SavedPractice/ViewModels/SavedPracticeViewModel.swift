import Combine
import Foundation

@MainActor
final class SavedPracticeViewModel: ObservableObject {
    @Published private(set) var sessions: [ListeningSavedSession] = []

    private let storage: ListeningSessionStoring

    init(storage: ListeningSessionStoring = ListeningStorageService()) {
        self.storage = storage
    }

    var continueSession: ListeningSavedSession? {
        sessions.first(where: \.isInProgress)
    }

    var savedSessionItems: [ListeningSavedSession] {
        sessions.filter { !$0.isInProgress || $0.id != continueSession?.id }
    }

    var isEmpty: Bool { sessions.isEmpty }

    func load() {
        Task {
            sessions = await storage.fetchSavedSessions()
        }
    }
}
