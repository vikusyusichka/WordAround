import SwiftUI
import Combine

@MainActor
final class InteractiveReadingSessionViewModel: ObservableObject {
    let setup: ReadingSessionSetup

    @Published var selectedWord: String? = "quickly"
    @Published var currentInteractionIndex = 2
    @Published var selectedTaskAnswerIndex: Int? = nil

    init(setup: ReadingSessionSetup) {
        self.setup = setup
    }

    var progressText: String {
        "Interaction \(currentInteractionIndex) / 15"
    }

    var sessionSubtitle: String {
        "\(setup.selection("mode", default: "Mixed interactions")) • \(setup.selection("complexity", default: "Balanced"))"
    }

    var selectedWordMeaning: String {
        switch selectedWord {
        case "quickly": return "at a fast speed"
        case "careful": return "done with attention"
        case "precision": return "exactness"
        case "results": return "outcomes of an action"
        default: return "tap a highlighted word"
        }
    }

    var selectedWordExample: String {
        "She worked quickly through the checklist."
    }

    func selectWord(_ word: String) {
        selectedWord = word
    }

    func selectTaskAnswer(_ index: Int) {
        selectedTaskAnswerIndex = index
    }

    func goNextInteraction() {
        currentInteractionIndex = min(currentInteractionIndex + 1, 15)
    }
}
