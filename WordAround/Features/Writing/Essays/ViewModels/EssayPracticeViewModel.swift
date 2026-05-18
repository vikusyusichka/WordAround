import Foundation
import Combine

@MainActor
final class EssayPracticeViewModel: ObservableObject {
    enum ValidationState: Equatable {
        case empty
        case belowMinimum(Int)
        case valid
        case aboveMaximum(Int)

        var message: String? {
            switch self {
            case .empty:
                return "Start writing your essay."
            case .belowMinimum(let minimum):
                return "Write at least \(minimum) words before checking grammar."
            case .valid:
                return nil
            case .aboveMaximum(let maximum):
                return "Try to keep your essay under \(maximum) words."
            }
        }

        var allowsGrammarCheck: Bool {
            self == .valid
        }
    }

    enum FeedbackState: Equatable {
        case idle
        case loading
        case success
        case emptyResult
        case error(String)
    }

    @Published private(set) var currentTopic: EssayTopic

    @Published var essayText: String {
        didSet {
            updateWritingState()
        }
    }

    @Published var selectedLanguage: GrammarLanguage {
        didSet {
            clearFeedback()
        }
    }

    @Published var selectedDifficulty: EssayDifficulty {
        didSet {
            resetAssistanceUsage()
            clearFeedback()
        }
    }

    @Published private(set) var wordCount: Int = 0
    @Published private(set) var grammarIssues: [GrammarIssue] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorState: String?
    @Published private(set) var validationState: ValidationState = .empty
    @Published private(set) var feedbackState: FeedbackState = .idle
    @Published private(set) var score: EssayScore?
    @Published private(set) var usedHints: Int = 0
    @Published private(set) var usedTranslations: Int = 0

    private let topics: [EssayTopic]
    private let grammarService: GrammarChecking

    init(
        topics: [EssayTopic] = EssayTopic.predefined,
        grammarService: GrammarChecking = GrammarCheckService(),
        selectedLanguage: GrammarLanguage = .english,
        selectedDifficulty: EssayDifficulty = .b1
    ) {
        self.topics = topics.isEmpty ? [.fallback] : topics
        self.currentTopic = topics.randomElement() ?? .fallback
        self.grammarService = grammarService
        self.selectedLanguage = selectedLanguage
        self.selectedDifficulty = selectedDifficulty
        self.essayText = ""
        updateWritingState()
    }

    var canCheckGrammar: Bool {
        !isLoading && validationState.allowsGrammarCheck
    }

    var hintsLimit: Int {
        selectedDifficulty.hintsLimit
    }

    var hintsLeft: Int {
        max(0, hintsLimit - usedHints)
    }

    var canUseHint: Bool {
        hintsLeft > 0
    }

    var canUseTranslation: Bool {
        selectedDifficulty.allowsTranslation
    }

    var translationWordLimit: Int {
        selectedDifficulty.translationWordLimit
    }

    var privacyNoticeText: String {
        "Essays are sent securely to LanguageTool for grammar checking. Do not include private information."
    }

    func selectRandomTopic() {
        let nextTopic = topics
            .filter { $0.id != currentTopic.id }
            .randomElement() ?? topics.randomElement() ?? .fallback

        currentTopic = nextTopic
        resetEssay()
    }

    func selectLanguage(_ language: GrammarLanguage) {
        guard selectedLanguage != language else { return }
        selectedLanguage = language
    }

    func selectDifficulty(_ difficulty: EssayDifficulty) {
        guard selectedDifficulty != difficulty else { return }
        selectedDifficulty = difficulty
    }

    func resetEssay() {
        essayText = ""
        score = nil
        resetAssistanceUsage()
        clearFeedback()
    }

    func clearFeedback() {
        grammarIssues = []
        errorState = nil
        feedbackState = .idle
        score = nil
    }

    func retryGrammarCheck() async {
        await checkGrammar()
    }

    func checkGrammar() async {
        updateWritingState()

        guard validationState.allowsGrammarCheck else {
            feedbackState = validationState == .empty
                ? .error("Write something before checking grammar.")
                : .error(validationState.message ?? "Check the word count first.")
            return
        }

        isLoading = true
        errorState = nil
        feedbackState = .loading

        do {
            let issues = try await grammarService.check(
                text: essayText,
                language: selectedLanguage.languageToolCode
            )

            grammarIssues = issues
            feedbackState = issues.isEmpty ? .emptyResult : .success

            // На цьому кроці score тільки готуємо як state.
            // Повний EssayScoringService підключимо наступним кроком.
            score = nil
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Grammar check failed. Try again."
            errorState = message
            feedbackState = .error(message)
        }

        isLoading = false
    }

    func registerHintUsage() {
        guard canUseHint else { return }
        usedHints += 1
    }

    func registerTranslationUsage() {
        guard canUseTranslation else { return }
        usedTranslations += 1
    }

    private func resetAssistanceUsage() {
        usedHints = 0
        usedTranslations = 0
    }

    private func updateWritingState() {
        wordCount = Self.countWords(in: essayText)

        if essayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationState = .empty
        } else if wordCount < currentTopic.wordRange.lowerBound {
            validationState = .belowMinimum(currentTopic.wordRange.lowerBound)
        } else if wordCount > currentTopic.wordRange.upperBound {
            validationState = .aboveMaximum(currentTopic.wordRange.upperBound)
        } else {
            validationState = .valid
        }

        if !grammarIssues.isEmpty || errorState != nil || score != nil {
            grammarIssues = []
            errorState = nil
            feedbackState = .idle
            score = nil
        }
    }

    static func countWords(in text: String) -> Int {
        text
            .split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }
}
