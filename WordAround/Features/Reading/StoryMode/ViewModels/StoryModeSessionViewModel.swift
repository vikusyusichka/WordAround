import SwiftUI
import Combine

@MainActor
final class StoryModeSessionViewModel: ObservableObject {
    let setup: ReadingSessionSetup

    @Published var selectedAnswerIndex: Int? = nil
    @Published var selectedChoiceIndex: Int? = nil

    init(setup: ReadingSessionSetup) {
        self.setup = setup
    }

    var storyType: String { setup.selection("type", default: "Adventure") }
    var chapterTitle: String { "Chapter 1" }
    var chapterProgress: String { "Chapter 1 / ?" }

    var miniQuestion = "What happened first?"
    var miniOptions = [
        "Elena found a map in the attic.",
        "She met the stranger at noon.",
        "She returned home safely."
    ]

    func selectAnswer(_ index: Int) {
        selectedAnswerIndex = index
    }

    func selectChoice(_ index: Int) {
        selectedChoiceIndex = index
    }
}
