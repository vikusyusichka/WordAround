import Foundation
import Combine
import AVFoundation
import FirebaseFirestore
import SwiftUI

@MainActor
final class FlashcardSetDetailViewModel: ObservableObject {

    // MARK: - Types

    enum CardFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case studied = "Studied"
        case remaining = "Remaining"
        case mastered = "Mastered"

        var id: String { rawValue }
    }

    enum SwipeDirection {
        case none, left, right
    }

    // MARK: - Published

    @Published var currentCardIndex = 0
    @Published var isShowingTranslation = false
    @Published var trackProgress = true
    @Published var selectedFilter: CardFilter = .all
    @Published var swipeDirection: SwipeDirection = .none
    @Published var isExpandedMode = false
    @Published var editingCard: Flashcard? = nil
    @Published var isShowingRoundFinish = false

    @Published private(set) var cards: [Flashcard]
    @Published private(set) var studiedCardIDs: Set<String> = []
    @Published private(set) var masteredCardIDs: Set<String> = []
    @Published private(set) var learningCardIDs: Set<String> = []
    @Published private(set) var activeRoundCardIDs: [String]
    @Published private(set) var set: FlashcardSet

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let synthesizer = AVSpeechSynthesizer()
    private let onSetChanged: (FlashcardSet) -> Void

    // MARK: - Init

    init(set: FlashcardSet, onSetChanged: @escaping (FlashcardSet) -> Void = { _ in }) {
        self.set = set
        self.cards = set.cards
        self.activeRoundCardIDs = set.cards.map(\.id)
        self.onSetChanged = onSetChanged
    }

    // MARK: - Computed

    var theme: CreateSetTheme {
        CreateSetTheme.theme(forHex: set.colorHex)
    }

    var activeCard: Flashcard? {
        activeRoundCard
    }

    var roundCards: [Flashcard] {
        activeRoundCardIDs.compactMap { id in
            cards.first { $0.id == id }
        }
    }

    var activeRoundCard: Flashcard? {
        let currentRoundCards = roundCards
        guard !currentRoundCards.isEmpty else { return nil }
        let safeIndex = min(currentCardIndex, currentRoundCards.count - 1)
        return currentRoundCards[safeIndex]
    }

    var roundTotalCount: Int {
        roundCards.count
    }

    var roundKnownCount: Int {
        roundCards.filter { studiedCardIDs.contains($0.id) }.count
    }

    var roundLearningCount: Int {
        roundCards.filter { learningCardIDs.contains($0.id) }.count
    }

    var roundAnsweredCount: Int {
        min(roundKnownCount + roundLearningCount, roundTotalCount)
    }

    var roundCurrentNumber: Int {
        roundAnsweredCount
    }

    var roundListingProgress: CGFloat {
        guard roundTotalCount > 0 else { return 0 }
        return CGFloat(roundAnsweredCount) / CGFloat(roundTotalCount)
    }

    var filteredCards: [Flashcard] {
        switch selectedFilter {
        case .all:       return cards
        case .studied:   return cards.filter { studiedCardIDs.contains($0.id) }
        case .remaining: return cards.filter { !studiedCardIDs.contains($0.id) }
        case .mastered:  return cards.filter { masteredCardIDs.contains($0.id) }
        }
    }

    var allCount: Int       { cards.count }
    var studiedCount: Int   { studiedCardIDs.count }
    var remainingCount: Int { max(cards.count - studiedCardIDs.count, 0) }
    var masteredCount: Int  { masteredCardIDs.count }

    func count(for filter: CardFilter) -> Int {
        switch filter {
        case .all:       return allCount
        case .studied:   return studiedCount
        case .remaining: return remainingCount
        case .mastered:  return masteredCount
        }
    }

    func isMastered(_ card: Flashcard) -> Bool { masteredCardIDs.contains(card.id) }
    func isStudied(_ card: Flashcard) -> Bool   { studiedCardIDs.contains(card.id) }

    // MARK: - Card Navigation

    func toggleTranslation() {
        isShowingTranslation.toggle()
    }

    func shuffleCards() {
        cards.shuffle()
        activeRoundCardIDs = cards.map(\.id)
        studiedCardIDs.removeAll()
        masteredCardIDs.removeAll()
        learningCardIDs.removeAll()
        currentCardIndex = 0
        isShowingTranslation = false
        isShowingRoundFinish = false
    }

    func goToNextCard() {
        guard currentCardIndex < roundCards.count - 1 else { return }
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
        guard let card = activeRoundCard else { return }

        swipeDirection = direction

        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            self.swipeDirection = .none
        }

        if trackProgress {
            updateProgress(for: card, direction: direction)
        }

        moveToNextCardUntilEnd()
        isShowingTranslation = false
    }

    func repeatUnknownRound() {
        let unknownIDs = roundCards
            .filter { learningCardIDs.contains($0.id) }
            .map(\.id)

        activeRoundCardIDs = unknownIDs.isEmpty ? cards.map(\.id) : unknownIDs
        learningCardIDs.subtract(activeRoundCardIDs)
        studiedCardIDs.subtract(activeRoundCardIDs)
        masteredCardIDs.subtract(activeRoundCardIDs)
        currentCardIndex = 0
        isShowingTranslation = false
        isShowingRoundFinish = false
    }

    func prepareExpandedPresentation() {
        if !trackProgress {
            isShowingRoundFinish = false
            return
        }

        guard isShowingRoundFinish else { return }
        restartAllCardsRound()
    }

    func restartAllCardsRound() {
        studiedCardIDs.removeAll()
        masteredCardIDs.removeAll()
        learningCardIDs.removeAll()
        activeRoundCardIDs = cards.map(\.id)
        currentCardIndex = 0
        isShowingTranslation = false
        isShowingRoundFinish = false
    }

    func selectFilter(_ filter: CardFilter) {
        selectedFilter = filter
        currentCardIndex = 0
        isShowingTranslation = false
    }

    // MARK: - Mastered

    func toggleMastered(_ card: Flashcard) {
        if masteredCardIDs.contains(card.id) {
            masteredCardIDs.remove(card.id)
        } else {
            masteredCardIDs.insert(card.id)
            studiedCardIDs.insert(card.id)
            learningCardIDs.remove(card.id)
        }
    }

    // MARK: - Speech

    func speak(_ text: String, language: String = "en-US") {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(makeUtterance(text: text, language: language))
    }

    func speakCurrentCard() {
        guard let card = activeCard else { return }
        let text = isShowingTranslation ? card.translation : card.word
        speak(text)
    }

    func speakWordAndTranslation(_ card: Flashcard) {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(makeUtterance(text: card.word, language: "en-US"))
        synthesizer.speak(makeUtterance(text: card.translation, language: "uk-UA"))
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
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        return voices.first(where: { $0.quality == .premium })
            ?? voices.first(where: { $0.quality == .enhanced })
            ?? voices.first
    }

    // MARK: - CRUD

    func addCard(_ card: Flashcard) {
        cards.append(card)
        activeRoundCardIDs.append(card.id)
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
        activeRoundCardIDs.removeAll { $0 == card.id }
        studiedCardIDs.remove(card.id)
        masteredCardIDs.remove(card.id)
        learningCardIDs.remove(card.id)
        clampCurrentIndex()
        persistCards()
    }

    func deleteCard(at offsets: IndexSet) {
        offsets.map { filteredCards[$0] }.forEach { deleteCard($0) }
    }

    func toggleExpandMode() {
        isExpandedMode.toggle()
    }

    // MARK: - Private Helpers

    private func clampCurrentIndex() {
        guard !cards.isEmpty else {
            currentCardIndex = 0
            return
        }
        currentCardIndex = min(currentCardIndex, max(roundCards.count - 1, 0))
    }

    private func markCurrentAsStudiedIfNeeded() {
        guard trackProgress, let card = activeRoundCard else { return }
        studiedCardIDs.insert(card.id)
        learningCardIDs.remove(card.id)
    }

    private func updateProgress(for card: Flashcard, direction: SwipeDirection) {
        switch direction {
        case .right:
            studiedCardIDs.insert(card.id)
            learningCardIDs.remove(card.id)
        case .left:
            learningCardIDs.insert(card.id)
            studiedCardIDs.remove(card.id)
            masteredCardIDs.remove(card.id)
        case .none:
            break
        }
    }

    private func moveToNextCardUntilEnd() {
        let currentRoundCards = roundCards
        guard !currentRoundCards.isEmpty else {
            currentCardIndex = 0
            isShowingRoundFinish = trackProgress
            return
        }

        if currentCardIndex < currentRoundCards.count - 1 {
            currentCardIndex += 1
        } else if trackProgress {
            isShowingRoundFinish = true
        }
    }

    // MARK: - Persist

    private func persistCards() {
        set.cards = cards
        set.updatedAt = Date()
        onSetChanged(set)

        guard !set.ownerUID.isEmpty else { return }

        let updatedCards: [[String: Any]] = cards.map { card in
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
            .updateData([
                "cards": updatedCards,
                "updatedAt": set.updatedAt
            ]) { error in
                if let error {
                    print("[FlashcardSetDetailViewModel] persistCards error: \(error.localizedDescription)")
                }
            }
    }
}
