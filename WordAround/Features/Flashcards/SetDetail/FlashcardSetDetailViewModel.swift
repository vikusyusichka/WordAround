import Foundation
import Combine
import AVFoundation
import FirebaseFirestore
import SwiftUI

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
    @Published var isShowingTranslation = false
    @Published var trackProgress = true
    @Published var selectedFilter: CardFilter = .all
    @Published private(set) var cards: [Flashcard]

    @Published private(set) var studiedCardIDs: Set<String> = []
    @Published private(set) var masteredCardIDs: Set<String> = []

    @Published var isExpandedMode = false
    @Published var editingCard: Flashcard? = nil
    @Published var swipeDirection: SwipeDirection = .none

    enum SwipeDirection {
        case none, left, right
    }

    let set: FlashcardSet

    private let db = Firestore.firestore()
    private var synthesizer = AVSpeechSynthesizer()

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

    var allCount: Int { cards.count }
    var studiedCount: Int { studiedCardIDs.count }
    var remainingCount: Int { max(cards.count - studiedCardIDs.count, 0) }
    var masteredCount: Int { masteredCardIDs.count }

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
        isShowingTranslation = false
    }

    func goToNextCard() {
        guard currentCardIndex < cards.count - 1 else { return }
        markCurrentAsStudiedIfNeeded()
        currentCardIndex += 1
        isShowingTranslation = false
    }

    func goToPreviousCard() {
        guard currentCardIndex > 0 else { return }
        currentCardIndex -= 1
        isShowingTranslation = false
    }

    func handleSwipe(_ direction: SwipeDirection) {
        guard let card = activeCard else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            swipeDirection = direction
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.swipeDirection = .none
        }

        if trackProgress {
            switch direction {
            case .right:
                if studiedCardIDs.contains(card.id) {
                    masteredCardIDs.insert(card.id)
                } else {
                    studiedCardIDs.insert(card.id)
                }
            case .left:
                studiedCardIDs.remove(card.id)
                masteredCardIDs.remove(card.id)
            case .none:
                break
            }
        }

        if currentCardIndex < cards.count - 1 {
            currentCardIndex += 1
        } else {
            currentCardIndex = 0
        }

        isShowingTranslation = false
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
        isShowingTranslation = false
    }

    // MARK: - Speak

    func speak(_ text: String, language: String = "en-US") {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestVoice(for: language)
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1.02
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.08

        synthesizer.speak(utterance)
    }

    func speakCurrentCard() {
        guard let card = activeCard else { return }
        let text = isShowingTranslation ? card.translation : card.word
        speak(text)
    }

    func speakWordAndTranslation(_ card: Flashcard) {
        synthesizer.stopSpeaking(at: .immediate)

        let wordUtterance = makeUtterance(text: card.word, language: "en-US")
        let translationUtterance = makeUtterance(text: card.translation, language: "uk-UA")

        synthesizer.speak(wordUtterance)
        synthesizer.speak(translationUtterance)
    }

    private func makeUtterance(text: String, language: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestVoice(for: language)
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1.02
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.12

        return utterance
    }

    private func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == language }

        return voices.first(where: { $0.quality == .premium })
            ?? voices.first(where: { $0.quality == .enhanced })
            ?? voices.first
    }

    // MARK: - Cards actions

    func addCard(_ card: Flashcard) {
        cards.append(card)

        if cards.count == 1 {
            currentCardIndex = 0
            isShowingTranslation = false
        }

        persistCards()
    }

    func saveEdit(_ updated: Flashcard) {
        guard let index = cards.firstIndex(where: { $0.id == updated.id }) else { return }
        cards[index] = updated
        persistCards()
    }

    func deleteCard(_ card: Flashcard) {
        cards.removeAll { $0.id == card.id }
        studiedCardIDs.remove(card.id)
        masteredCardIDs.remove(card.id)

        if currentCardIndex >= cards.count {
            currentCardIndex = max(0, cards.count - 1)
        }

        persistCards()
    }

    func deleteCard(at offsets: IndexSet) {
        let toDelete = offsets.map { filteredCards[$0] }
        for card in toDelete {
            deleteCard(card)
        }
    }

    func toggleExpandMode() {
        isExpandedMode.toggle()
    }

    // MARK: - Persist

    private func persistCards() {
        guard !set.ownerUID.isEmpty else { return }

        let updatedCards = cards.map { card -> [String: Any] in
            var dict: [String: Any] = [
                "id": card.id,
                "word": card.word,
                "translation": card.translation,
                "example": card.example
            ]

            if let url = card.imageURL {
                dict["imageURL"] = url
            }

            return dict
        }

        db.collection("users")
            .document(set.ownerUID)
            .collection("flashcardSets")
            .document(set.id)
            .updateData(["cards": updatedCards]) { _ in }
    }

    private func markCurrentAsStudiedIfNeeded() {
        guard trackProgress, let activeCard else { return }
        studiedCardIDs.insert(activeCard.id)
    }
}
