import Foundation
import Combine

@MainActor
final class ReadingSessionViewModel: ObservableObject {
    @Published private(set) var session: ReadingSession?
    @Published var currentPhase: ReadingSessionPhase = .reading
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswers: [String: String] = [:]
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var result: ReadingResult?
    @Published var errorMessage: String?
    @Published var navigateToResult = false
    @Published var isLoadingSession = true
    @Published private(set) var selectedWord: String?
    @Published private(set) var selectedWordRange: NSRange?
    @Published private(set) var translatedWord: String?
    @Published private(set) var isTranslatingWord = false
    @Published private(set) var translationError: String?
    @Published var translationTargetLanguage: GrammarLanguage

    let userText: ReadingUserText
    let assistance: ReadingAssistanceOptions

    private var timerCancellable: AnyCancellable?
    private var translationTask: Task<Void, Never>?
    private let sessionService: ReadingSessionServicing
    private let analyzer: ReadingTextAnalyzing
    private let translationService: ReadingTranslationService
    private let statsService: DailyPracticeStatsService
    private var didRecordPracticeStats = false

    init(
        userText: ReadingUserText,
        sessionService: ReadingSessionServicing = ReadingSessionService.shared,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        translationService: ReadingTranslationService = ReadingTranslationService(),
        statsService: DailyPracticeStatsService = .shared
    ) {
        self.userText = userText
        self.assistance = userText.assistance
        self.translationTargetLanguage = userText.assistance.resolvedTranslationTarget(
            sourceLanguage: userText.language
        )
        self.sessionService = sessionService
        self.analyzer = analyzer
        self.translationService = translationService
        self.statsService = statsService
    }

    var translationSourceLanguage: GrammarLanguage { userText.language }

    var vocabularyHighlightTerms: [String] {
        guard userText.sourceType == .flashcardSet else { return [] }
        guard let raw = userText.sourceMetadata["vocabularyTerms"],
              let data = raw.data(using: .utf8),
              let terms = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return terms
    }

    var translationSourceTitle: String {
        translationSourceLanguage.title
    }

    var translationTargetTitle: String {
        translationTargetLanguage.title
    }

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var showTimer: Bool { assistance.readingTimer }

    var readingProgress: Double {
        guard let session else { return 0 }
        switch currentPhase {
        case .reading:
            let estimate = analyzer.estimatedReadingTimeSeconds(wordCount: session.wordCount)
            return min(0.45, Double(elapsedSeconds) / Double(max(estimate, 1)))
        case .questions:
            guard !session.questions.isEmpty else { return 0.6 }
            let questionProgress = Double(currentQuestionIndex + 1) / Double(session.questions.count)
            return 0.45 + (questionProgress * 0.45)
        case .completed:
            return 1
        }
    }

    var progressText: String {
        switch currentPhase {
        case .reading:
            return showTimer ? "Reading • \(formattedTime)" : "Reading"
        case .questions:
            guard let session, !session.questions.isEmpty else { return "Questions" }
            return "Question \(currentQuestionIndex + 1) / \(session.questions.count)"
        case .completed:
            return "Complete"
        }
    }

    var currentQuestion: ReadingQuestion? {
        guard currentPhase == .questions,
              let session,
              currentQuestionIndex < session.questions.count else { return nil }
        return session.questions[currentQuestionIndex]
    }

    var isLastQuestion: Bool {
        guard let session else { return true }
        return currentQuestionIndex >= session.questions.count - 1
    }

    var hasQuestions: Bool { session?.questions.isEmpty == false }

    var selectedAnswer: String? {
        guard let question = currentQuestion else { return nil }
        return selectedAnswers[question.id]
    }

    func loadSession() async {
        isLoadingSession = true
        let built = await sessionService.createSession(from: userText)
        session = built
        isLoadingSession = false
    }

    func onAppear() {
        if assistance.readingTimer { startTimer() }
    }

    func onDisappear() {
        stopTimer()
        translationTask?.cancel()
        guard currentPhase != .completed, let session else { return }
        Task {
            await sessionService.savePartialProgress(
                textId: session.textId,
                progress: readingProgress,
                lastReadCharacterIndex: Int(Double(session.content.count) * readingProgress)
            )
        }
    }

    func startQuestions() {
        clearTranslation()
        currentPhase = .questions
        currentQuestionIndex = 0
        guard let session else { return }
        Task {
            await sessionService.savePartialProgress(
                textId: session.textId,
                progress: 0.5,
                lastReadCharacterIndex: session.content.count / 2
            )
        }
    }

    func selectAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }
        selectedAnswers[question.id] = answer
    }

    func goToNextQuestion() {
        guard let question = currentQuestion else { return }
        recordAnswer(for: question)
        guard currentQuestionIndex < (session?.questions.count ?? 0) - 1 else { return }
        currentQuestionIndex += 1
    }

    func finishSession() {
        if currentPhase == .questions, let question = currentQuestion {
            recordAnswer(for: question)
        }
        stopTimer()
        guard var activeSession = session else { return }
        activeSession.readingTimeSeconds = elapsedSeconds

        recordPracticeStatsIfNeeded()

        let answers = buildAnswers()
        Task {
            let scored = await sessionService.completeSession(
                activeSession,
                answers: answers,
                readingTimeSeconds: elapsedSeconds
            )
            result = scored
            activeSession.result = scored
            session = activeSession
            currentPhase = .completed
            navigateToResult = true
        }
    }

    private func recordPracticeStatsIfNeeded() {
        guard !didRecordPracticeStats else { return }
        guard elapsedSeconds > 0 else { return }
        didRecordPracticeStats = true
        let modeID: String = userText.sourceType == .flashcardSet ? "reading-from-sets" : "my-texts"
        statsService.record(
            skill: .reading,
            value: elapsedSeconds,
            sourceModeID: modeID,
            sessionId: userText.id
        )
    }

    private func recordAnswer(for question: ReadingQuestion) {
        guard let selected = selectedAnswers[question.id] else { return }
        let answer = ReadingAnswer(
            questionId: question.id,
            selectedAnswer: selected,
            isCorrect: normalize(selected) == normalize(question.correctAnswer)
        )
        session?.answers.removeAll { $0.questionId == question.id }
        session?.answers.append(answer)
    }

    private func buildAnswers() -> [ReadingAnswer] {
        guard let session else { return [] }
        return session.questions.compactMap { question in
            guard let selected = selectedAnswers[question.id] else { return nil }
            return ReadingAnswer(
                questionId: question.id,
                selectedAnswer: selected,
                isCorrect: normalize(selected) == normalize(question.correctAnswer)
            )
        }
    }

    private func startTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedSeconds += 1
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func handleWordTap(_ word: String, range: NSRange) {
        guard assistance.translationOnTap || assistance.highlightUnknownWords else { return }

        let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count >= 2 else { return }

        if selectedWord?.caseInsensitiveCompare(cleaned) == .orderedSame,
           selectedWordRange?.location == range.location,
           selectedWordRange?.length == range.length {
            clearTranslation()
            return
        }

        selectedWord = cleaned
        selectedWordRange = range
        translatedWord = nil
        translationError = nil
        translationTask?.cancel()

        guard assistance.translationOnTap else { return }
        translationTask = Task { await translateSelectedWord(cleaned) }
    }

    func clearTranslation() {
        translationTask?.cancel()
        selectedWord = nil
        selectedWordRange = nil
        translatedWord = nil
        translationError = nil
        isTranslatingWord = false
    }

    func selectTranslationTarget(_ language: GrammarLanguage) {
        guard language != userText.language else { return }
        translationTargetLanguage = language
        translationError = nil
        guard assistance.translationOnTap, let word = selectedWord else { return }
        translationTask?.cancel()
        translatedWord = nil
        translationTask = Task { await translateSelectedWord(word) }
    }

    private func translateSelectedWord(_ word: String) async {
        isTranslatingWord = true
        translationError = nil
        translatedWord = nil

        defer {
            if !Task.isCancelled {
                isTranslatingWord = false
            }
        }

        do {
            let result = try await translationService.translate(
                word: word,
                from: userText.language,
                to: translationTargetLanguage
            )
            guard !Task.isCancelled else { return }
            translatedWord = result
        } catch {
            guard !Task.isCancelled else { return }
            translationError = (error as? LocalizedError)?.errorDescription ?? "Translation unavailable."
        }
    }
}

private extension ReadingTextAnalyzing {
    func estimatedReadingTimeSeconds(wordCount: Int) -> Int {
        max(30, estimatedReadingMinutes(wordCount: wordCount) * 60)
    }
}
