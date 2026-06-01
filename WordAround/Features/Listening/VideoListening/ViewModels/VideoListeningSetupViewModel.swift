import Combine
import Foundation

@MainActor
final class VideoListeningSetupViewModel: ObservableObject {
    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var selectedLevel: EssayDifficulty = .b1
    @Published var topicQuery = ""
    @Published var selectedLength: ListeningVideoLength = .medium
    @Published var showResults = false

    let suggestedTopics = ["Daily life", "Travel", "Food", "Work", "Culture", "News", "Stories"]

    func makeSetup() -> ListeningVideoSetup {
        ListeningVideoSetup(
            language: selectedLanguage,
            level: selectedLevel,
            topic: topicQuery.isEmpty ? "Daily life" : topicQuery,
            length: selectedLength
        )
    }

    var previewSubtitle: String {
        "We'll find videos for \(selectedLanguage.title) • \(selectedLevel.title) based on your topic."
    }

    var previewChips: [String] {
        [selectedLanguage.title, selectedLevel.title, selectedLength.rawValue, "YouTube"]
    }
}
