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
            let todaysSeconds = sessions
                .filter { calendar.isDateInToday($0.updatedAt) }
                .reduce(0) { $0 + $1.elapsedSeconds }
            minutesListenedToday = todaysSeconds / 60
        }
    }
}
