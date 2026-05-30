import SwiftUI
import Combine

/// Drives the Reading home/menu screen.
///
/// Menu only — Reading *sessions* are not implemented yet, so all data here is
/// mock/placeholder. The modes are presented as a uniform grid (same principle
/// as `SpeakingView`); each one opens the shared `ReadingSetupView`.
@MainActor
final class ReadingHomeViewModel: ObservableObject {

    // MARK: - Progress (mock placeholder)

    @Published private(set) var minutesReadToday: Int = 6
    @Published private(set) var dailyGoalMinutes: Int = 15

    // MARK: - Modes (mock placeholder)

    @Published private(set) var modes: [ReadingMode] = [
        ReadingMode(
            id: "generated-reading",
            title: "Generated Reading",
            subtitle: "Fresh AI texts at your level — read and learn.",
            systemImage: "sparkles",
            accentColor: ReadingHomeViewModel.indigo,
            blobColor: ReadingHomeViewModel.indigoBlob
        ),
        ReadingMode(
            id: "my-texts",
            title: "My Texts",
            subtitle: "Paste your own text and read it with help.",
            systemImage: "doc.text.fill",
            accentColor: Color(red: 0.13, green: 0.66, blue: 0.74),
            blobColor: Color(red: 0.80, green: 0.94, blue: 0.96)
        ),
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
            subtitle: "Read short stories that adapt to you.",
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
        ReadingMode(
            id: "interactive-reading",
            title: "Interactive Reading",
            subtitle: "Tap words, answer questions, and explore.",
            systemImage: "hand.tap.fill",
            accentColor: AppColors.greenAccent,
            blobColor: AppColors.blobGreen
        ),
    ]

    // MARK: - Theme

    static let indigo = Color(red: 0.42, green: 0.36, blue: 0.86)
    static let indigoBlob = Color(red: 0.88, green: 0.86, blue: 0.98)
}
