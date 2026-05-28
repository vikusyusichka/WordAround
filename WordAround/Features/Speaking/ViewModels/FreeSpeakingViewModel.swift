import Foundation
import SwiftUI
import Combine

@MainActor
final class FreeSpeakingViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var messages: [SpeakingConversationMessage] = []
    /// Plain-text mirror of finalized user transcript chunks (one per finalized utterance).
    /// Kept in sync with `messages` so Free Speaking can drive UI from a simple [String]
    /// while feedback continues to use the existing `messages` pipeline.
    @Published private(set) var transcriptChunks: [String] = []
    @Published private(set) var partialTranscript: String = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published var errorMessage: String?
    /// True when microphone or speech recognition permission was denied.
    @Published private(set) var permissionsDenied: Bool = false

    /// Mirrors `state == .listening` for the public Free Speaking API.
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

    // MARK: - Public Interface

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

    // MARK: - Private

    private let recognizer: SpeechRecognitionService
    private let topicService: SpeakingTopicGenerationService
    private let feedbackService: SpeakingFeedbackService
    private let recentTitlesStore = SpeakingRecentTopicTitlesStore.shared

    private var hasStarted = false
    private var permissionsRequested = false
    private var lastSubmittedTranscript: String = ""

    private var timerTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var topicGenerationTask: Task<Void, Never>?

    private var triedTopicTitles: [String] = []
    private var triedTopicTitlesLoaded = false

    // MARK: - Init

    init(
        setup: SpeakingConversationSetup,
        recognizer: SpeechRecognitionService? = nil,
        topicService: SpeakingTopicGenerationService? = nil,
        feedbackService: SpeakingFeedbackService? = nil
    ) {
        self.setup = setup
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.topicService = topicService ?? SpeakingTopicGenerationService()
        self.feedbackService = feedbackService ?? SpeakingFeedbackService()
        self.remainingSeconds = setup.length.minutes * 60
        wireRecognizerCallbacks()
    }

    deinit {
        timerTask?.cancel()
        feedbackTask?.cancel()
        topicGenerationTask?.cancel()
    }

    // MARK: - Session Lifecycle

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

        if conversationFeedback == nil && !isGeneratingFeedback {
            beginFeedbackGeneration()
        }
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
        errorMessage = nil
        permissionsDenied = false
        lastSubmittedTranscript = ""
        remainingSeconds = setup.length.minutes * 60
        context = nil
        usedFallbackTopic = false
    }

    // MARK: - Timer

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

    // MARK: - Speech Recognition

    private func wireRecognizerCallbacks() {
        recognizer.onPartialTranscript = { [weak self] text in
            #if DEBUG
            print("[FreeSpeakingVM] partial transcript update (len=\(text.count))")
            #endif
            self?.partialTranscript = text
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
        // Go idle immediately; final transcript arrives via callback
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

        // Deduplicate: ignore if same utterance repeated
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
        // Free Speaking: no AI reply. The session continues until End or timer.
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Topic Management

    /// Called at session start — generates and auto-applies the first topic.
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

    /// Called from topic picker — generates a preview topic (not auto-applied).
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

    // MARK: - Feedback

    private func beginFeedbackGeneration() {
        let snapshotLanguage = setup.language
        let snapshotLevel = setup.level
        let snapshotContext = context
        let snapshotMessages = messages
        let service = feedbackService

        #if DEBUG
        print("[FreeSpeakingVM] beginFeedbackGeneration userMessages=\(snapshotMessages.count)")
        #endif

        isGeneratingFeedback = true
        feedbackError = nil

        feedbackTask?.cancel()
        feedbackTask = Task.detached(priority: .utility) { [weak self] in
            let feedback = await service.generateFeedback(
                language: snapshotLanguage,
                level: snapshotLevel,
                context: snapshotContext,
                messages: snapshotMessages
            )
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self else { return }
                self.conversationFeedback = feedback
                self.isGeneratingFeedback = false
                self.feedbackError = feedback.isFallback
                    ? "AI feedback unavailable. Showing basic feedback."
                    : nil
            }
        }
    }
}

// MARK: - Protocol Conformances

extension FreeSpeakingViewModel: SpeakingTopicPickable {}
extension FreeSpeakingViewModel: SpeakingResultProvidable {}
