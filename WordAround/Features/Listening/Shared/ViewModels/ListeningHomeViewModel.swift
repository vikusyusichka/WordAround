import Combine
import Foundation

@MainActor
final class ListeningHomeViewModel: ObservableObject {
    @Published var minutesListenedToday: Int = 0
    let dailyGoalMinutes: Int = 15

    var modes: [ListeningMode] { ListeningMode.allModes }
}
