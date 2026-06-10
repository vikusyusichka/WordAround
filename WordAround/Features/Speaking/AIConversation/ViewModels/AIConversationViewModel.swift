import Foundation
import SwiftUI
import Combine

@MainActor
final class AIConversationViewModel: ObservableObject {

    @Published private(set) var messages: [SpeakingConversationMessage] = []
    @Published private(set) var partialTranscript: String = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published var errorMessage: String?

    @Published private(set) var context: SpeakingConversationContext?

    @Published private(set) var isGeneratingTopic = false

    @Published private(set) var didUseFallbackReply = false

    @Published private(set) var usedFallbackTopic = false

    @Published private(set) var generatedTopic: GeneratedConversationTopic?

    @Published private(set) var topicGenerationError: String?

    private var triedTopicTitles: [String] = []
    private var triedTopicTitlesLoaded = false
    private var topicGenerationTask: Task<Void, Never>?
    private let recentTitlesStore = SpeakingRecentTopicTitlesStore.shared

    @Published var currentHint: String?

    @Published private(set) var isRequestingHint: Bool = false

    @Published var showTopicPicker: Bool = false

    var selectedScenario: ConversationScenario? {
        if case .scenario(let s) = context { return s }
        return nil
    }

    @Published private(set) var conversationFeedback: SpeakingConversationFeedback?

    @Published private(set) var isGeneratingFeedback: Bool = false

    @Published private(set) var feedbackError: String?

    private let feedbackService: SpeakingFeedbackService
    private var feedbackTask: Task<Void, Never>?

    @Published private(set) var remainingSeconds: Int = 0

    var formattedRemainingTime: String {
        let s = max(0, remainingSeconds)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    var isTimeRunningOut: Bool { remainingSeconds > 0 && remainingSeconds < 60 }
    var isTimeUp: Bool { remainingSeconds == 0 && hasStarted }

    var onTimerFinished: (() -> Void)?

    private var timerTask: Task<Void, Never>?

    private var hintAutoHideTask: Task<Void, Never>?

    private let hintAutoHideSeconds: UInt64 = 9

    let setup: SpeakingConversationSetup

    private let recognizer: SpeechRecognitionService
    private let synthesizer: SpeechSynthesisService
    private let conversationService: SpeakingConversationService
    private let topicService: SpeakingTopicGenerationService

    private var hasStarted = false
    private var didRecordPracticeStats = false
    private let statsService: DailyPracticeStatsService
    private var permissionsRequested = false

    private var lastSubmittedTranscript: String = ""

    private var lastGeminiSendAt: Date?
    private let geminiCooldownSeconds: TimeInterval = 2

    init(
        setup: SpeakingConversationSetup,
        recognizer: SpeechRecognitionService? = nil,
        synthesizer: SpeechSynthesisService? = nil,
        conversationService: SpeakingConversationService? = nil,
        topicService: SpeakingTopicGenerationService? = nil,
        feedbackService: SpeakingFeedbackService? = nil,
        statsService: DailyPracticeStatsService = .shared
    ) {
        self.setup = setup
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.synthesizer = synthesizer ?? SpeechSynthesisService()
        self.conversationService = conversationService
            ?? SpeakingConversationService(client: GeminiSpeakingAIClient())
        self.topicService = topicService ?? SpeakingTopicGenerationService()
        self.feedbackService = feedbackService ?? SpeakingFeedbackService()
        self.statsService = statsService
        self.remainingSeconds = setup.length.minutes * 60

        wireRecognizerCallbacks()
        wireSynthesizerCallbacks()
    }

    deinit {
        timerTask?.cancel()
        hintAutoHideTask?.cancel()
        feedbackTask?.cancel()
        topicGenerationTask?.cancel()
    }

    private func wireRecognizerCallbacks() {
        recognizer.onPartialTranscript = { [weak self] text in
            guard let self else { return }
            guard self.state.isListening else { return }
            self.partialTranscript = text
        }

        recognizer.onFinalTranscript = { [weak self] text in
            guard let self else { return }
            self.handleFinalTranscript(text)
        }

        recognizer.onError = { [weak self] error in
            guard let self else { return }
            self.partialTranscript = ""
            self.errorMessage = error.localizedDescription
            self.state = .error(error.localizedDescription)
            Task.detached(priority: .utility) { [weak self] in
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    self?.state = .idle
                }
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

    func startConversation() {
        guard !hasStarted else { return }
        hasStarted = true

        #if DEBUG
        print("[ConversationVM] startConversation language=\(setup.language.title) level=\(setup.level.rawValue) length=\(setup.length.title) scenario=\(setup.scenario?.title ?? "<auto>")")
        #endif

        startTimer()

        if let scenario = setup.scenario {
            self.context = .scenario(scenario)
            seedOpeningMessage(.scenario(scenario))
        } else {

            isGeneratingTopic = true
            state = .processing
            topicGenerationTask?.cancel()
            topicGenerationTask = runTopicGeneration(
                avoidTitles: [],
                forceRefresh: true,
                applyToConversation: true
            )
        }
    }

    private func seedOpeningMessage(_ context: SpeakingConversationContext) {
        let firstText = context.firstAIMessage(for: setup.language)
        guard !firstText.isEmpty else { return }
        appendAIMessage(firstText)
        speakAIResponse(firstText)
    }

    func endConversation() {
        #if DEBUG
        print("[ConversationVM] endConversation messages=\(messages.count)")
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
            sourceModeID: "ai-conversation"
        )
    }

    func resetConversation() {
        endConversation()
        feedbackTask?.cancel()
        feedbackTask = nil
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil
        topicGenerationTask?.cancel()
        topicGenerationTask = nil
        generatedTopic = nil
        topicGenerationError = nil
        triedTopicTitles.removeAll()
        triedTopicTitlesLoaded = false
        messages.removeAll()
        hasStarted = false
        didRecordPracticeStats = false
        errorMessage = nil
        didUseFallbackReply = false
        usedFallbackTopic = false
        lastSubmittedTranscript = ""
        lastGeminiSendAt = nil
        remainingSeconds = setup.length.minutes * 60
        context = nil
    }

    func applyStandardScenario(_ scenario: ConversationScenario) {
        #if DEBUG
        print("[TopicPicker] applyStandardScenario → \(scenario.title)")
        #endif
        showTopicPicker = false

        generatedTopic = nil
        topicGenerationError = nil
        triedTopicTitles.removeAll()
        resetConversationForNewTopic()
        self.context = .scenario(scenario)
        seedOpeningMessage(.scenario(scenario))
    }

    func applyGeneratedTopic() {
        guard let topic = generatedTopic else {
            #if DEBUG
            print("[TopicPicker] applyGeneratedTopic — no preview, ignoring")
            #endif
            return
        }
        #if DEBUG
        print("[TopicPicker] applyGeneratedTopic → \(topic.title)")
        #endif
        showTopicPicker = false
        topicGenerationError = nil
        resetConversationForNewTopic()
        self.context = .generatedTopic(topic)
        seedOpeningMessage(.generatedTopic(topic))
    }

    func generateFreshTopic(forceRefresh: Bool) {

        topicGenerationTask?.cancel()

        let avoidTitles = forceRefresh ? triedTopicTitles : []
        #if DEBUG
        print("[TopicPicker] generateFreshTopic forceRefresh=\(forceRefresh) avoid=\(avoidTitles)")
        #endif

        isGeneratingTopic = true
        topicGenerationError = nil

        topicGenerationTask = runTopicGeneration(
            avoidTitles: avoidTitles,
            forceRefresh: forceRefresh,
            applyToConversation: false
        )
    }

    private func runTopicGeneration(
        avoidTitles: [String],
        forceRefresh: Bool,
        applyToConversation: Bool
    ) -> Task<Void, Never> {
        let language = setup.language
        let level = setup.level
        let length = setup.length
        let service = topicService

        return Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }

            let storedTitles = await Task.detached(priority: .utility) {
                SpeakingRecentTopicTitlesStore.shared.recentTitles(language: language, level: level)
            }.value

            let resolvedAvoidTitles = await MainActor.run { [weak self] in
                guard let self else { return avoidTitles }
                if !self.triedTopicTitlesLoaded {
                    self.triedTopicTitles = storedTitles
                    self.triedTopicTitlesLoaded = true
                }
                return avoidTitles.isEmpty ? self.triedTopicTitles : avoidTitles
            }

            let (topic, usedFallback) = await service.topic(
                for: language,
                level: level,
                length: length,
                avoidTitles: resolvedAvoidTitles,
                forceRefresh: forceRefresh
            )
            if Task.isCancelled { return }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.isGeneratingTopic = false
                self.usedFallbackTopic = usedFallback
                self.generatedTopic = topic
                self.rememberTopicTitle(topic.title, usedFallback: usedFallback)

                if applyToConversation {
                    self.context = .generatedTopic(topic)
                    self.state = .idle
                    self.seedOpeningMessage(.generatedTopic(topic))
                } else if usedFallback {
                    self.topicGenerationError = "Could not generate topic. Using fallback topic."
                } else {
                    self.topicGenerationError = nil
                }

                #if DEBUG
                print("[TopicPicker] final generated topic title='\(topic.title)' fallback=\(usedFallback) apply=\(applyToConversation)")
                #endif
            }
        }
    }

    private func rememberTopicTitle(_ title: String, usedFallback: Bool) {
        if !triedTopicTitles.contains(title) {
            triedTopicTitles.append(title)
        }
        guard !usedFallback else { return }

        let language = setup.language
        let level = setup.level
        let store = recentTitlesStore
        Task.detached(priority: .utility) {
            store.remember(title: title, language: language, level: level)
        }
    }

    private func resetConversationForNewTopic() {
        recognizer.cancel()
        synthesizer.stop()

        feedbackTask?.cancel()
        feedbackTask = nil
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil

        messages.removeAll()
        partialTranscript = ""
        clearHint()
        errorMessage = nil
        didUseFallbackReply = false
        usedFallbackTopic = false
        lastSubmittedTranscript = ""
        lastGeminiSendAt = nil
        state = .idle

        startTimer()
    }

    func startTimer() {
        timerTask?.cancel()
        remainingSeconds = setup.length.minutes * 60
        #if DEBUG
        print("[ConversationVM] timer start \(remainingSeconds)s")
        #endif

        timerTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    guard let self else { return }
                    if self.remainingSeconds > 0 {
                        self.remainingSeconds -= 1
                    }
                    if self.remainingSeconds == 0 {
                        self.handleTimerFinished()
                    }
                }
            }
        }
    }

    func stopTimer() {
        #if DEBUG
        print("[ConversationVM] timer stop at \(remainingSeconds)s")
        #endif
        timerTask?.cancel()
        timerTask = nil
    }

    private func handleTimerFinished() {
        guard timerTask != nil else { return }
        #if DEBUG
        print("[ConversationVM] timer finished")
        #endif
        stopTimer()
        recognizer.cancel()
        synthesizer.stop()
        state = .idle
        onTimerFinished?()
    }

    func toggleListening() async {
        if isGeneratingTopic { return }
        switch state {
        case .idle, .error:
            await startListening()
        case .listening:
            stopListeningAndSend()
        case .processing, .speaking:
            #if DEBUG
            print("[ConversationVM] mic tap ignored — state=\(state)")
            #endif
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
            #if DEBUG
            print("[ConversationVM] speech start")
            #endif

            clearHint()
            state = .listening
        }
    }

    func stopListeningAndSend() {
        guard recognizer.isListening else { return }
        #if DEBUG
        print("[ConversationVM] speech stop")
        #endif
        state = .processing
        Task {
            await recognizer.stop()
        }

    }

    private func handleFinalTranscript(_ text: String) {
        partialTranscript = ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            #if DEBUG
            print("[ConversationVM] empty transcript — back to idle")
            #endif
            state = .idle
            return
        }

        if trimmed == lastSubmittedTranscript {
            #if DEBUG
            print("[ConversationVM] duplicate transcript ignored: \(trimmed.prefix(40))")
            #endif
            state = .idle
            return
        }

        if let last = lastGeminiSendAt, Date().timeIntervalSince(last) < geminiCooldownSeconds {
            #if DEBUG
            print("[ConversationVM] cooldown active — skipping")
            #endif
            state = .idle
            return
        }

        lastSubmittedTranscript = trimmed
        lastGeminiSendAt = Date()
        sendUserMessage(trimmed)
    }

    func sendUserMessage(_ text: String) {
        #if DEBUG
        print("[ConversationVM] append user message: \(text.prefix(60))")
        #endif

        clearHint()
        let userMessage = SpeakingConversationMessage(role: .user, text: text)
        messages.append(userMessage)
        state = .processing

        Task.detached(priority: .utility) { [weak self] in
            await self?.requestAIReply(for: text)
        }
    }

    func requestAIReply(for text: String) async {
        let snapshot: (
            context: SpeakingConversationContext?,
            history: [SpeakingConversationMessage],
            language: GrammarLanguage,
            level: EssayDifficulty,
            service: SpeakingConversationService
        ) = await MainActor.run {
            (
                context: context,
                history: messages,
                language: setup.language,
                level: setup.level,
                service: conversationService
            )
        }

        guard let context = snapshot.context else {
            #if DEBUG
            print("[ConversationVM] requestAIReply called before context resolved — skipping")
            #endif
            await MainActor.run { state = .idle }
            return
        }

        #if DEBUG
        print("[ConversationVM] → Gemini request (history=\(snapshot.history.count))")
        #endif

        do {
            let reply = try await snapshot.service.requestReply(
                language: snapshot.language,
                level: snapshot.level,
                context: context,
                history: snapshot.history,
                userMessage: text
            )
            let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalReply = trimmed.isEmpty
                ? SpeakingConversationService.fallbackReply(for: snapshot.language)
                : trimmed

            await MainActor.run {
                didUseFallbackReply = trimmed.isEmpty
                appendAIMessage(finalReply)
                speakAIResponse(finalReply)
            }
        } catch {
            #if DEBUG
            print("[ConversationVM] Gemini failed: \(error.localizedDescription) — using fallback")
            #endif
            let fallback = SpeakingConversationService.fallbackReply(for: snapshot.language)
            await MainActor.run {
                didUseFallbackReply = true
                errorMessage = SpeakingConversationService.fallbackBannerText(for: snapshot.language)
                appendAIMessage(fallback)
                speakAIResponse(fallback)
            }
        }
    }

    private func appendAIMessage(_ text: String) {
        let message = SpeakingConversationMessage(role: .ai, text: text)
        messages.append(message)
    }

    func speakAIResponse(_ text: String) {
        state = .speaking
        synthesizer.speak(text, localeIdentifier: setup.speechLocaleIdentifier)
    }

    func requestHint() {

        if case .processing = state {
            #if DEBUG
            print("[ConversationVM] hint ignored — state=processing")
            #endif
            return
        }
        if case .listening = state {
            #if DEBUG
            print("[ConversationVM] hint ignored — state=listening")
            #endif
            return
        }
        guard !isRequestingHint else { return }

        guard let context else {
            presentHint(SpeakingConversationService.genericTopicHint(for: setup.language))
            return
        }

        isRequestingHint = true
        let language = setup.language
        let level = setup.level
        let history = messages
        let lastUserMessage = messages.last(where: { $0.role == .user })?.text
        let service = conversationService

        Task { [weak self] in
            let hintText = await Self.resolveHint(
                service: service,
                language: language,
                level: level,
                context: context,
                history: history,
                lastUserMessage: lastUserMessage
            )
            await MainActor.run {
                guard let self else { return }
                self.isRequestingHint = false
                self.presentHint(hintText)
            }
        }
    }

    private static func resolveHint(
        service: SpeakingConversationService,
        language: GrammarLanguage,
        level: EssayDifficulty,
        context: SpeakingConversationContext,
        history: [SpeakingConversationMessage],
        lastUserMessage: String?
    ) async -> String {
        do {
            let hint = try await service.requestHint(
                mode: .aiConversation,
                language: language,
                level: level,
                context: context,
                history: history,
                lastUserMessage: lastUserMessage
            )
            if !hint.isEmpty { return hint }
        } catch {
            #if DEBUG
            print("[ConversationVM] AI hint failed: \(error.localizedDescription) — using local hint")
            #endif
        }
        return SpeakingConversationService.localHint(for: language, context: context)
    }

    private func presentHint(_ hintText: String) {
        guard !state.isListening, !state.isBusy else {
            #if DEBUG
            print("[ConversationVM] hint dropped — state=\(state)")
            #endif
            return
        }
        #if DEBUG
        print("[ConversationVM] hint shown: \(hintText.prefix(60))")
        #endif
        currentHint = hintText
        scheduleHintAutoHide()
        speakAIResponse(hintText)
    }

    func clearHint() {
        hintAutoHideTask?.cancel()
        hintAutoHideTask = nil
        isRequestingHint = false
        if currentHint != nil { currentHint = nil }
    }

    private func scheduleHintAutoHide() {
        hintAutoHideTask?.cancel()
        hintAutoHideTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let seconds = await MainActor.run { self.hintAutoHideSeconds }
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                if self.currentHint != nil {
                    #if DEBUG
                    print("[ConversationVM] hint auto-hidden")
                    #endif
                    self.currentHint = nil
                }
            }
        }
    }

    private func beginFeedbackGeneration() {

        let snapshotLanguage = setup.language
        let snapshotLevel = setup.level
        let snapshotContext = context
        let snapshotMessages = messages
        let service = feedbackService

        #if DEBUG
        print("[ConversationVM] beginFeedbackGeneration userMessages=\(snapshotMessages.filter { $0.role == .user }.count)")
        #endif

        isGeneratingFeedback = true
        feedbackError = nil

        feedbackTask?.cancel()
        feedbackTask = Task.detached(priority: .utility) { [weak self] in
            let result = await service.generateFeedback(
                language: snapshotLanguage,
                level: snapshotLevel,
                context: snapshotContext,
                messages: snapshotMessages
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

extension AIConversationViewModel: SpeakingTopicPickable {}
extension AIConversationViewModel: SpeakingResultProvidable {}
