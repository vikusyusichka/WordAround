import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class StorySessionViewModel: ObservableObject {

    enum Phase: Equatable {
        case reading
        case questions
        case results
    }

    // MARK: - Published state

    @Published private(set) var session: StorySession?
    @Published private(set) var phase: Phase = .reading
    @Published private(set) var questions: [ReadingQuestion] = []
    @Published var selectedAnswers: [String: String] = [:]
    @Published private(set) var currentQuestionIndex = 0
    @Published private(set) var result: ReadingResult?

    @Published private(set) var isLoading = true
    @Published private(set) var isGeneratingNextChapter = false
    @Published var errorMessage: String?

    @Published private(set) var selectedChoice: StoryChoice?
    @Published private(set) var hasCompletedQuestions = false
    @Published private(set) var hasCompletedChapter = false
    @Published var navigateToResult = false
    @Published var showChoiceSection = false

    let assistance: ReadingAssistanceOptions

    @Published private(set) var selectedWord: String?
    @Published private(set) var selectedWordRange: NSRange?
    @Published private(set) var translatedWord: String?
    @Published private(set) var isTranslatingWord = false
    @Published private(set) var translationError: String?
    @Published var translationTargetLanguage: GrammarLanguage
    @Published private(set) var elapsedSeconds = 0

    // MARK: - Dependencies

    private enum Source {
        case new(StoryModeConfiguration)
        case existing(StorySession)
    }

    private let source: Source
    private let storyLanguage: GrammarLanguage

    private let storageService: StoryStorageServicing
    private let generationService: StoryGenerating
    private let questionService: ReadingQuestionGenerating
    private let scoringService: ReadingScoringServicing
    private let translationService: ReadingTranslationService
    private let analyzer: ReadingTextAnalyzing
    private let currentUserId: () -> String?

    private var timerCancellable: AnyCancellable?
    private var translationTask: Task<Void, Never>?
    private var hasLoaded = false

    // MARK: - Init

    init(
        setup: ReadingSessionSetup,
        storageService: StoryStorageServicing = StoryStorageService.shared,
        generationService: StoryGenerating = StoryGenerationService(),
        questionService: ReadingQuestionGenerating = ReadingQuestionService.shared,
        scoringService: ReadingScoringServicing = ReadingScoringService.shared,
        translationService: ReadingTranslationService = ReadingTranslationService(),
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        let configuration = StoryModeConfiguration(from: setup)
        self.source = .new(configuration)
        self.assistance = setup.toggles.isEmpty
            ? .default
            : ReadingAssistanceOptions.from(toggles: setup.toggles)
        self.storyLanguage = configuration.language
        self.translationTargetLanguage = self.assistance
            .resolvedTranslationTarget(sourceLanguage: configuration.language)
        self.storageService = storageService
        self.generationService = generationService
        self.questionService = questionService
        self.scoringService = scoringService
        self.translationService = translationService
        self.analyzer = analyzer
        self.currentUserId = currentUserId
    }

    init(
        item: ReadingLibraryItem,
        storageService: StoryStorageServicing = StoryStorageService.shared,
        generationService: StoryGenerating = StoryGenerationService(),
        questionService: ReadingQuestionGenerating = ReadingQuestionService.shared,
        scoringService: ReadingScoringServicing = ReadingScoringService.shared,
        translationService: ReadingTranslationService = ReadingTranslationService(),
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        let existing = StorySession.from(item: item)
        self.source = .existing(existing)
        self.assistance = item.toggles.isEmpty
            ? .default
            : ReadingAssistanceOptions.from(toggles: item.toggles)
        self.storyLanguage = existing.configuration.language
        self.translationTargetLanguage = self.assistance
            .resolvedTranslationTarget(sourceLanguage: existing.configuration.language)
        self.storageService = storageService
        self.generationService = generationService
        self.questionService = questionService
        self.scoringService = scoringService
        self.translationService = translationService
        self.analyzer = analyzer
        self.currentUserId = currentUserId
    }

    init(
        previewSession: StorySession,
        questions: [ReadingQuestion] = [],
        phase: Phase = .reading,
        storageService: StoryStorageServicing = MockStoryStorageService(),
        generationService: StoryGenerating = MockStoryGenerationService()
    ) {
        self.source = .existing(previewSession)
        self.assistance = .default
        self.storyLanguage = previewSession.configuration.language
        self.translationTargetLanguage = ReadingAssistanceOptions.default
            .resolvedTranslationTarget(sourceLanguage: previewSession.configuration.language)
        self.storageService = storageService
        self.generationService = generationService
        self.questionService = ReadingQuestionService.shared
        self.scoringService = ReadingScoringService.shared
        self.translationService = ReadingTranslationService()
        self.analyzer = ReadingTextAnalyzerService.shared
        self.currentUserId = { previewSession.userId }
        self.session = previewSession
        self.questions = questions
        self.phase = phase
        self.isLoading = false
        self.hasLoaded = true
    }

    // MARK: - Derived display

    var accent: Color { ReadingSetupConfig.storyMode.accent }
    var accentDark: Color { ReadingSetupConfig.storyMode.accentDark }

    var storyTitle: String { session?.title ?? "Story Mode" }
    var typeTitle: String { session?.configuration.storyType.title ?? "" }
    var difficultyTitle: String { session?.configuration.difficultyTitle ?? "" }
    var languageTitle: String { storyLanguage.title }
    var lengthTitle: String { session?.configuration.storyLength.title ?? "" }

    var currentChapter: StoryChapter? { session?.currentChapter }
    var chapterContent: String { currentChapter?.text ?? "" }
    var chapterTitle: String { currentChapter?.displayTitle ?? "Chapter 1" }
    var chapterProgressText: String { session?.progress.chapterProgressText ?? "" }
    var overallProgress: Double { session?.progress.overallProgress ?? 0 }

    var isShortStory: Bool { session?.configuration.storyLength == .shortStory }
    var isInfinite: Bool { session?.configuration.storyLength == .infinite }
    var branches: Bool { (session?.configuration.storyLength ?? .shortStory) != .shortStory }

    var hasQuestions: Bool { !questions.isEmpty }
    var showTimer: Bool { assistance.readingTimer }

    var availableChoices: [StoryChoice] { currentChapter?.choices ?? [] }

    var translationSourceLanguage: GrammarLanguage { storyLanguage }

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var currentQuestion: ReadingQuestion? {
        guard phase == .questions, currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var isLastQuestion: Bool { currentQuestionIndex >= questions.count - 1 }

    var selectedAnswer: String? {
        guard let question = currentQuestion else { return nil }
        return selectedAnswers[question.id]
    }

    var questionProgressText: String {
        guard hasQuestions else { return "" }
        return "Question \(currentQuestionIndex + 1) / \(questions.count)"
    }

    var isStoryCompleted: Bool { session?.status == .completed }

    enum PostResultPrimaryRoute {
        case exitToLibrary
        case showChoices
    }

    var postResultPrimaryActionTitle: String {
        if isStoryCompleted { return "Finish Story" }
        switch session?.configuration.storyLength {
        case .shortStory:   return "Finish Story"
        case .multiChapter: return "Choose What Happens Next"
        case .infinite:     return "Continue Story"
        case .none:         return "Continue"
        }
    }

    var postResultPrimaryActionIcon: String {
        if isStoryCompleted { return "checkmark.seal.fill" }
        switch session?.configuration.storyLength {
        case .shortStory:   return "checkmark.seal.fill"
        case .multiChapter, .infinite: return "arrow.triangle.branch"
        case .none:         return "arrow.right"
        }
    }

    // MARK: - Loading

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true
        errorMessage = nil

        guard let userId = currentUserId() else {
            errorMessage = "Sign in to read stories."
            isLoading = false
            return
        }

        do {
            switch source {
            case .new(let configuration):
                session = try await storageService.createSession(config: configuration, for: userId)
            case .existing(let existing):
                session = existing
                try? await storageService.markOpened(sessionId: existing.id, for: userId)
            }

            if session?.hasGeneratedContent != true {
                try await generateFirstChapter(userId: userId)
            }

            await prepareCurrentChapter()
            await startReading()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = readableMessage(for: error)
        }
    }

    func startReading() async {
        guard var current = session, let userId = currentUserId() else { return }
        if current.status == .new {
            current.status = .inProgress
            current.updatedAt = Date()
            session = current
            try? await storageService.updateProgress(current, toggles: assistance.asToggleDictionary(), for: userId)
        }
        if assistance.readingTimer, timerCancellable == nil { startTimer() }
    }

    private func generateFirstChapter(userId: String) async throws {
        guard var current = session else { return }
        let chapter = try await generationService.generateFirstChapter(for: current)
        current.chapters = [chapter]
        current.progress.currentChapterIndex = 0
        current.status = .inProgress
        current.updatedAt = Date()
        session = current
        try await storageService.updateProgress(current, toggles: assistance.asToggleDictionary(), for: userId)
    }

    private func prepareCurrentChapter() async {
        guard let current = session, let chapter = current.currentChapter else { return }
        stopTimer()
        phase = .reading
        selectedAnswers = [:]
        currentQuestionIndex = 0
        result = nil
        selectedChoice = nil
        navigateToResult = false
        showChoiceSection = false
        hasCompletedQuestions = chapter.isCompleted
        hasCompletedChapter = chapter.isCompleted
        elapsedSeconds = 0
        clearTranslation()

        if chapter.isCompleted && branches && chapter.madeChoice == nil && !chapter.choices.isEmpty {
            phase = .results
            showChoiceSection = true
        }

        let input = chapter.toReadingSessionInput(storySession: current)
        questions = await questionService.generateQuestions(
            for: input.asUserText(),
            focus: input.readingFocus,
            enabledTypes: input.questionTypes,
            maxQuestions: 6
        )

    }

    // MARK: - Reading → Questions

    func startQuestions() {
        guard hasQuestions else { return }
        clearTranslation()
        phase = .questions
        currentQuestionIndex = 0
    }

    func selectAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }
        selectedAnswers[question.id] = answer
    }

    func goToNextQuestion() {
        guard !isLastQuestion else { return }
        currentQuestionIndex += 1
    }

    func submitAnswers() async {
        stopTimer()
        guard let current = session, let chapter = current.currentChapter else { return }

        let input = chapter.toReadingSessionInput(storySession: current)
        let readingSession = input.makeReadingSession(questions: questions)
        let answers = buildAnswers()
        let scored = scoringService.score(
            session: readingSession,
            answers: answers,
            readingTimeSeconds: elapsedSeconds
        )
        result = scored
        hasCompletedQuestions = true
        phase = .results
        await completeChapter(scorePercent: scored.comprehensionPercent, readingTimeSeconds: elapsedSeconds)
    }

    func finishReadingWithoutQuestions() async {
        stopTimer()
        guard let current = session, let chapter = current.currentChapter else { return }

        let input = chapter.toReadingSessionInput(storySession: current)
        let wordCount = input.wordCount
        let wpm = elapsedSeconds > 0
            ? Int(Double(wordCount) / (Double(elapsedSeconds) / 60.0))
            : 0
        result = ReadingResult(
            sessionId: current.id,
            textId: input.id,
            comprehensionPercent: 0,
            correctAnswers: 0,
            totalQuestions: 0,
            readingTimeSeconds: elapsedSeconds,
            wordsPerMinute: wpm,
            mistakes: []
        )
        hasCompletedQuestions = true
        phase = .results
        await completeChapter(scorePercent: 0, readingTimeSeconds: elapsedSeconds)
    }

    // MARK: - Chapter completion + progress

    private func completeChapter(scorePercent: Double, readingTimeSeconds: Int) async {
        guard var current = session, let userId = currentUserId() else { return }
        let index = clampedCurrentIndex(in: current)
        guard current.chapters.indices.contains(index) else { return }

        current.chapters[index].isCompleted = true
        current.chapters[index].completedAt = Date()
        current.chapters[index].scorePercent = scorePercent
        current.chapters[index].readingTimeSeconds = readingTimeSeconds
        current.progress.completedChaptersCount = current.chapters.filter(\.isCompleted).count
        current.progress.totalReadingTimeSeconds += readingTimeSeconds
        current.progress.totalWordsRead += analyzer.wordCount(for: current.chapters[index].text)
        applyProgressMetrics(to: &current)
        current.updatedAt = Date()

        hasCompletedChapter = true
        session = current

        do {
            try await storageService.updateProgress(current, toggles: assistance.asToggleDictionary(), for: userId)
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    private func applyProgressMetrics(to session: inout StorySession) {
        switch session.configuration.storyLength {
        case .shortStory:
            session.progress.overallProgress = 1.0
            session.status = .completed
        case .multiChapter:
            let total = max(session.progress.totalChaptersTarget, session.chapters.count)
            session.progress.overallProgress = total > 0
                ? min(1.0, Double(session.progress.completedChaptersCount) / Double(total))
                : 0
            session.status = session.progress.overallProgress >= 1.0 ? .completed : .inProgress
        case .infinite:
            let completed = Double(session.progress.completedChaptersCount)
            session.progress.overallProgress = completed > 0 ? min(0.95, completed / (completed + 1)) : 0
            session.status = .inProgress
        }
    }

    // MARK: - Choices → next chapter

    func selectChoice(_ choice: StoryChoice) async {
        guard !isGeneratingNextChapter else { return }       // no double generation
        guard var current = session, let userId = currentUserId() else { return }
        guard branches else { return }

        selectedChoice = choice
        let index = clampedCurrentIndex(in: current)
        if current.chapters.indices.contains(index) {
            current.chapters[index].madeChoice = choice
            session = current
            try? await storageService.updateProgress(current, toggles: assistance.asToggleDictionary(), for: userId)
        }
        await generateNextChapter(from: choice)
    }

    func generateNextChapter(from choice: StoryChoice) async {
        guard var current = session, let userId = currentUserId() else { return }
        isGeneratingNextChapter = true
        errorMessage = nil

        do {
            let chapter = try await generationService.generateNextChapter(for: current, selectedChoice: choice)
            current.chapters.append(chapter)
            current.progress.currentChapterIndex = current.chapters.count - 1
            current.status = .inProgress
            current.updatedAt = Date()
            session = current
            try await storageService.updateProgress(current, toggles: assistance.asToggleDictionary(), for: userId)
            isGeneratingNextChapter = false
            await prepareCurrentChapter()
            await startReading()
        } catch {
            isGeneratingNextChapter = false
            errorMessage = readableMessage(for: error)
        }
    }

    func dismissResult(showChoices: Bool) {
        navigateToResult = false
        showChoiceSection = showChoices
    }

    @discardableResult
    func handlePostResultPrimaryAction() -> PostResultPrimaryRoute {
        if isStoryCompleted || isShortStory {
            dismissResult(showChoices: false)
            return .exitToLibrary
        }
        dismissResult(showChoices: true)
        return .showChoices
    }

    func restartChapterQuestions() async {
        guard let current = session, let chapter = current.currentChapter else { return }
        phase = .reading
        selectedAnswers = [:]
        currentQuestionIndex = 0
        result = nil
        hasCompletedQuestions = false
        hasCompletedChapter = chapter.isCompleted
        showChoiceSection = false
        elapsedSeconds = 0
        clearTranslation()
        if assistance.readingTimer { startTimer() }
    }

    func retryGeneration() async {
        errorMessage = nil
        guard let userId = currentUserId() else {
            errorMessage = "Sign in to read stories."
            return
        }
        if session == nil {
            hasLoaded = false
            await load()
            return
        }
        if session?.hasGeneratedContent != true {
            isLoading = true
            do {
                try await generateFirstChapter(userId: userId)
                await prepareCurrentChapter()
            } catch {
                errorMessage = readableMessage(for: error)
            }
            isLoading = false
        } else if let choice = selectedChoice {
            await generateNextChapter(from: choice)
        }
    }

    func endStory() async {
        guard var current = session, let userId = currentUserId() else { return }
        current.status = .completed
        current.progress.overallProgress = 1.0
        current.updatedAt = Date()
        session = current
        try? await storageService.updateProgress(current, toggles: assistance.asToggleDictionary(), for: userId)
    }

    func saveProgress() async {
        guard let current = session, let userId = currentUserId() else { return }
        try? await storageService.updateProgress(current, toggles: assistance.asToggleDictionary(), for: userId)
    }

    // MARK: - Lifecycle

    func onDisappear() {
        stopTimer()
        translationTask?.cancel()
        Task { await saveProgress() }
    }

    // MARK: - Answers

    private func buildAnswers() -> [ReadingAnswer] {
        questions.compactMap { question in
            guard let selected = selectedAnswers[question.id] else { return nil }
            return ReadingAnswer(
                questionId: question.id,
                selectedAnswer: selected,
                isCorrect: normalize(selected) == normalize(question.correctAnswer)
            )
        }
    }

    private func clampedCurrentIndex(in session: StorySession) -> Int {
        min(max(session.progress.currentChapterIndex, 0), max(session.chapters.count - 1, 0))
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Timer

    private func startTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.elapsedSeconds += 1 }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Translation (reuses ReadingTranslationService)

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
        guard language != storyLanguage else { return }
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
        defer { if !Task.isCancelled { isTranslatingWord = false } }

        do {
            let translation = try await translationService.translate(
                word: word,
                from: storyLanguage,
                to: translationTargetLanguage
            )
            guard !Task.isCancelled else { return }
            translatedWord = translation
        } catch {
            guard !Task.isCancelled else { return }
            translationError = (error as? LocalizedError)?.errorDescription ?? "Translation unavailable."
        }
    }

    // MARK: - Errors

    private func readableMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }
}
