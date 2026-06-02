import Foundation
import SwiftUI
import Combine

@MainActor
final class DebateModeViewModel: ObservableObject {

    @Published private(set) var messages: [SpeakingConversationMessage] = []
    @Published private(set) var partialTranscript: String = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published var errorMessage: String?

    @Published private(set) var session: DebateSession?
    @Published private(set) var isGeneratingTopic = false
    @Published private(set) var didUseFallbackReply = false
    @Published private(set) var usedFallbackTopic = false

    @Published var currentHint: String?

    @Published private(set) var conversationFeedback: SpeakingConversationFeedback?
    @Published private(set) var isGeneratingFeedback = false
    @Published private(set) var feedbackError: String?

    @Published private(set) var remainingSeconds: Int = 0

    let setup: SpeakingConversationSetup
    let requestedSide: DebateSide

    var currentRound: DebateRound? { session?.currentRound }
    var rounds: [DebateRound] { session?.rounds ?? [] }
    var currentRoundIndex: Int { session?.currentRoundIndex ?? 0 }

    var learnerSide: DebateSide { session?.learnerSide ?? requestedSide.resolvedConcreteSide() }

    var formattedRemainingTime: String {
        let s = max(0, remainingSeconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    var isTimeRunningOut: Bool { remainingSeconds > 0 && remainingSeconds < 60 }

    var onDebateEnded: (() -> Void)?

    private let recognizer: SpeechRecognitionService
    private let synthesizer: SpeechSynthesisService
    private let debateService: DebateConversationService
    private let topicService: SpeakingTopicGenerationService
    private let feedbackService: SpeakingFeedbackService

    private var hasStarted = false
    private var hasEnded = false
    private var didRecordPracticeStats = false
    private let statsService: DailyPracticeStatsService
    private var permissionsRequested = false

    private var lastSubmittedTranscript = ""
    private var lastGeminiSendAt: Date?
    private let geminiCooldownSeconds: TimeInterval = 2

    private var hintIndex = 0
    private let hintAutoHideSeconds: UInt64 = 6

    private var timerTask: Task<Void, Never>?
    private var topicTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var hintAutoHideTask: Task<Void, Never>?

    init(
        setup: SpeakingConversationSetup,
        side: DebateSide,
        recognizer: SpeechRecognitionService? = nil,
        synthesizer: SpeechSynthesisService? = nil,
        debateService: DebateConversationService? = nil,
        topicService: SpeakingTopicGenerationService? = nil,
        feedbackService: SpeakingFeedbackService? = nil,
        statsService: DailyPracticeStatsService = .shared
    ) {
        self.setup = setup
        self.requestedSide = side
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.synthesizer = synthesizer ?? SpeechSynthesisService()
        self.debateService = debateService
            ?? DebateConversationService(client: GeminiSpeakingAIClient())
        self.topicService = topicService ?? SpeakingTopicGenerationService()
        self.feedbackService = feedbackService ?? SpeakingFeedbackService()
        self.statsService = statsService
        self.remainingSeconds = setup.length.minutes * 60

        wireRecognizerCallbacks()
        wireSynthesizerCallbacks()
    }

    deinit {
        timerTask?.cancel()
        topicTask?.cancel()
        feedbackTask?.cancel()
        hintAutoHideTask?.cancel()
    }

    private func wireRecognizerCallbacks() {
        recognizer.onPartialTranscript = { [weak self] text in
            self?.partialTranscript = text
        }
        recognizer.onFinalTranscript = { [weak self] text in
            self?.handleFinalTranscript(text)
        }
        recognizer.onError = { [weak self] error in
            guard let self else { return }
            self.partialTranscript = ""
            self.errorMessage = error.localizedDescription
            self.state = .error(error.localizedDescription)
            Task.detached(priority: .utility) { [weak self] in
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run { self?.state = .idle }
            }
        }
    }

    private func wireSynthesizerCallbacks() {
        synthesizer.onStart = { [weak self] in
            self?.state = .speaking
        }
        synthesizer.onFinish = { [weak self] in
            guard let self else { return }
            if case .speaking = self.state { self.state = .idle }
        }
    }

    func startDebate() {
        guard !hasStarted else { return }
        hasStarted = true
        hasEnded = false

        #if DEBUG
        print("[DebateVM] startDebate lang=\(setup.language.title) level=\(setup.level.rawValue) length=\(setup.length.title) side=\(requestedSide.rawValue)")
        #endif

        startTimer()
        generateTopicAndOpen()
    }

    func endDebate() {
        guard !hasEnded else { return }
        hasEnded = true

        #if DEBUG
        print("[DebateVM] endDebate messages=\(messages.count)")
        #endif
        recognizer.cancel()
        synthesizer.stop()
        stopTimer()
        partialTranscript = ""
        clearHint()
        state = .idle

        recordPracticeStatsIfNeeded()

        if conversationFeedback == nil && !isGeneratingFeedback {
            beginFeedbackGeneration()
        }
    }

    private func recordPracticeStatsIfNeeded() {
        guard hasStarted, !didRecordPracticeStats else { return }
        let total = setup.length.minutes * 60
        let practiced = max(0, total - remainingSeconds)
        guard practiced > 0 else { return }
        didRecordPracticeStats = true
        statsService.record(
            skill: .speaking,
            value: practiced,
            sourceModeID: "debate-mode"
        )
    }

    func resetDebate() {
        endDebate()
        feedbackTask?.cancel(); feedbackTask = nil
        topicTask?.cancel(); topicTask = nil
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil
        messages.removeAll()
        session = nil
        isGeneratingTopic = false
        hasStarted = false
        hasEnded = false
        didRecordPracticeStats = false
        errorMessage = nil
        didUseFallbackReply = false
        usedFallbackTopic = false
        lastSubmittedTranscript = ""
        lastGeminiSendAt = nil
        remainingSeconds = setup.length.minutes * 60
    }

    private func generateTopicAndOpen() {
        isGeneratingTopic = true
        state = .processing

        let language = setup.language
        let level = setup.level
        let length = setup.length
        let service = topicService

        topicTask?.cancel()
        topicTask = Task.detached(priority: .utility) { [weak self] in
            let (topic, usedFallback) = await service.topic(
                for: language,
                level: level,
                length: length,
                avoidTitles: [],
                forceRefresh: true
            )
            if Task.isCancelled { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.isGeneratingTopic = false
                self.usedFallbackTopic = usedFallback
                let rounds = DebatePlan.rounds(for: self.setup.length)
                self.session = DebateSession(topic: topic, requestedSide: self.requestedSide, rounds: rounds)
                self.requestAIOpening()
            }
        }
    }

    private func requestAIOpening() {
        guard let session else { return }
        state = .processing

        let language = setup.language
        let level = setup.level
        let service = debateService
        let topic = session.topic
        let learnerSide = session.learnerSide
        let aiSide = session.aiSide

        Task.detached(priority: .utility) { [weak self] in
            do {
                let opening = try await service.requestOpening(
                    language: language,
                    level: level,
                    topic: topic,
                    learnerSide: learnerSide,
                    aiSide: aiSide
                )
                let trimmed = opening.trimmingCharacters(in: .whitespacesAndNewlines)
                let final = trimmed.isEmpty
                    ? DebateConversationService.fallbackOpening(for: language, topicTitle: topic.title)
                    : trimmed
                await MainActor.run { [weak self] in
                    self?.didUseFallbackReply = trimmed.isEmpty
                    self?.appendAIMessage(final)
                    self?.speak(final)
                }
            } catch {
                let fallback = DebateConversationService.fallbackOpening(for: language, topicTitle: topic.title)
                await MainActor.run { [weak self] in
                    self?.didUseFallbackReply = true
                    self?.errorMessage = DebateConversationService.fallbackBannerText(for: language)
                    self?.appendAIMessage(fallback)
                    self?.speak(fallback)
                }
            }
        }
    }

    func toggleListening() async {
        if isGeneratingTopic { return }
        switch state {
        case .idle, .error:
            await startListening()
        case .listening:
            stopListeningAndSend()
        case .processing, .speaking:
            break
        }
    }

    func startListening() async {
        synthesizer.stop()
        if !permissionsRequested {
            permissionsRequested = true
            let granted = await recognizer.requestPermissions()
            guard granted else { return }
        }
        await recognizer.start(localeIdentifier: setup.speechLocaleIdentifier)
        if recognizer.isListening {
            clearHint()
            state = .listening
        }
    }

    func stopListeningAndSend() {
        guard recognizer.isListening else { return }
        state = .processing
        Task { await recognizer.stop() }
    }

    private func handleFinalTranscript(_ text: String) {
        partialTranscript = ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty { state = .idle; return }
        if trimmed == lastSubmittedTranscript { state = .idle; return }
        if let last = lastGeminiSendAt, Date().timeIntervalSince(last) < geminiCooldownSeconds {
            state = .idle
            return
        }

        lastSubmittedTranscript = trimmed
        lastGeminiSendAt = Date()
        sendUserTranscript(trimmed)
    }

    func sendUserTranscript(_ text: String) {
        clearHint()
        messages.append(SpeakingConversationMessage(role: .user, text: text))
        state = .processing
        Task.detached(priority: .utility) { [weak self] in
            await self?.generateAIResponse(for: text)
        }
    }

    func generateAIResponse(for text: String) async {
        let snapshot: (
            session: DebateSession?,
            history: [SpeakingConversationMessage],
            language: GrammarLanguage,
            level: EssayDifficulty,
            service: DebateConversationService
        ) = await MainActor.run {
            (session, messages, setup.language, setup.level, debateService)
        }

        guard let session = snapshot.session, let round = session.currentRound else {
            await MainActor.run { state = .idle }
            return
        }

        do {
            let reply = try await snapshot.service.requestReply(
                language: snapshot.language,
                level: snapshot.level,
                topic: session.topic,
                learnerSide: session.learnerSide,
                aiSide: session.aiSide,
                round: round,
                history: snapshot.history,
                userMessage: text
            )
            let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            let final = trimmed.isEmpty
                ? DebateConversationService.fallbackReply(for: snapshot.language)
                : trimmed
            await MainActor.run { [weak self] in
                self?.didUseFallbackReply = trimmed.isEmpty
                self?.appendAIMessage(final)
                self?.speak(final)
                self?.advanceRound()
            }
        } catch {
            let fallback = DebateConversationService.fallbackReply(for: snapshot.language)
            await MainActor.run { [weak self] in
                self?.didUseFallbackReply = true
                self?.errorMessage = DebateConversationService.fallbackBannerText(for: snapshot.language)
                self?.appendAIMessage(fallback)
                self?.speak(fallback)
                self?.advanceRound()
            }
        }
    }

    func advanceRound() {
        guard var session else { return }
        let didAdvance = session.advance()
        self.session = session

        #if DEBUG
        print("[DebateVM] advanceRound → index=\(session.currentRoundIndex) didAdvance=\(didAdvance)")
        #endif

        if !didAdvance {
            endDebate()
            onDebateEnded?()
        }
    }

    private func appendAIMessage(_ text: String) {
        messages.append(SpeakingConversationMessage(role: .ai, text: text))
    }

    private func speak(_ text: String) {
        state = .speaking
        synthesizer.speak(text, localeIdentifier: setup.speechLocaleIdentifier)
    }

    func requestHint() {
        if case .processing = state { return }
        if case .listening = state { return }

        let hints = DebateConversationService.localHints(for: setup.language)
        guard !hints.isEmpty else { return }
        let hint = hints[hintIndex % hints.count]
        hintIndex += 1
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            currentHint = hint
        }
        scheduleHintAutoHide(hint)
    }

    func clearHint() {
        hintAutoHideTask?.cancel()
        hintAutoHideTask = nil
        if currentHint != nil { currentHint = nil }
    }

    private func scheduleHintAutoHide(_ hint: String) {
        hintAutoHideTask?.cancel()
        hintAutoHideTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let seconds = await MainActor.run { self.hintAutoHideSeconds }
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                if self.currentHint == hint { self.currentHint = nil }
            }
        }
    }

    func startTimer() {
        timerTask?.cancel()
        remainingSeconds = setup.length.minutes * 60
        timerTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    guard let self else { return }
                    if self.remainingSeconds > 0 { self.remainingSeconds -= 1 }
                    if self.remainingSeconds == 0 { self.handleTimerFinished() }
                }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func handleTimerFinished() {
        guard timerTask != nil else { return }
        stopTimer()
        recognizer.cancel()
        synthesizer.stop()
        state = .idle
        endDebate()
        onDebateEnded?()
    }

    private func beginFeedbackGeneration() {
        let language = setup.language
        let level = setup.level
        let topicContext: SpeakingConversationContext? = session.map { .generatedTopic($0.topic) }
        let snapshotMessages = messages
        let service = feedbackService

        isGeneratingFeedback = true
        feedbackError = nil

        feedbackTask?.cancel()
        feedbackTask = Task.detached(priority: .utility) { [weak self] in
            let result = await service.generateFeedback(
                language: language,
                level: level,
                context: topicContext,
                messages: snapshotMessages,
                includeDebateMetrics: true
            )
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self else { return }
                self.conversationFeedback = result.feedback
                self.isGeneratingFeedback = false
                self.feedbackError = result.fallbackReason
            }
        }
    }

    func clearError() {
        errorMessage = nil
        didUseFallbackReply = false
        usedFallbackTopic = false
    }
}

extension DebateModeViewModel: SpeakingResultProvidable {}
