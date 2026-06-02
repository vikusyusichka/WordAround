import SwiftUI
import Combine

@MainActor
final class ReadingHomeViewModel: ObservableObject {

    @Published private(set) var minutesReadToday: Int = 0
    let dailyGoalMinutes: Int

    private let statsService: DailyPracticeStatsService

    init(statsService: DailyPracticeStatsService = .shared) {
        self.statsService = statsService
        self.dailyGoalMinutes = statsService.defaultGoal(skill: .reading)
    }

    func refreshDailyProgress() {
        Task {
            let seconds = await statsService.totalToday(skill: .reading)
            minutesReadToday = seconds / 60
        }
    }

    @Published private(set) var modes: [ReadingMode] = [
        ReadingMyTextsMode.homeCard,
        ReadingMode(
            id: "reading-from-sets",
            title: "Reading From Sets",
            subtitle: "Build a reading from your flashcard sets.",
            systemImage: "rectangle.stack.fill",
            accentColor: AppColors.orangeAccent,
            blobColor: AppColors.blobYellow
        ),
        ReadingMode(
            id: "story-mode",
            title: "Story Mode",
            subtitle: "Read interactive stories with branching choices.",
            systemImage: "books.vertical.fill",
            accentColor: Color(red: 0.93, green: 0.40, blue: 0.60),
            blobColor: AppColors.blobPink
        ),
        ReadingMode(
            id: "speed-reading",
            title: "Speed Reading Mode",
            subtitle: "Train faster reading with timed pacing.",
            systemImage: "bolt.fill",
            accentColor: Color(red: 0.95, green: 0.42, blue: 0.40),
            blobColor: Color(red: 1.0, green: 0.90, blue: 0.90)
        ),
    ]

    static let indigo = Color(red: 0.42, green: 0.36, blue: 0.86)
    static let indigoBlob = Color(red: 0.88, green: 0.86, blue: 0.98)
}
