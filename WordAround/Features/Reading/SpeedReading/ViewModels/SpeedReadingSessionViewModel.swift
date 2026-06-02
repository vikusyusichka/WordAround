import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class SpeedReadingSessionViewModel: ObservableObject {

    enum Phase: Equatable {
        case loading
        case countdown
        case reading
        case questions
        case results
        case error(String)
    }

    @Published private(set) var session: SpeedReadingSession?
    @Published private(set) var phase: Phase = .loading
    @Published private(set) var loadingStepIndex = 0
    @Published private(set) var countdownValue = 3

    @Published private(set) var currentChunkIndex = 0
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var chunkElapsedSeconds = 0
    @Published private(set) var chunkSecondsRecorded: [Int] = []
    @Published private(set) var fontScale: CGFloat = 1.0
    @Published private(set) var isPaused = false

    @Published private(set) var questions: [ReadingQuestion] = []
    @Published private(set) var currentQuestionIndex = 0
    @Published var selectedAnswers: [String: String] = [:]

    @Published private(set) var result: SpeedReadingResult?
    @Published var errorMessage: String?

    private enum Source {
        case new(SpeedReadingConfiguration)
        case existing(SpeedReadingSession)
    }

    let setup: ReadingSessionSetup
    private let source: Source
    private let storage: ReadingStorageServicing
    private let generation: SpeedReadingGenerating
    private let questionService: ReadingQuestionGenerating
    private let scoring: ReadingScoringServicing
    private let analyzer: ReadingTextAnalyzing
    private let currentUserId: () -> String?

    private let timer = SpeedReadingTimerService()
    private var countdownTask: Task<Void, Never>?
    private var loadingStepTask: Task<Void, Never>?
    private var hasLoaded = false

    static let loadingSteps = [
        "Preparing practice…",
        "Calculating pace…",
        "Building reading session…"
    ]

    init(
        setup: ReadingSessionSetup,
        storage: ReadingStorageServicing = ReadingStorageService(),
        generation: SpeedReadingGenerating = SpeedReadingGenerationService(),
        questionService: ReadingQuestionGenerating = ReadingQuestionService.shared,
        scoring: ReadingScoringServicing = ReadingScoringService.shared,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        self.setup = setup
        self.source = .new(SpeedReadingConfiguration(from: setup))
        self.storage = storage
        self.generation = generation
        self.questionService = questionService
        self.scoring = scoring
        self.analyzer = analyzer
        self.currentUserId = currentUserId
    }

    init(
        item: ReadingLibraryItem,
        storage: ReadingStorageServicing = ReadingStorageService(),
        generation: SpeedReadingGenerating = SpeedReadingGenerationService(),
        questionService: ReadingQuestionGenerating = ReadingQuestionService.shared,
        scoring: ReadingScoringServicing = ReadingScoringService.shared,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        let existing = SpeedReadingSession.from(item: item)
        self.setup = ReadingSessionSetup(
            modeID: "speed-reading",
            language: existing.configuration.language,
            selections: existing.configuration.asSelections,
            toggles: [:],
            accent: ReadingSetupConfig.speedReading.accent,
            accentDark: ReadingSetupConfig.speedReading.accentDark,
            title: ReadingSetupConfig.speedReading.title,
            subtitle: ReadingSetupConfig.speedReading.subtitle
        )
        self.source = .existing(existing)
        self.storage = storage
        self.generation = generation
        self.questionService = questionService
        self.scoring = scoring
        self.analyzer = analyzer
        self.currentUserId = currentUserId
    }

    var configuration: SpeedReadingConfiguration {
        if let session { return session.configuration }
        if case let .new(config) = source { return config }
        return SpeedReadingConfiguration(from: setup)
    }

    var accent: Color { setup.accent }
    var accentDark: Color { setup.accentDark }

    var chunks: [String] { session?.chunks ?? [] }
    var hasChunks: Bool { !chunks.isEmpty }
    var currentChunkText: String {
        guard chunks.indices.contains(currentChunkIndex) else { return "" }
        return chunks[currentChunkIndex]
    }
    var isLastChunk: Bool { currentChunkIndex >= chunks.count - 1 }

    var targetWPM: Int { configuration.wpmTarget }
    var paceLabel: String { configuration.target.title }

    var wordsRead: Int {
        let completed = chunks.prefix(currentChunkIndex).map { analyzer.wordCount(for: $0) }
        return completed.reduce(0, +) + (chunks.indices.contains(currentChunkIndex) ? analyzer.wordCount(for: chunks[currentChunkIndex]) : 0)
    }

    var currentWPM: Int {
        SpeedReadingMetricsService.wpm(wordsRead: wordsRead, seconds: elapsedSeconds)
    }

    var paceStatus: String {
        SpeedReadingMetricsService.paceStatus(currentWPM: currentWPM, target: configuration.target)
    }

    var totalWords: Int { analyzer.wordCount(for: session?.text ?? "") }

    var readingProgress: Double {
        guard !chunks.isEmpty else { return 0 }
        let denom = Double(chunks.count)
        return Double(currentChunkIndex + 1) / denom
    }

    var chunkTimeRemaining: Int {
        let target = configuration.chunkSeconds
        guard target > 0 else { return 0 }
        return max(0, target - chunkElapsedSeconds)
    }

    var timerText: String { SpeedReadingTimerFormat.mmss(elapsedSeconds) }

    var chunkTimerText: String {
        if configuration.timer.enforcesPace {
            return SpeedReadingTimerFormat.mmss(chunkTimeRemaining)
        }
        return SpeedReadingTimerFormat.mmss(chunkElapsedSeconds)
    }

    var chunkTimerLabel: String {
        configuration.timer.enforcesPace ? "Time left" : "Chunk time"
    }

    var countdownChips: [String] { configuration.summaryChips }

    var hasQuestions: Bool { !questions.isEmpty }

    var currentQuestion: ReadingQuestion? {
        guard phase == .questions, currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var isLastQuestion: Bool { currentQuestionIndex >= questions.count - 1 }

    var selectedAnswer: String? {
        guard let id = currentQuestion?.id else { return nil }
        return selectedAnswers[id]
    }

    var questionProgressText: String {
        guard hasQuestions else { return "" }
        return "Question \(currentQuestionIndex + 1) / \(questions.count)"
    }

    var sessionTitle: String { session?.title ?? "Speed Reading" }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        phase = .loading
        startLoadingTicker()

        let userId = currentUserId()
        var workingSession: SpeedReadingSession

        switch source {
        case .new(let configuration):
            workingSession = SpeedReadingSession(
                userId: userId ?? "guest",
                configuration: configuration
            )
        case .existing(let existing):
            workingSession = existing
            if let userId {
                try? await storage.updateLastOpened(
                    itemId: existing.id,
                    mode: Self.speedReadingMode,
                    for: userId
                )
            }
        }

        do {
            if !workingSession.hasGeneratedContent {
                let generated = try await generation.generateReading(for: workingSession.configuration)
                workingSession.text = generated.text
                workingSession.chunks = generated.chunks
            } else if workingSession.chunks.isEmpty {
                workingSession.chunks = SpeedReadingGenerationService.makeChunks(
                    from: workingSession.text,
                    configuration: workingSession.configuration
                )
            }
            session = workingSession
            await buildQuestions(for: workingSession)
            await persist(session: workingSession, userId: userId)

            stopLoadingTicker()
            await startCountdown()
        } catch {
            stopLoadingTicker()
            let message = readableMessage(for: error)
            errorMessage = message
            phase = .error(message)
        }
    }

    private func startLoadingTicker() {
        loadingStepIndex = 0
        loadingStepTask?.cancel()
        loadingStepTask = Task { [weak self] in
            for index in 0..<Self.loadingSteps.count {
                try? await Task.sleep(nanoseconds: 700_000_000)
                guard let self, !Task.isCancelled else { return }
                self.loadingStepIndex = index
            }
        }
    }

    private func stopLoadingTicker() {
        loadingStepTask?.cancel()
        loadingStepTask = nil
    }

    private func buildQuestions(for session: SpeedReadingSession) async {
        let input = ReadingSessionInput(
            id: session.id,
            modeID: "speed-reading",
            title: session.title,
            fullText: session.text,
            language: session.configuration.language,
            difficulty: EssayDifficulty.from(title: session.configuration.length.title) ?? .b1,
            readingFocus: .speedFluency,
            questionTypes: [.comprehension, .trueFalse, .findEvidence],
            assistance: .default,
            sourceType: .speedPractice,
            sourceId: session.id
        )
        let max = session.configuration.length.questionTarget
        questions = await questionService.generateQuestions(
            for: input.asUserText(),
            focus: .speedFluency,
            enabledTypes: input.questionTypes,
            maxQuestions: max
        )
    }

    func startCountdown() async {
        phase = .countdown
        countdownValue = 3
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }
            for value in stride(from: 3, through: 1, by: -1) {
                self.countdownValue = value
                try? await Task.sleep(nanoseconds: 900_000_000)
                if Task.isCancelled { return }
            }
            self.beginReading()
        }
    }

    func beginReading() {
        guard hasChunks else {
            phase = .error("This reading came back empty. Try generating again.")
            return
        }
        phase = .reading
        currentChunkIndex = 0
        elapsedSeconds = 0
        chunkElapsedSeconds = 0
        chunkSecondsRecorded = []
        isPaused = false
        startTickingIfNeeded()
    }

    private func startTickingIfNeeded() {
        guard phase == .reading, !isPaused else { return }
        timer.start { [weak self] _ in
            guard let self else { return }
            self.tick()
        }
    }

    private func tick() {
        elapsedSeconds += 1
        chunkElapsedSeconds += 1
        if configuration.timer.enforcesPace, configuration.timer.locksChunkOnExpire,
           chunkElapsedSeconds >= configuration.chunkSeconds {
            advanceChunk()
        }
    }

    func togglePause() {
        guard phase == .reading else { return }
        isPaused.toggle()
        if isPaused {
            timer.stop()
        } else {
            startTickingIfNeeded()
        }
    }

    func advanceChunk() {
        guard phase == .reading else { return }
        recordChunkTime()
        if isLastChunk {
            finishReading()
            return
        }
        currentChunkIndex += 1
        chunkElapsedSeconds = 0
    }

    func goPreviousChunk() {
        guard phase == .reading, currentChunkIndex > 0 else { return }
        currentChunkIndex -= 1
        chunkElapsedSeconds = 0
    }

    func increaseFont() { fontScale = min(fontScale + 0.1, 1.4) }
    func decreaseFont() { fontScale = max(fontScale - 0.1, 0.8) }

    private func recordChunkTime() {
        chunkSecondsRecorded.append(chunkElapsedSeconds)
    }

    private func finishReading() {
        timer.stop()
        if hasQuestions {
            phase = .questions
            currentQuestionIndex = 0
        } else {
            Task { await computeAndPersistResult() }
        }
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
        await computeAndPersistResult()
    }

    private func computeAndPersistResult() async {
        timer.stop()
        guard var working = session else { return }

        let answers = buildAnswers()
        let input = ReadingSessionInput(
            id: working.id,
            modeID: "speed-reading",
            title: working.title,
            fullText: working.text,
            language: working.configuration.language,
            difficulty: EssayDifficulty.from(title: working.configuration.length.title) ?? .b1,
            readingFocus: .speedFluency,
            questionTypes: [.comprehension, .trueFalse, .findEvidence],
            sourceType: .speedPractice,
            sourceId: working.id
        )
        let scored = scoring.score(
            session: input.makeReadingSession(questions: questions),
            answers: answers,
            readingTimeSeconds: max(1, elapsedSeconds)
        )
        let violations = SpeedReadingMetricsService.timerViolations(
            chunkSeconds: chunkSecondsRecorded,
            target: working.configuration
        )
        let rating = working.configuration.target.rating(forAchievedWPM: scored.wordsPerMinute)
        let speedResult = SpeedReadingResult(
            base: scored,
            targetWPM: working.configuration.wpmTarget,
            timerViolations: violations,
            rating: rating
        )
        result = speedResult
        working.record(result: speedResult)
        working.status = .completed
        working.progress = 1.0
        working.updatedAt = Date()
        session = working

        DailyPracticeStatsService.shared.record(
            skill: .reading,
            value: max(1, elapsedSeconds),
            sourceModeID: "speed-reading",
            sessionId: working.id
        )

        phase = .results
        await persist(session: working, userId: currentUserId())
    }

    private func buildAnswers() -> [ReadingAnswer] {
        questions.compactMap { question in
            guard let selected = selectedAnswers[question.id] else { return nil }
            let isCorrect = selected.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() == question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return ReadingAnswer(
                questionId: question.id,
                selectedAnswer: selected,
                isCorrect: isCorrect
            )
        }
    }

    func retry() async {
        errorMessage = nil
        hasLoaded = false
        phase = .loading
        await load()
    }

    func onDisappear() {
        timer.reset()
        countdownTask?.cancel()
        loadingStepTask?.cancel()
    }

    private func persist(session: SpeedReadingSession, userId: String?) async {
        guard let userId else { return }
        do {
            try await storage.updateItem(session.toLibraryItem(), for: userId)
        } catch {
            #if DEBUG
            print("[SpeedReadingSessionViewModel] persist failed:", error)
            #endif
        }
    }

    private func readableMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }

    private static var speedReadingMode: ReadingMode {
        ReadingMode(
            id: "speed-reading",
            title: ReadingSetupConfig.speedReading.title,
            subtitle: ReadingSetupConfig.speedReading.subtitle,
            systemImage: "bolt.fill",
            accentColor: ReadingSetupConfig.speedReading.accent,
            blobColor: ReadingSetupConfig.speedReading.accent.opacity(0.18)
        )
    }
}

private extension EssayDifficulty {
    static func from(title: String) -> EssayDifficulty? {
        EssayDifficulty.allCases.first { $0.rawValue.caseInsensitiveCompare(title) == .orderedSame }
    }
}
