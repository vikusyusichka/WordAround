import SwiftUI
import Combine

@MainActor
final class WritingViewModel: ObservableObject {

    @Published private(set) var currentWordsToday: Int = 0
    let targetWords: Int

    private let statsService: DailyPracticeStatsService

    let menuItems: [WritingMenuItem] = [
        WritingMenuItem(
            title: "Write from sets",
            subtitle: "Practice spelling and writing words from your sets.",
            systemImage: "square.grid.2x2.fill",
            accentColor: Color(red: 0.52, green: 0.39, blue: 1.00),
            blobColor: Color(red: 0.90, green: 0.86, blue: 1.00),
            action: .writeFromSets
        ),
        WritingMenuItem(
            title: "Essays",
            subtitle: "Write texts and get AI feedback on grammar and style.",
            systemImage: "note.text.badge.plus",
            accentColor: Color(red: 0.36, green: 0.58, blue: 1.00),
            blobColor: AppColors.blobBlue,
            action: .essays
        ),
        WritingMenuItem(
            title: "Grammar notes",
            subtitle: "Learn grammar with clear notes, examples and mini exercises.",
            systemImage: "book.pages.fill",
            accentColor: AppColors.orangeAccent,
            blobColor: AppColors.blobYellow,
            action: .grammarNotes
        )
    ]

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
