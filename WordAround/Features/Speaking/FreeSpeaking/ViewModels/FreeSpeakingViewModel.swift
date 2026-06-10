import Foundation
import SwiftUI
import Combine

@MainActor
final class FreeSpeakingViewModel: ObservableObject {

    @Published private(set) var messages: [SpeakingConversationMessage] = []
    @Published private(set) var transcriptChunks: [String] = []
    @Published private(set) var partialTranscript: String = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published var errorMessage: String?
    @Published private(set) var permissionsDenied: Bool = false

    var isListening: Bool { state == .listening }

    @Published private(set) var context: SpeakingConversationContext?

    @Published private(set) var isGeneratingTopic = false
    @Published private(set) var generatedTopic: GeneratedConversationTopic?
    @Published private(set) var topicGenerationError: String?
    @Published private(set) var usedFallbackTopic = false
    @Published var showTopicPicker: Bool = false

    @Published private(set) var conversationFeedback: SpeakingConversationFeedback?
    @Published private(set) var isGeneratingFeedback: Bool = false
    @Published private(set) var feedbackError: String?

    @Published private(set) var remainingSeconds: Int = 0

    let setup: SpeakingConversationSetup

    var onTimerFinished: (() -> Void)?

    var formattedRemainingTime: String {
        let s = max(0, remainingSeconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    var isTimeRunningOut: Bool { remainingSeconds > 0 && remainingSeconds < 60 }

    var selectedScenario: ConversationScenario? {
        if case .scenario(let s) = context { return s }
        return nil
    }

    private let recognizer: SpeechRecognitionService
    private let topicService: SpeakingTopicGenerationService
    private let feedbackService: SpeakingFeedbackService
    private let recentTitlesStore = SpeakingRecentTopicTitlesStore.shared

    private var hasStarted = false
    private var didRecordPracticeStats = false
    private let statsService: DailyPracticeStatsService
    private var permissionsRequested = false
    private var lastSubmittedTranscript: String = ""

    private var timerTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var topicGenerationTask: Task<Void, Never>?

    private var triedTopicTitles: [String] = []
    private var triedTopicTitlesLoaded = false

    init(
        setup: SpeakingConversationSetup,
        recognizer: SpeechRecognitionService? = nil,
        topicService: SpeakingTopicGenerationService? = nil,
        feedbackService: SpeakingFeedbackService? = nil,
        statsService: DailyPracticeStatsService = .shared
    ) {
        self.setup = setup
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.topicService = topicService ?? SpeakingTopicGenerationService()
        self.feedbackService = feedbackService ?? SpeakingFeedbackService()
        self.statsService = statsService
        self.remainingSeconds = setup.length.minutes * 60
        wireRecognizerCallbacks()
    }

    deinit {
        timerTask?.cancel()
        feedbackTask?.cancel()
        topicGenerationTask?.cancel()
    }

    func startSession() {
        guard !hasStarted else { return }
        hasStarted = true

        #if DEBUG
        print("[FreeSpeakingVM] startSession lang=\(setup.language.title) level=\(setup.level.rawValue) length=\(setup.length.title)")
        #endif

        startTimer()
        startAutoTopicGeneration()
    }

    func endSession() {
        recognizer.cancel()
        stopTimer()
        partialTranscript = ""
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
            sourceModeID: "free-speaking"
        )
    }

    func resetSession() {
        endSession()
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
        transcriptChunks.removeAll()
        hasStarted = false
        didRecordPracticeStats = false
        errorMessage = nil
        permissionsDenied = false
        lastSubmittedTranscript = ""
        remainingSeconds = setup.length.minutes * 60
        context = nil
        usedFallbackTopic = false
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
        state = .idle
        onTimerFinished?()
    }

    private func wireRecognizerCallbacks() {
        recognizer.onPartialTranscript = { [weak self] text in
            guard let self else { return }
            guard self.state.isListening else { return }
            #if DEBUG
            print("[FreeSpeakingVM] partial transcript update (len=\(text.count))")
            #endif
            self.partialTranscript = text
        }

        recognizer.onFinalTranscript = { [weak self] text in
            guard let self else { return }
            #if DEBUG
            print("[FreeSpeakingVM] final transcript received (len=\(text.count))")
            #endif
            self.handleFinalTranscript(text)
        }

        recognizer.onError = { [weak self] error in
            guard let self else { return }
            #if DEBUG
            print("[FreeSpeakingVM] recognition error: \(error.localizedDescription)")
            #endif
            self.partialTranscript = ""
            switch error {
            case .microphonePermissionDenied, .speechPermissionDenied:
                self.permissionsDenied = true
                self.errorMessage = "Microphone and speech recognition access are required for Free Speaking."
            case .recognizerUnavailable:
                self.errorMessage = error.localizedDescription
            default:
                self.errorMessage = error.localizedDescription
            }
            self.state = .error(error.localizedDescription)
            Task.detached(priority: .utility) { [weak self] in
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run { self?.state = .idle }
            }
        }
    }

    func toggleListening() async {
        #if DEBUG
        print("[FreeSpeakingVM] toggleListening (state=\(state))")
        #endif
        if isGeneratingTopic { return }
        switch state {
        case .idle, .error:
            await startListening()
        case .listening:
            stopListening()
        case .processing, .speaking:
            break
        }
    }

    func startListening() async {
        #if DEBUG
        print("[FreeSpeakingVM] mic tapped → startListening (permissionsRequested=\(permissionsRequested))")
        #endif

        if !permissionsRequested {
            permissionsRequested = true
            let granted = await recognizer.requestPermissions()
            #if DEBUG
            print("[FreeSpeakingVM] permission result granted=\(granted)")
            #endif
            guard granted else {
                permissionsDenied = true
                errorMessage = "Microphone and speech recognition access are required for Free Speaking."
                state = .idle
                return
            }
            permissionsDenied = false
        }

        await recognizer.start(localeIdentifier: setup.speechLocaleIdentifier)
        if recognizer.isListening {
            #if DEBUG
            print("[FreeSpeakingVM] recognition started locale=\(setup.speechLocaleIdentifier)")
            #endif
            state = .listening
        } else {
            #if DEBUG
            print("[FreeSpeakingVM] recognition NOT started (recognizer.isListening=false)")
            #endif
        }
    }

    func stopListening() {
        guard recognizer.isListening else { return }
        #if DEBUG
        print("[FreeSpeakingVM] mic tapped → stopListening")
        #endif
        state = .idle
        Task { await recognizer.stop() }
    }

    func handleFinalTranscript(_ text: String) {
        partialTranscript = ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        if trimmed == lastSubmittedTranscript {
            state = .idle
            return
        }

        lastSubmittedTranscript = trimmed

        #if DEBUG
        print("[FreeSpeakingVM] transcript chunk appended: \(trimmed.prefix(60))")
        #endif

        messages.append(SpeakingConversationMessage(role: .user, text: trimmed))
        transcriptChunks.append(trimmed)
        state = .idle
    }

    func clearError() {
        errorMessage = nil
    }

    private func startAutoTopicGeneration() {
        topicGenerationTask?.cancel()
        isGeneratingTopic = true
        topicGenerationError = nil

        topicGenerationTask = runTopicGeneration(
            avoidTitles: [],
            forceRefresh: true,
            applyToContext: true
        )
    }

    func generateFreshTopic(forceRefresh: Bool) {
        topicGenerationTask?.cancel()
        let avoidTitles = forceRefresh ? triedTopicTitles : []

        #if DEBUG
        print("[FreeSpeakingVM] generateFreshTopic forceRefresh=\(forceRefresh) avoid=\(avoidTitles)")
        #endif

        isGeneratingTopic = true
        topicGenerationError = nil

        topicGenerationTask = runTopicGeneration(
            avoidTitles: avoidTitles,
            forceRefresh: forceRefresh,
            applyToContext: false
        )
    }

    private func runTopicGeneration(
        avoidTitles: [String],
        forceRefresh: Bool,
        applyToContext: Bool
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

                if applyToContext {
                    self.context = .generatedTopic(topic)
                    self.topicGenerationError = usedFallback
                        ? "Could not generate topic. Using fallback topic."
                        : nil
                } else {
                    self.topicGenerationError = usedFallback
                        ? "Could not generate topic. Using fallback topic."
                        : nil
                }

                #if DEBUG
                print("[FreeSpeakingVM] topic='\(topic.title)' fallback=\(usedFallback) applyToContext=\(applyToContext)")
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

    func applyGeneratedTopic() {
        guard let topic = generatedTopic else { return }

        #if DEBUG
        print("[FreeSpeakingVM] applyGeneratedTopic → \(topic.title)")
        #endif

        showTopicPicker = false
        topicGenerationError = nil
        context = .generatedTopic(topic)
        resetSpeechForNewTopic()
    }

    func applyStandardScenario(_ scenario: ConversationScenario) {
        #if DEBUG
        print("[FreeSpeakingVM] applyStandardScenario → \(scenario.title)")
        #endif

        showTopicPicker = false
        generatedTopic = nil
        topicGenerationError = nil
        triedTopicTitles.removeAll()
        context = .scenario(scenario)
        resetSpeechForNewTopic()
    }

    private func resetSpeechForNewTopic() {
        recognizer.cancel()
        feedbackTask?.cancel()
        feedbackTask = nil
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil
        messages.removeAll()
        transcriptChunks.removeAll()
        partialTranscript = ""
        errorMessage = nil
        lastSubmittedTranscript = ""
        state = .idle
        startTimer()
    }

    private func beginFeedbackGeneration() {
        let snapshotLanguage = setup.language
        let snapshotLevel = setup.level
        let snapshotContext = context
        let snapshotMessages = messages
        let snapshotChunks = transcriptChunks
        let service = feedbackService

        let totalChars = snapshotChunks.reduce(0) { $0 + $1.count }

        #if DEBUG
        print("[FreeSpeakingVM] beginFeedbackGeneration userMessages=\(snapshotMessages.count) transcriptChunks=\(snapshotChunks.count) transcriptChars=\(totalChars)")
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
                #if DEBUG
                if let reason = result.fallbackReason {
                    print("[FreeSpeakingVM] feedback fallback reason='\(reason)'")
                } else {
                    print("[FreeSpeakingVM] feedback AI succeeded overall=\(result.feedback.overallScore)")
                }
                #endif
            }
        }
    }
}

extension FreeSpeakingViewModel: SpeakingTopicPickable {}
extension FreeSpeakingViewModel: SpeakingResultProvidable {}
