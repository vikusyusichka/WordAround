import SwiftUI

@MainActor
final class WritingSetSelectionViewModel: ObservableObject {
    @Published private(set) var sets: [FlashcardSet]

    init(sets: [FlashcardSet]) {
        self.sets = sets.filter { !$0.cards.isEmpty }
    }

    var isEmpty: Bool {
        sets.isEmpty
    }

    func theme(for set: FlashcardSet) -> CreateSetTheme {
        CreateSetTheme.theme(forHex: set.colorHex)
    }

    func wordsCountText(for set: FlashcardSet) -> String {
        "\(set.cards.count) words"
    }
}
