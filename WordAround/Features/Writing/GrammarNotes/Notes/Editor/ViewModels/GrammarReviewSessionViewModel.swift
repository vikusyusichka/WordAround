import Foundation
import Combine

// MARK: - Phase

/// The active step in a review card's lifecycle.
enum GrammarReviewSessionPhase: Equatable {
    /// Showing the source block. User taps Continue to proceed.
    case source
    /// Showing the quiz question. User answers, then result is revealed.
    case question
    /// Showing result / explanation. Rating buttons are visible.
    case result
}

// MARK: - ViewModel

/// Drives the multi-phase review session.
///
/// Phase lifecycle per card:
///   source → question → result → (next card)
///
/// Every card is guaranteed to have a question — the queue builder skips
/// items that can't produce a usable question rather than degrading to
/// rate-only mode. The session has no rate-only fallback.
@MainActor
final class GrammarReviewSessionViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var cards: [GrammarReviewSessionCard] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var phase: GrammarReviewSessionPhase = .source
    /// Which source pool the active session is using. Drives the badge on
    /// every card. `nil` while loading or after an empty result.
    @Published private(set) var sourcePool: GrammarReviewSourcePool?

    @Published private(set) var isLoading = false
    @Published private(set) var sessionError: String?
    @Published private(set) var isFinished = false
    @Published private(set) var isRating = false

    /// Set after the user submits an answer in `.question` phase. Only
    /// meaningful for auto-graded question types (MC, TF, fill-gap). Short
    /// answer questions cannot be auto-graded so `lastAnswerCorrect` stays
    /// false and the session treats them as "self-rated".
    @Published private(set) var lastAnswerCorrect: Bool = false
    @Published private(set) var lastUserAnswer: String = ""
    /// True when the current card was answered with an auto-graded question
    /// type and the answer matched. Used by the session summary to count
    /// `correctAnswerCount` strictly — short-answer questions don't count
    /// toward correct/incorrect even though they're "answered".
    @Published private(set) var lastAnswerWasAutoGraded: Bool = false

    // MARK: - Stats

    @Published private(set) var totalReviewed: Int = 0
    /// Correct quiz answers — counted only for auto-graded question types.
    @Published private(set) var correctAnswerCount: Int = 0
    /// Incorrect quiz answers — counted only for auto-graded question types.
    /// Short-answer "incorrect" doesn't increment this; rating handles that.
    @Published private(set) var incorrectAnswerCount: Int = 0
    @Published private(set) var forgotCount: Int = 0
    @Published private(set) var hardCount: Int = 0
    @Published private(set) var goodCount: Int = 0
    @Published private(set) var easyCount: Int = 0

    // MARK: - Dependencies

    private let ownerUID: String
    private let reviewService: GrammarReviewServicing
    private let queueBuilder: GrammarReviewQueueBuilder

    // MARK: - Init

    init(
        ownerUID: String,
        reviewService: GrammarReviewServicing = GrammarReviewService(),
        queueBuilder: GrammarReviewQueueBuilder = GrammarReviewQueueBuilder()
    ) {
        self.ownerUID = ownerUID
        self.reviewService = reviewService
        self.queueBuilder = queueBuilder
    }

    // MARK: - Computed

    var currentCard: GrammarReviewSessionCard? {
        guard !cards.isEmpty, currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var totalCards: Int { cards.count }

    var progressFraction: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(min(currentIndex + 1, cards.count)) / Double(cards.count)
    }

    /// Total rated items where the user answered the quiz wrong OR rated as
    /// Forgot without an auto-graded answer. Used for the summary.
    var incorrectCount: Int { incorrectAnswerCount + forgotCountWithoutQuiz }

    /// Internal counter: how many Forgot ratings happened on a card where
    /// the quiz was a short-answer (i.e. not auto-graded). These count
    /// toward "incorrect" because the user explicitly said they forgot.
    @Published private(set) var forgotCountWithoutQuiz: Int = 0

    // MARK: - Session start

    /// **Preferred entry point.** Starts the session from a queue that was
    /// already built by `GrammarReviewViewModel`. The session NEVER
    /// rebuilds — it just consumes the cards it was handed.
    ///
    /// This is the single source of truth that fixes the "card shows 1
    /// item, session shows Nothing reviewed" inconsistency: the card and
    /// the session share the exact same `GrammarReviewQueueBuilder.Result`.
    func startSession(prebuilt: GrammarReviewQueueBuilder.Result) {
        guard !isLoading else { return }
        resetStats()

        #if DEBUG
        print("[ReviewSession] startSession(prebuilt:) → pool=\(prebuilt.pool?.rawValue ?? "nil") count=\(prebuilt.count) ids=\(prebuilt.cards.map { $0.id })")
        #endif

        cards = prebuilt.cards
        sourcePool = prebuilt.pool

        if cards.isEmpty {
            isFinished = true
        } else {
            currentIndex = 0
            phase = .source
        }
    }

    /// Legacy entry point — builds the queue on the fly. Kept for callers
    /// that don't pre-build (tests, previews). Production code should use
    /// `startSession(prebuilt:)` so the home card and session share state.
    func startSession(
        recentlyOpened: [GrammarReviewRecommendation],
        recentlyEdited: [GrammarReviewRecommendation]
    ) async {
        guard !isLoading else { return }
        resetStats()
        isLoading = true
        sessionError = nil
        defer { isLoading = false }

        do {
            let manualItems = try await reviewService.fetchDueReviewItems(
                ownerUID: ownerUID,
                limit: 30
            )
            await buildAndStart(
                manualItems: manualItems,
                recentlyOpened: recentlyOpened,
                recentlyEdited: recentlyEdited
            )
        } catch {
            sessionError = "Could not load review queue. Please check your connection."
            isFinished = true
        }
    }

    /// Legacy entry point with pre-fetched pools. Same semantics as the
    /// async variant above.
    func startSession(
        manualItems: [GrammarReviewItem],
        recentlyOpened: [GrammarReviewRecommendation],
        recentlyEdited: [GrammarReviewRecommendation]
    ) async {
        guard !isLoading else { return }
        resetStats()
        isLoading = true
        defer { isLoading = false }

        await buildAndStart(
            manualItems: manualItems,
            recentlyOpened: recentlyOpened,
            recentlyEdited: recentlyEdited
        )
    }

    private func buildAndStart(
        manualItems: [GrammarReviewItem],
        recentlyOpened: [GrammarReviewRecommendation],
        recentlyEdited: [GrammarReviewRecommendation]
    ) async {
        let result = await queueBuilder.build(
            manualItems: manualItems,
            recentlyOpened: recentlyOpened,
            recentlyEdited: recentlyEdited
        )

        startSession(prebuilt: result)
    }

    // MARK: - Phase transitions

    /// Called when the user taps "Continue" in the `.source` phase. Always
    /// advances to `.question` — every card has a question.
    func continueFromSource() {
        guard case .source = phase else { return }
        phase = .question
    }

    /// Called when the user submits an answer in the `.question` phase.
    /// Records correctness for auto-graded questions; short-answer questions
    /// fall through to `.result` without auto-grading.
    func submitAnswer(_ answer: String) {
        guard case .question = phase,
              let question = currentCard?.question else { return }

        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCorrect = question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)

        let autoGraded: Bool
        let isCorrect: Bool
        switch question.type {
        case .shortAnswer:
            autoGraded = false
            isCorrect = false
        case .multipleChoice, .trueFalse, .fillGap:
            autoGraded = true
            isCorrect = trimmedAnswer.lowercased() == trimmedCorrect.lowercased()
        }

        lastUserAnswer = trimmedAnswer
        lastAnswerCorrect = isCorrect
        lastAnswerWasAutoGraded = autoGraded

        // Track quiz-level correctness independently from the rating step.
        // The spec is strict: "incorrect" in the summary means an actually
        // wrong auto-graded answer, not just a low recall rating.
        if autoGraded {
            if isCorrect { correctAnswerCount += 1 }
            else         { incorrectAnswerCount += 1 }
        }

        phase = .result
    }

    // MARK: - Rating

    /// Saves the rating and advances to the next card.
    func rate(_ result: GrammarReviewResult) async {
        guard !isRating else { return }
        guard let card = currentCard else { return }

        isRating = true
        defer { isRating = false }

        if card.reviewItem.ownerUID == ownerUID {
            _ = try? await reviewService.markReviewed(item: card.reviewItem, result: result)
        }

        recordResult(result)
        advance()
    }

    private func recordResult(_ result: GrammarReviewResult) {
        totalReviewed += 1
        switch result {
        case .forgot:
            forgotCount += 1
            // Spec: "Do not count Forgot as incorrect unless no quiz answer
            // exists." Auto-graded answers already counted via
            // submitAnswer(); only count Forgot here for short-answer cards.
            if !lastAnswerWasAutoGraded {
                forgotCountWithoutQuiz += 1
            }
        case .hard:
            hardCount += 1
        case .good:
            goodCount += 1
        case .easy:
            easyCount += 1
        }
    }

    // MARK: - Navigation

    func skipCurrent() {
        advance()
    }

    private func advance() {
        if currentIndex + 1 < cards.count {
            currentIndex += 1
            lastAnswerCorrect = false
            lastUserAnswer = ""
            lastAnswerWasAutoGraded = false
            phase = .source
        } else {
            isFinished = true
        }
    }

    // MARK: - Reset

    func reset() {
        cards = []
        currentIndex = 0
        phase = .source
        sourcePool = nil
        isFinished = false
        sessionError = nil
        isRating = false
        isLoading = false
        resetStats()
    }

    private func resetStats() {
        totalReviewed = 0
        correctAnswerCount = 0
        incorrectAnswerCount = 0
        forgotCount = 0
        hardCount = 0
        goodCount = 0
        easyCount = 0
        forgotCountWithoutQuiz = 0
        lastAnswerCorrect = false
        lastUserAnswer = ""
        lastAnswerWasAutoGraded = false
        isFinished = false
    }
}
