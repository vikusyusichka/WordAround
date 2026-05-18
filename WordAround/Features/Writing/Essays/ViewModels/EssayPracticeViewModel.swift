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

    @Published private(set) var wordCount: Int = 0
    @Published private(set) var grammarIssues: [GrammarIssue] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorState: String?
    @Published private(set) var validationState: ValidationState = .empty
    @Published private(set) var feedbackState: FeedbackState = .idle

    private let topics: [EssayTopic]
    private let grammarService: GrammarChecking

    init(
        topics: [EssayTopic] = EssayTopic.predefined,
        grammarService: GrammarChecking = GrammarCheckService()
    ) {
        self.topics = topics.isEmpty ? [.fallback] : topics
        self.currentTopic = topics.randomElement() ?? .fallback
        self.grammarService = grammarService
        self.essayText = ""
        updateWritingState()
    }

    var canCheckGrammar: Bool {
        !isLoading && validationState.allowsGrammarCheck
    }

    func selectRandomTopic() {
        let nextTopic = topics.filter { $0.id != currentTopic.id }.randomElement() ?? topics.randomElement() ?? .fallback
        currentTopic = nextTopic
        resetEssay()
    }

    func resetEssay() {
        essayText = ""
        clearFeedback()
    }

    func clearFeedback() {
        grammarIssues = []
        errorState = nil
        feedbackState = .idle
    }

    func retryGrammarCheck() async {
        await checkGrammar()
    }

    func checkGrammar() async {
        updateWritingState()

        guard validationState.allowsGrammarCheck else {
            feedbackState = validationState == .empty ? .error("Write something before checking grammar.") : .error(validationState.message ?? "Check the word count first.")
            return
        }

        isLoading = true
        errorState = nil
        feedbackState = .loading

        do {
            let issues = try await grammarService.check(text: essayText, language: "en-US")
            grammarIssues = issues
            feedbackState = issues.isEmpty ? .emptyResult : .success
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Grammar check failed. Try again."
            errorState = message
            feedbackState = .error(message)
        }

        isLoading = false
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

        if !grammarIssues.isEmpty || errorState != nil {
            grammarIssues = []
            errorState = nil
            feedbackState = .idle
        }
    }

    static func countWords(in text: String) -> Int {
        text
            .split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }
}
