import Foundation
import Combine

@MainActor
final class VideoListeningSetupViewModel: ObservableObject {
    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var selectedLevel: EssayDifficulty = .b1
    @Published var selectedLength: ListeningVideoLength = .medium
    @Published var showResults = false

    func findVideos() {
        showResults = true
    }

    func makeSetup() -> ListeningVideoSetup {
        ListeningVideoSetup(
            language: selectedLanguage,
            level: selectedLevel,
            length: selectedLength
        )
    }

    var previewSubtitle: String {
        "We'll find \(selectedLength.rawValue.lowercased()) videos for \(selectedLanguage.title) • \(selectedLevel.title)."
    }

    var previewChips: [String] {
        [selectedLanguage.title, selectedLevel.title, selectedLength.rawValue, "YouTube"]
    }
}
