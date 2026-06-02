import SwiftUI
import Combine

enum WriteWordsTrainingMode: String, CaseIterable, Identifiable {
    case wordToTranslation = "Word → Translation"
    case translationToWord = "Translation → Word"
    var id: String { rawValue }
}

enum WriteWordsDifficulty: String, CaseIterable, Identifiable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .easy:   return "hare.fill"
        case .medium: return "figure.walk"
        case .hard:   return "flame.fill"
        }
    }

    var description: String {
        switch self {
        case .easy:   return "Unlimited hints, unlimited skips"
        case .medium: return "1 hint letter, max 25% skips"
        case .hard:   return "No hints, no skips, timed"
        }
    }
}

enum WriteWordsValidationState: Equatable {
    case idle
    case correct
    case incorrect
}

enum WriteWordsNavigationState: Equatable {
    case active
    case lose
}

enum WriteWordsGameOverReason: Equatable {
    case timeout
    case wrongAnswer
}

struct WriteWordsLoseStats: Equatable {
    let completedWords: Int
    let streak: Int
    let difficulty: String
}

struct WriteWordsRoundStats: Equatable {
    let totalWords: Int
    let completedWords: Int
    let skippedWords: Int
    let hintsUsed: Int
    let difficulty: WriteWordsDifficulty
}

struct WriteWordsWrongAnswerDetails: Equatable {
    let word: String
    let userAnswer: String
    let correctAnswer: String
}

@MainActor
final class WriteWordsViewModel: ObservableObject {

    @Published var currentIndex: Int = 0
    @Published var typedAnswer: String = ""
    @Published var validationState: WriteWordsValidationState = .idle
    @Published var trainingMode: WriteWordsTrainingMode = .wordToTranslation
    @Published var difficulty: WriteWordsDifficulty = .medium
    @Published var hintRevealedCount: Int = 0
    @Published var isSettingsPresented: Bool = false
    @Published var isDifficultyMenuPresented: Bool = false
    @Published private(set) var navigationState: WriteWordsNavigationState = .active
    @Published private(set) var streak: Int = 0
    @Published private(set) var isRoundCompleted: Bool = false
    @Published private(set) var completedWords: Int = 0
    @Published private(set) var skippedWords: Int = 0
    @Published private(set) var hintsUsed: Int = 0
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var gameOverReason: WriteWordsGameOverReason?
    @Published private(set) var gameOverCorrectAnswer: String = ""
    @Published private(set) var gameOverUserAnswer: String = ""
    @Published private(set) var gameOverWord: String = ""

    @Published private(set) var secondsRemaining: Int = 0
    @Published private(set) var timerProgress: CGFloat = 1
    @Published private(set) var isTimerExpired: Bool = false

    @Published var skippedCount: Int = 0

    private enum TimerConstants {
        static let shortWordLimit = 4
        static let mediumWordLimit = 7
        static let longWordLimit = 10

        static let shortWordDuration: TimeInterval = 3
        static let mediumWordDuration: TimeInterval = 5
        static let longWordDuration: TimeInterval = 7
        static let extraLongWordDuration: TimeInterval = 10

        static let refreshInterval: TimeInterval = 1.0 / 60.0
        static let correctAdvanceDelay: UInt64 = 700_000_000
    }

    private let exercises: [WriteWordsExercise]
    private var timerTask: Task<Void, Never>?
    private var delayedAdvanceTask: Task<Void, Never>?
    private var timerStartedAt: Date?
    private var timerDuration: TimeInterval = TimerConstants.extraLongWordDuration
    private let statsService: DailyPracticeStatsService
    private var didRecordPracticeStats = false

    init(set: FlashcardSet? = nil, statsService: DailyPracticeStatsService = .shared) {
        self.statsService = statsService
        if let set, !set.cards.isEmpty {
            self.exercises = set.cards.map { card in
                WriteWordsExercise(
                    id: card.id,
                    sourceLanguageWord: card.word,
                    hint: "",
                    targetLanguageTitle: "Translate to your language",
                    answer: card.translation
                )
            }
        } else {
            self.exercises = [
                WriteWordsExercise(id: UUID().uuidString, sourceLanguageWord: "manzana", hint: "", targetLanguageTitle: "Translate to your language", answer: "яблуко"),
                WriteWordsExercise(id: UUID().uuidString, sourceLanguageWord: "casa", hint: "", targetLanguageTitle: "Translate to your language", answer: "будинок"),
                WriteWordsExercise(id: UUID().uuidString, sourceLanguageWord: "perro", hint: "", targetLanguageTitle: "Translate to your language", answer: "собака"),
                WriteWordsExercise(id: UUID().uuidString, sourceLanguageWord: "gato", hint: "", targetLanguageTitle: "Translate to your language", answer: "кіт")
            ]
        }
        resetAnswerState()
    }

    deinit {
        timerTask?.cancel()
        delayedAdvanceTask?.cancel()
    }

    var exercise: WriteWordsExercise {
        exercises[safe: currentIndex] ?? exercises[0]
    }

    var displayWord: String {
        switch trainingMode {
        case .wordToTranslation: return exercise.sourceLanguageWord
        case .translationToWord: return exercise.answer
        }
    }

    var displayTitle: String {
        switch trainingMode {
        case .wordToTranslation: return "Translate to your language"
        case .translationToWord: return exercise.targetLanguageTitle
        }
    }

    var correctAnswer: String {
        switch trainingMode {
        case .wordToTranslation: return exercise.answer
        case .translationToWord: return exercise.sourceLanguageWord
        }
    }

    var totalCount: Int { exercises.count }
    var totalWords: Int { totalCount }
    var progressText: String { "\(currentIndex + 1) / \(max(totalCount, 1))" }
    var progress: CGFloat { CGFloat(currentIndex + 1) / CGFloat(max(totalCount, 1)) }

    var isCorrect: Bool { validationState == .correct }
    var isIncorrect: Bool { validationState == .incorrect }
    var isInteractionLocked: Bool { navigationState == .lose || isRoundCompleted || isGameOver || isTimerExpired }

    var loseStats: WriteWordsLoseStats {
        WriteWordsLoseStats(
            completedWords: completedWords,
            streak: streak,
            difficulty: difficulty.rawValue
        )
    }

    var roundStats: WriteWordsRoundStats {
        WriteWordsRoundStats(
            totalWords: totalWords,
            completedWords: completedWords,
            skippedWords: skippedWords,
            hintsUsed: hintsUsed,
            difficulty: difficulty
        )
    }

    var wrongAnswerDetails: WriteWordsWrongAnswerDetails? {
        guard gameOverReason == .wrongAnswer else { return nil }
        return WriteWordsWrongAnswerDetails(
            word: gameOverWord,
            userAnswer: gameOverUserAnswer,
            correctAnswer: gameOverCorrectAnswer
        )
    }

    var maxHintLetters: Int {
        switch difficulty {
        case .easy:   return correctAnswer.count
        case .medium: return 1
        case .hard:   return 0
        }
    }

    var hintOverlayText: String? {
        guard hintRevealedCount > 0, difficulty != .hard else { return nil }
        return String(correctAnswer.prefix(hintRevealedCount))
    }

    var isHintAvailable: Bool {
        difficulty != .hard && hintRevealedCount < maxHintLetters
    }

    var maxSkipsAllowed: Int {
        switch difficulty {
        case .easy:   return totalCount
        case .medium: return Int(ceil(Double(totalCount) * 0.25))
        case .hard:   return 0
        }
    }

    var canSkip: Bool {
        switch difficulty {
        case .easy:   return true
        case .medium: return skippedCount < maxSkipsAllowed
        case .hard:   return false
        }
    }

    var skipsRemainingText: String? {
        guard difficulty == .medium else { return nil }
        let remaining = maxSkipsAllowed - skippedCount
        return "\(remaining) skip\(remaining == 1 ? "" : "s") left"
    }

    var isHardTimerVisible: Bool {
        difficulty == .hard
    }

    var modeTitle: String { trainingMode.rawValue }
    var difficultyTitle: String { difficulty.rawValue }

    func validateAnswer() {
        guard !isInteractionLocked else { return }

        if validationState == .incorrect {
            validationState = .idle
        }
    }

    @discardableResult
    func attemptNext() -> Bool {
        guard !isInteractionLocked, validationState != .correct else { return false }

        delayedAdvanceTask?.cancel()
        stopTimer()

        if normalize(typedAnswer) == normalize(correctAnswer) {
            validationState = .correct
            streak += 1
            completedWords += 1
            scheduleAdvance(after: TimerConstants.correctAdvanceDelay)
            return true
        }

        validationState = .incorrect

        if difficulty == .hard {
            triggerGameOver(reason: .wrongAnswer)
        }

        return false
    }

    func skip() {
        guard !isInteractionLocked, canSkip else { return }
        skippedWords += 1
        if difficulty == .medium { skippedCount += 1 }
        delayedAdvanceTask?.cancel()
        stopTimer()
        advanceToNext()
    }

    func revealNextHint() {
        guard !isInteractionLocked, isHintAvailable else { return }
        hintRevealedCount += 1
        hintsUsed += 1
    }

    func selectTrainingMode(_ mode: WriteWordsTrainingMode) {
        guard mode != trainingMode else { return }
        trainingMode = mode
        resetFullSession()
    }

    func selectDifficulty(_ level: WriteWordsDifficulty) {
        guard level != difficulty else { return }
        difficulty = level
        resetFullSession()
    }

    func startTimerIfNeeded() {
        guard difficulty == .hard else {
            stopTimer()
            resetTimerDisplay()
            return
        }
        startTimer()
    }

    func stopTimerIfNeeded() {
        stopTimer()
    }

    private func startTimer() {
        guard difficulty == .hard, !isInteractionLocked else { return }

        stopTimer()
        resetTimerDisplay()

        timerDuration = timerDuration(for: correctAnswer)
        secondsRemaining = Int(ceil(timerDuration))
        timerProgress = 1
        timerStartedAt = Date()

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(TimerConstants.refreshInterval * 1_000_000_000))
                if Task.isCancelled { return }

                await MainActor.run { [weak self] in
                    self?.updateTimerProgress()
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        timerStartedAt = nil
    }

    private func updateTimerProgress() {
        guard difficulty == .hard, let timerStartedAt else {
            stopTimer()
            return
        }

        let elapsed = Date().timeIntervalSince(timerStartedAt)
        let remaining = max(timerDuration - elapsed, 0)

        secondsRemaining = Int(ceil(remaining))
        timerProgress = timerDuration > 0 ? CGFloat(remaining / timerDuration) : 0

        if remaining <= 0 {
            handleTimerExpired()
        }
    }

    private func handleTimerExpired() {
        guard navigationState == .active, !isGameOver else { return }

        isTimerExpired = true
        timerProgress = 0
        secondsRemaining = 0
        validationState = .incorrect
        triggerGameOver(reason: .timeout)
    }

    func restartRound() {
        resetFullSession()
    }

    func exitRound() {
        stopTimer()
        delayedAdvanceTask?.cancel()
    }

    func retryAfterLose() {
        restartRound()
    }

    func closeLoseScreen() {
        exitRound()
        navigationState = .lose
    }

    private func triggerGameOver(reason: WriteWordsGameOverReason) {
        delayedAdvanceTask?.cancel()
        stopTimer()

        gameOverReason = reason
        isGameOver = true
        navigationState = .lose

        gameOverCorrectAnswer = correctAnswer
        gameOverUserAnswer = typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        gameOverWord = displayWord

        recordPracticeStatsIfNeeded()
    }

    private func timerDuration(for answer: String) -> TimeInterval {
        let lettersCount = answer.trimmingCharacters(in: .whitespacesAndNewlines).count

        switch lettersCount {
        case 0...TimerConstants.shortWordLimit:
            return TimerConstants.shortWordDuration
        case (TimerConstants.shortWordLimit + 1)...TimerConstants.mediumWordLimit:
            return TimerConstants.mediumWordDuration
        case (TimerConstants.mediumWordLimit + 1)...TimerConstants.longWordLimit:
            return TimerConstants.longWordDuration
        default:
            return TimerConstants.extraLongWordDuration
        }
    }

    private func resetTimerDisplay() {
        secondsRemaining = 0
        timerProgress = 1
        isTimerExpired = false
    }

    private func scheduleAdvance(after delay: UInt64) {
        delayedAdvanceTask?.cancel()
        delayedAdvanceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            if Task.isCancelled { return }

            await MainActor.run { [weak self] in
                self?.advanceToNext()
            }
        }
    }

    private func advanceToNext() {
        delayedAdvanceTask?.cancel()

        guard currentIndex < totalCount - 1 else {
            completeRound()
            return
        }

        currentIndex += 1
        resetAnswerState()

        if difficulty == .hard {
            startTimer()
        }
    }

    private func completeRound() {
        delayedAdvanceTask?.cancel()
        stopTimer()
        resetTimerDisplay()
        typedAnswer = ""
        validationState = .idle
        hintRevealedCount = 0
        isRoundCompleted = true
        recordPracticeStatsIfNeeded()
    }

    private func recordPracticeStatsIfNeeded() {
        guard !didRecordPracticeStats else { return }
        guard completedWords > 0 else { return }
        didRecordPracticeStats = true
        statsService.record(
            skill: .writing,
            value: completedWords,
            sourceModeID: "write-from-sets"
        )
    }

    private func resetAnswerState() {
        typedAnswer = ""
        validationState = .idle
        hintRevealedCount = 0
        stopTimer()
        resetTimerDisplay()
    }

    private func resetFullSession() {
        delayedAdvanceTask?.cancel()
        currentIndex = 0
        skippedCount = 0
        skippedWords = 0
        hintsUsed = 0
        completedWords = 0
        streak = 0
        isRoundCompleted = false
        isGameOver = false
        gameOverReason = nil
        gameOverCorrectAnswer = ""
        gameOverUserAnswer = ""
        gameOverWord = ""
        navigationState = .active
        didRecordPracticeStats = false
        resetAnswerState()
        startTimerIfNeeded()
    }

    private func normalize(_ string: String) -> String {
        string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
