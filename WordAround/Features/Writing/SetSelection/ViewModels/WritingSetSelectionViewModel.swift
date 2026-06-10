import SwiftUI
import Combine

struct WritingSetSelectionItem: Identifiable {
    let id: String
    let sourceSet: FlashcardSet
    let title: String
    let subtitle: String
    let wordsCountText: String
    let iconSystemName: String
    let theme: CreateSetTheme
}

@MainActor
final class WritingSetSelectionViewModel: ObservableObject {
    @Published private(set) var items: [WritingSetSelectionItem]

    init(sets: [FlashcardSet]) {
        self.items = sets
            .filter { !$0.cards.isEmpty }
            .map { set in
                let theme = CreateSetTheme.theme(forHex: set.colorHex)

                return WritingSetSelectionItem(
                    id: set.id,
                    sourceSet: set,
                    title: set.title,
                    subtitle: Self.subtitle(for: set),
                    wordsCountText: Self.wordsCountText(for: set),
                    iconSystemName: Self.iconSystemName(for: set),
                    theme: theme
                )
            }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    private static func subtitle(for set: FlashcardSet) -> String {
        let description = set.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? wordsCountText(for: set) : description
    }

    private static func wordsCountText(for set: FlashcardSet) -> String {
        set.cards.count == 1
            ? L10n.string("readingOneWord")
            : String(format: L10n.string("readingWordsCountFmt"), set.cards.count)
    }

    private static func iconSystemName(for set: FlashcardSet) -> String {
        if case let .systemName(name) = set.icon, !name.isEmpty {
            return name
        }

        return "rectangle.stack.fill"
    }
}
