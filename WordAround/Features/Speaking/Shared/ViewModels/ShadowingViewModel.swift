import Foundation
import SwiftUI
import Combine

@MainActor
final class ShadowingViewModel: ObservableObject {

    @Published private(set) var phrases: [ShadowingPhrase] = []
    @Published private(set) var currentPhraseIndex = 0
    @Published private(set) var isLoadingPhrases = false
    @Published private(set) var phraseGenerationError: String?
    @Published private(set) var usedFallbackPhrases = false

    @Published private(set) var currentAssessment: PronunciationAssessmentResult?
    @Published private(set) var isAssessingPronunciation = false
    @Published private(set) var assessmentError: String?

    @Published private(set) var userTranscript = ""
    @Published private(set) var partialTranscript = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published private(set) var isSpeakingTarget = false
    @Published var errorMessage: String?
    @Published private(set) var permissionsDenied = false

    @Published private(set) var attempts: [ShadowingAttempt] = []
    @Published private(set) var currentAttemptResult: ShadowingAttempt?

    @Published private(set) var messages: [SpeakingConversationMessage] = []
    @Published private(set) var conversationFeedback: SpeakingConversationFeedback?
    @Published private(set) var isGeneratingFeedback = false
    @Published private(set) var feedbackError: String?

    var currentPhrase: ShadowingPhrase? {
        guard phrases.indices.contains(currentPhraseIndex) else { return nil }
        return phrases[currentPhraseIndex]
    }

    var isListening: Bool { state == .listening }
    var isPlayingPhrase: Bool { isSpeakingTarget }

    var isLastPhrase: Bool {
        !phrases.isEmpty && currentPhraseIndex >= phrases.count - 1
    }

    var sessionProgress: Double {
        guard !phrases.isEmpty else { return 0 }
        return min(1.0, Double(attempts.count) / Double(phrases.count))
    }

    var progressLabel: String {
        guard !phrases.isEmpty else { return "0/0" }
        return "\(min(currentPhraseIndex + 1, phrases.count))/\(phrases.count)"
    }

    var averageAccuracy: Int {
        guard !attempts.isEmpty else { return 0 }
        return attempts.reduce(0) { $0 + $1.accuracy } / attempts.count
    }

    var hasAttemptForCurrentPhrase: Bool { currentAttemptResult != nil }

    let setup: SpeakingConversationSetup
    let category: ShadowingCategory
    var onSessionEnded: (() -> Void)?

    var usesPreloadedPhrases: Bool {
        guard let preloadedPhrases else { return false }
        return !preloadedPhrases.isEmpty
    }

    private let preloadedPhrases: [ShadowingPhrase]?
    private let recognizer: SpeechRecognitionService
    private let synthesizer: SpeechSynthesisService
    private let phraseService: ShadowingPhraseProviding
    private let feedbackService: SpeakingFeedbackService
    private let pronunciationAssessor: PronunciationAssessing
    private let fallbackAssessor: PronunciationAssessing

    private var hasStarted = false
    private var hasEnded = false
    private var sessionStartedAt: Date?
    private var didRecordPracticeStats = false
    private let statsService: DailyPracticeStatsService
    private var permissionsRequested = false
    private var lastSubmittedTranscript = ""
    private var feedbackTask: Task<Void, Never>?
    private var assessmentTask: Task<Void, Never>?

    private let shadowingContext: SpeakingConversationContext = .generatedTopic(
        GeneratedConversationTopic(
            title: "Shadowing practice",
            description: "Repeat target phrases aloud as closely as possible.",
            firstAIMessage: "",
            promptContext: "The learner is shadowing: they listen to a target phrase and repeat it aloud. Evaluate only the learner's spoken repetitions (grammar, vocabulary, fluency, pronunciation as estimated from the transcript). There is no AI interlocutor.",
            category: "Shadowing"
        )
    )

    init(
        setup: SpeakingConversationSetup,
        category: ShadowingCategory,
        preloadedPhrases: [ShadowingPhrase]? = nil,
        recognizer: SpeechRecognitionService? = nil,
        synthesizer: SpeechSynthesisService? = nil,
        phraseService: ShadowingPhraseProviding? = nil,
        feedbackService: SpeakingFeedbackService? = nil,
        pronunciationAssessor: PronunciationAssessing? = nil,
        fallbackAssessor: PronunciationAssessing? = nil,
        statsService: DailyPracticeStatsService = .shared
    ) {
        self.setup = setup
        self.category = category
        self.preloadedPhrases = preloadedPhrases
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.synthesizer = synthesizer ?? SpeechSynthesisService()
        self.phraseService = phraseService ?? ShadowingPhraseService()
        self.feedbackService = feedbackService ?? SpeakingFeedbackService()
        self.pronunciationAssessor = pronunciationAssessor ?? PronunciationAssessmentConfiguration.makeAzureAssessor()
        self.fallbackAssessor = fallbackAssessor ?? PronunciationAssessmentConfiguration.makeFallbackAssessor()
        self.statsService = statsService
        wireRecognizerCallbacks()
        wireSynthesizerCallbacks()
    }

    deinit {
        feedbackTask?.cancel()
        assessmentTask?.cancel()
    }

    func startSession() {
        guard !hasStarted else { return }
        hasStarted = true
        hasEnded = false
        sessionStartedAt = Date()

        #if DEBUG
        print("[ShadowingVM] startSession lang=\(setup.language.title) level=\(setup.level.rawValue) category=\(category.rawValue)")
        #endif

        if let preloadedPhrases, !preloadedPhrases.isEmpty {
            applyPreloadedPhrases(preloadedPhrases)
        } else {
            loadFreshPhrases(forceRefresh: false)
        }
    }

    private func applyPreloadedPhrases(_ batch: [ShadowingPhrase]) {
        phrases = batch
        currentPhraseIndex = 0
        usedFallbackPhrases = false
        phraseGenerationError = nil
        isLoadingPhrases = false
    }

    func endSession() {
        guard !hasEnded else { return }
        hasEnded = true

        #if DEBUG
        print("[ShadowingVM] endSession attempts=\(attempts.count) avgAccuracy=\(averageAccuracy)")
        #endif

        synthesizer.stop()
        recognizer.cancel()
        isSpeakingTarget = false
        partialTranscript = ""
        state = .idle

        recordPracticeStatsIfNeeded()

        if conversationFeedback == nil && !isGeneratingFeedback {
            beginFeedbackGeneration()
        }
    }

    private func recordPracticeStatsIfNeeded() {
        guard hasStarted, !didRecordPracticeStats, let start = sessionStartedAt else { return }
        let practiced = Int(Date().timeIntervalSince(start))
        guard practiced > 0 else { return }
        didRecordPracticeStats = true
        statsService.record(
            skill: .speaking,
            value: practiced,
            sourceModeID: "shadowing"
        )
    }

    func resetSession() {
        synthesizer.stop()
        recognizer.cancel()
        feedbackTask?.cancel()
        feedbackTask = nil
        assessmentTask?.cancel()
        assessmentTask = nil

        phrases.removeAll()
        currentPhraseIndex = 0
        attempts.removeAll()
        currentAttemptResult = nil
        currentAssessment = nil
        isAssessingPronunciation = false
        assessmentError = nil
        phraseGenerationError = nil
        usedFallbackPhrases = false
        messages.removeAll()
        userTranscript = ""
        partialTranscript = ""
        lastSubmittedTranscript = ""
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil
        errorMessage = nil
        permissionsDenied = false
        isSpeakingTarget = false
        state = .idle
        hasStarted = false
        hasEnded = false
        sessionStartedAt = nil
        didRecordPracticeStats = false
    }

    func loadFreshPhrases(forceRefresh: Bool) {
        guard !usesPreloadedPhrases else { return }
        guard !isLoadingPhrases else { return }
        isLoadingPhrases = true
        errorMessage = nil
        phraseGenerationError = nil

        let language = setup.language
        let level = setup.level
        let category = category
        let service = phraseService
        let avoid = forceRefresh ? phrases.map(\.text) : []

        currentAssessment = nil
        assessmentError = nil
        currentAttemptResult = nil
        userTranscript = ""

        #if DEBUG
        print("[ShadowingVM] phrase generation request started forceRefresh=\(forceRefresh) lang=\(language.title) level=\(level.rawValue) category=\(category.title)")
        #endif

        Task { [weak self] in
            do {
                let batch = try await service.phrases(
                    for: language, level: level, category: category, count: 5, avoidPhrases: avoid
                )
                guard let self else { return }
                self.phrases = batch.phrases
                self.currentPhraseIndex = 0
                self.usedFallbackPhrases = batch.usedFallback
                self.phraseGenerationError = batch.fallbackReason
                self.isLoadingPhrases = false
                #if DEBUG
                print("[ShadowingVM] phrase generation response count=\(batch.phrases.count) usedFallback=\(batch.usedFallback)")
                #endif
            } catch {
                guard let self else { return }
                self.isLoadingPhrases = false
                self.phraseGenerationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                #if DEBUG
                print("[ShadowingVM] phrase generation failed: \(self.phraseGenerationError ?? "?")")
                #endif
            }
        }
    }

    func regeneratePhrases() {
        guard !usesPreloadedPhrases else { return }
        loadFreshPhrases(forceRefresh: true)
    }

    func playTargetPhrase() {
        guard let phrase = currentPhrase else { return }

        if recognizer.isListening {
            recognizer.cancel()
        }
        partialTranscript = ""

        #if DEBUG
        print("[ShadowingVM] phrase played — TTS spoken text='\(phrase.text.prefix(80))' locale=\(setup.speechLocaleIdentifier)")
        if let t = phrase.translation { print("[ShadowingVM] translation NOT spoken (display only): '\(t.prefix(80))'") }
        #endif

        isSpeakingTarget = true
        state = .speaking
        synthesizer.speak(phrase.text, localeIdentifier: setup.speechLocaleIdentifier)
    }

    func toggleListening() async {
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
        if isSpeakingTarget {
            synthesizer.stop()
            isSpeakingTarget = false
        }

        if !permissionsRequested {
            permissionsRequested = true
            let granted = await recognizer.requestPermissions()
            #if DEBUG
            print("[ShadowingVM] permission result granted=\(granted)")
            #endif
            guard granted else {
                permissionsDenied = true
                errorMessage = "Microphone and speech recognition access are required for Shadowing."
                state = .idle
                return
            }
            permissionsDenied = false
        }

        currentAttemptResult = nil
        userTranscript = ""
        lastSubmittedTranscript = ""

        await recognizer.start(localeIdentifier: setup.speechLocaleIdentifier)
        if recognizer.isListening {
            #if DEBUG
            print("[ShadowingVM] mic started locale=\(setup.speechLocaleIdentifier)")
            #endif
            state = .listening
        }
    }

    func stopListening() {
        guard recognizer.isListening else { return }
        #if DEBUG
        print("[ShadowingVM] mic stopping")
        #endif
        state = .processing
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
        print("[ShadowingVM] final transcript received: \(trimmed.prefix(60))")
        #endif

        userTranscript = trimmed
        if let phrase = currentPhrase {
            let attempt = compareAttempt(target: phrase, userTranscript: trimmed)
            recordAttempt(attempt)
            assessCurrentAttempt(referenceText: phrase.text, recognizedText: trimmed)
        }
        state = .idle
    }

    func assessCurrentAttempt(referenceText: String, recognizedText: String) {
        let languageCode = setup.speechLocaleIdentifier
        let realAssessor = pronunciationAssessor
        let fallback = fallbackAssessor

        assessmentTask?.cancel()
        isAssessingPronunciation = true
        assessmentError = nil
        currentAssessment = nil

        #if DEBUG
        print("[ShadowingVM] pronunciation assessment started ref='\(referenceText.prefix(40))' locale=\(languageCode)")
        #endif

        assessmentTask = Task { [weak self] in
            do {
                let result = try await realAssessor.assessPronunciation(
                    audioInput: .recognizedText(recognizedText),
                    referenceText: referenceText,
                    languageCode: languageCode
                )
                if Task.isCancelled { return }
                await MainActor.run {
                    guard let self else { return }
                    self.currentAssessment = result
                    self.isAssessingPronunciation = false
                    #if DEBUG
                    print("[ShadowingVM] assessment result (real) pron=\(result.pronunciationScore) acc=\(result.accuracyScore)")
                    #endif
                }
                return
            } catch {
                #if DEBUG
                print("[ShadowingVM] assessment fallback reason: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
                #endif
            }

            do {
                let estimate = try await fallback.assessPronunciation(
                    audioInput: .recognizedText(recognizedText),
                    referenceText: referenceText,
                    languageCode: languageCode
                )
                if Task.isCancelled { return }
                await MainActor.run {
                    guard let self else { return }
                    self.currentAssessment = estimate
                    self.isAssessingPronunciation = false
                    self.assessmentError = "Pronunciation assessment unavailable. Showing transcript-based estimate."
                    #if DEBUG
                    print("[ShadowingVM] assessment result (estimate) pron=\(estimate.pronunciationScore) completeness=\(estimate.completenessScore)")
                    #endif
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard let self else { return }
                    self.isAssessingPronunciation = false
                    self.assessmentError = "Could not assess this attempt."
                }
            }
        }
    }

    func compareAttempt(target: ShadowingPhrase, userTranscript: String) -> ShadowingAttempt {
        let attempt = ShadowingComparison.evaluate(phrase: target, userTranscript: userTranscript)
        #if DEBUG
        print("[ShadowingVM] comparison score=\(attempt.accuracy)% missing=\(attempt.missingWords) extra=\(attempt.extraWords)")
        #endif
        return attempt
    }

    private func recordAttempt(_ attempt: ShadowingAttempt) {
        currentAttemptResult = attempt
        attempts.removeAll { $0.phraseID == attempt.phraseID }
        attempts.append(attempt)
        messages.append(SpeakingConversationMessage(role: .user, text: attempt.userTranscript))
    }

    func retryCurrentPhrase() {
        #if DEBUG
        print("[ShadowingVM] retry phrase index=\(currentPhraseIndex)")
        #endif
        synthesizer.stop()
        recognizer.cancel()
        assessmentTask?.cancel()
        isSpeakingTarget = false
        currentAttemptResult = nil
        currentAssessment = nil
        isAssessingPronunciation = false
        assessmentError = nil
        userTranscript = ""
        partialTranscript = ""
        lastSubmittedTranscript = ""
        state = .idle
    }

    func goToNextPhrase() {
        guard !phrases.isEmpty else { return }

        if isLastPhrase {
            #if DEBUG
            print("[ShadowingVM] reached last phrase → ending session")
            #endif
            endSession()
            onSessionEnded?()
            return
        }

        synthesizer.stop()
        recognizer.cancel()
        assessmentTask?.cancel()
        isSpeakingTarget = false
        currentPhraseIndex += 1
        currentAttemptResult = nil
        currentAssessment = nil
        isAssessingPronunciation = false
        assessmentError = nil
        userTranscript = ""
        partialTranscript = ""
        lastSubmittedTranscript = ""
        state = .idle

        #if DEBUG
        print("[ShadowingVM] next phrase index=\(currentPhraseIndex)")
        #endif
    }

    func clearError() {
        errorMessage = nil
    }

    private func wireRecognizerCallbacks() {
        recognizer.onPartialTranscript = { [weak self] text in
            self?.partialTranscript = text
            #if DEBUG
            print("[ShadowingVM] partial transcript update (len=\(text.count))")
            #endif
        }

        recognizer.onFinalTranscript = { [weak self] text in
            self?.handleFinalTranscript(text)
        }

        recognizer.onError = { [weak self] error in
            guard let self else { return }
            self.partialTranscript = ""
            switch error {
            case .microphonePermissionDenied, .speechPermissionDenied:
                self.permissionsDenied = true
                self.errorMessage = "Microphone and speech recognition access are required for Shadowing."
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

    private func wireSynthesizerCallbacks() {
        synthesizer.onStart = { [weak self] in
            self?.isSpeakingTarget = true
            self?.state = .speaking
        }
        synthesizer.onFinish = { [weak self] in
            guard let self else { return }
            self.isSpeakingTarget = false
            if self.state == .speaking { self.state = .idle }
        }
    }

    private func beginFeedbackGeneration() {
        let snapshotLanguage = setup.language
        let snapshotLevel = setup.level
        let snapshotContext = shadowingContext
        let snapshotMessages = messages
        let service = feedbackService

        #if DEBUG
        print("[ShadowingVM] feedback generation start userMessages=\(snapshotMessages.count)")
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
}

extension ShadowingViewModel: SpeakingResultProvidable {}
