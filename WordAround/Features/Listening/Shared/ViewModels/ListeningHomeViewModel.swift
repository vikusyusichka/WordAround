import Combine
import Foundation

@MainActor
final class ListeningHomeViewModel: ObservableObject {
    @Published private(set) var minutesListenedToday: Int = 0
    let dailyGoalMinutes: Int = 15

    private let store: ListeningSessionStoring

    init(store: ListeningSessionStoring? = nil) {
        self.store = store ?? LocalListeningSessionStore.shared
    }

    var modes: [ListeningMode] { ListeningMode.allModes }

    func refreshDailyProgress() {
        Task {
            let sessions = await store.fetchSessions()
            let calendar = Calendar.current
            // Only completed sessions count toward today's progress, and each
            // session id is taken once so resaving a finished session can't
            var seenIds = Set<String>()
            let todaysSeconds = sessions
                .filter { $0.isCompleted && calendar.isDateInToday($0.updatedAt) }
                .reduce(into: 0) { partial, session in
                    guard seenIds.insert(session.id).inserted else { return }
                    partial += session.elapsedSeconds
                }
            minutesListenedToday = todaysSeconds / 60
        }
    }
}
