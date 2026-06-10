import SwiftUI
import Combine

@MainActor
final class WritingViewModel: ObservableObject {

    @Published private(set) var currentWordsToday: Int = 0
    let targetWords: Int

    private let statsService: DailyPracticeStatsService

    var menuItems: [WritingMenuItem] {
        [
            WritingMenuItem(
                title: L10n.string("writingModeSetsTitle"),
                subtitle: L10n.string("writingModeSetsSubtitle"),
                systemImage: "square.grid.2x2.fill",
                accentColor: Color(red: 0.52, green: 0.39, blue: 1.00),
                blobColor: Color(red: 0.90, green: 0.86, blue: 1.00),
                action: .writeFromSets
            ),
            WritingMenuItem(
                title: L10n.string("writingModeEssaysTitle"),
                subtitle: L10n.string("writingModeEssaysSubtitle"),
                systemImage: "note.text.badge.plus",
                accentColor: Color(red: 0.36, green: 0.58, blue: 1.00),
                blobColor: AppColors.blobBlue,
                action: .essays
            )
        ]
    }

    init(statsService: DailyPracticeStatsService = .shared) {
        self.statsService = statsService
        self.targetWords = statsService.defaultGoal(skill: .writing)
    }

    func refreshDailyProgress() {
        Task {
            currentWordsToday = await statsService.totalToday(skill: .writing)
        }
    }
}
