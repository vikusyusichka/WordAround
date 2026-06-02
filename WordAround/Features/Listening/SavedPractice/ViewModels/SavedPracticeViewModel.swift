import Combine
import Foundation

@MainActor
final class SavedPracticeViewModel: ObservableObject {
    @Published private(set) var sessions: [ListeningPersistedSession] = []

    private let store: ListeningSessionStoring

    init(store: ListeningSessionStoring? = nil) {
        self.store = store ?? LocalListeningSessionStore.shared
    }

    var continueSession: ListeningPersistedSession? {
        sessions.first { $0.status != .completed && $0.result == nil }
    }

    var savedSessions: [ListeningPersistedSession] {
        sessions.filter { $0.id != continueSession?.id }
    }

    var isEmpty: Bool { sessions.isEmpty }

    func load() {
        Task {
            sessions = await store.fetchSessions()
        }
    }

    func delete(_ session: ListeningPersistedSession) {
        Task {
            await store.delete(id: session.id)
            sessions = await store.fetchSessions()
        }
    }
}
