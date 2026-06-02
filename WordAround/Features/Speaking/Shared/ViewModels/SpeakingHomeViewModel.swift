import Combine
import Foundation

@MainActor
final class SpeakingHomeViewModel: ObservableObject {
    @Published private(set) var minutesSpokenToday: Int = 0
    let dailyGoalMinutes: Int

    private let statsService: DailyPracticeStatsService

    init(statsService: DailyPracticeStatsService = .shared) {
        self.statsService = statsService
        self.dailyGoalMinutes = statsService.defaultGoal(skill: .speaking)
    }

    func refreshDailyProgress() {
        Task {
            let seconds = await statsService.totalToday(skill: .speaking)
            minutesSpokenToday = seconds / 60
        }
    }
}
