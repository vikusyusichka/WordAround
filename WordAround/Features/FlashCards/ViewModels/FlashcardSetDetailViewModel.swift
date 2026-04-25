import Foundation
import Combine

@MainActor
final class FlashcardSetDetailViewModel: ObservableObject {
    enum CardFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case studied = "Studied"
        case remaining = "Remaining"
        case mastered = "Mastered"

        var id: String { rawValue }
    }

    @Published var currentCardIndex = 0
    @Published var isShowingTranslation = true
    @Published var trackProgress = true
    @Published var selectedFilter: CardFilter = .all
    @Published private(set) var cards: [Flashcard]

    @Published private var studiedCardIDs: Set<String> = []
    @Published private var masteredCardIDs: Set<String> = []

    let set: FlashcardSet

    init(set: FlashcardSet) {
        self.set = set
        self.cards = set.cards
    }

    var theme: CreateSetTheme {
        CreateSetTheme.theme(forHex: set.colorHex)
    }

    var activeCard: Flashcard? {
        guard !cards.isEmpty else { return nil }
        return cards[min(currentCardIndex, cards.count - 1)]
    }

    var filteredCards: [Flashcard] {
        switch selectedFilter {
        case .all:
            return cards
        case .studied:
            return cards.filter { studiedCardIDs.contains($0.id) }
        case .remaining:
            return cards.filter { !studiedCardIDs.contains($0.id) }
        case .mastered:
            return cards.filter { masteredCardIDs.contains($0.id) }
        }
    }

    var allCount: Int {
        cards.count
    }

    var studiedCount: Int {
        studiedCardIDs.count
    }

    var remainingCount: Int {
        max(cards.count - studiedCardIDs.count, 0)
    }

    var masteredCount: Int {
        masteredCardIDs.count
    }

    func count(for filter: CardFilter) -> Int {
        switch filter {
        case .all:
            return allCount
        case .studied:
            return studiedCount
        case .remaining:
            return remainingCount
        case .mastered:
            return masteredCount
        }
    }

    func toggleTranslation() {
        isShowingTranslation.toggle()
    }

    func shuffleCards() {
        cards.shuffle()
        currentCardIndex = 0
        isShowingTranslation = true
    }

    func goToNextCard() {
        markCurrentAsStudiedIfNeeded()

        guard currentCardIndex < cards.count - 1 else { return }

        currentCardIndex += 1
        isShowingTranslation = true
    }

    func goToPreviousCard() {
        guard currentCardIndex > 0 else { return }

        currentCardIndex -= 1
        isShowingTranslation = true
    }

    func toggleMastered(_ card: Flashcard) {
        if masteredCardIDs.contains(card.id) {
            masteredCardIDs.remove(card.id)
        } else {
            masteredCardIDs.insert(card.id)
            studiedCardIDs.insert(card.id)
        }
    }

    func isMastered(_ card: Flashcard) -> Bool {
        masteredCardIDs.contains(card.id)
    }

    func isStudied(_ card: Flashcard) -> Bool {
        studiedCardIDs.contains(card.id)
    }

    func selectFilter(_ filter: CardFilter) {
        selectedFilter = filter
        currentCardIndex = 0
        isShowingTranslation = true
    }

    private func markCurrentAsStudiedIfNeeded() {
        guard trackProgress, let activeCard else { return }
        studiedCardIDs.insert(activeCard.id)
    }
}
