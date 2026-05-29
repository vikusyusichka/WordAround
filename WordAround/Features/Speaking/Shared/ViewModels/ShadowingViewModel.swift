import Foundation
import SwiftUI
import Combine

/// Orchestrates the Shadowing flow over the SHARED speaking services:
///
///   ShadowingViewModel
///     → ShadowingPhraseService      (target phrases)
///     → SpeechSynthesisService      (play target phrase)
///     → SpeechRecognitionService    (capture spoken repetition)
///     → SpeakingFeedbackService     (optional end-of-session feedback)
///
/// No duplicate speech / feedback / timer / worker systems are created.
@MainActor
final class ShadowingViewModel: ObservableObject {

    // MARK: - Published — Phrases

    @Published private(set) var phrases: [ShadowingPhrase] = []
    @Published private(set) var currentPhraseIndex = 0
    @Published private(set) var isLoadingPhrases = false
    @Published private(set) var phraseGenerationError: String?
    @Published private(set) var usedFallbackPhrases = false

    // MARK: - Published — Pronunciation Assessment

    @Published private(set) var currentAssessment: PronunciationAssessmentResult?
    @Published private(set) var isAssessingPronunciation = false
    @Published private(set) var assessmentError: String?

    // MARK: - Published — Speech / Transcript

    @Published private(set) var userTranscript = ""
    @Published private(set) var partialTranscript = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published private(set) var isSpeakingTarget = false
    @Published var errorMessage: String?
    @Published private(set) var permissionsDenied = false

    // MARK: - Published — Attempts

    @Published private(set) var attempts: [ShadowingAttempt] = []
    @Published private(set) var currentAttemptResult: ShadowingAttempt?

    // MARK: - Published — Feedback (shared result screen)

    @Published private(set) var messages: [SpeakingConversationMessage] = []
    @Published private(set) var conversationFeedback: SpeakingConversationFeedback?
    @Published private(set) var isGeneratingFeedback = false
    @Published private(set) var feedbackError: String?

    // MARK: - Derived

    var currentPhrase: ShadowingPhrase? {
        guard phrases.indices.contains(currentPhraseIndex) else { return nil }
        return phrases[currentPhraseIndex]
    }

    var isListening: Bool { state == .listening }
    var isPlayingPhrase: Bool { isSpeakingTarget }

    var isLastPhrase: Bool {
        !phrases.isEmpty && currentPhraseIndex >= phrases.count - 1
    }

    /// Progress as the fraction of phrases that have a recorded attempt.
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

    // MARK: - Public Interface

    let setup: SpeakingConversationSetup
    let category: ShadowingCategory
    var onSessionEnded: (() -> Void)?

    // MARK: - Private

    private let recognizer: SpeechRecognitionService
    private let synthesizer: SpeechSynthesisService
    private let phraseService: ShadowingPhraseProviding
    private let feedbackService: SpeakingFeedbackService
    private let pronunciationAssessor: PronunciationAssessing
    private let fallbackAssessor: PronunciationAssessing

    private var hasStarted = false
    private var hasEnded = false
    private var permissionsRequested = false
    private var lastSubmittedTranscript = ""
    private var feedbackTask: Task<Void, Never>?
    private var assessmentTask: Task<Void, Never>?

    /// Shadowing task context fed to the shared feedback service.
    private let shadowingContext: SpeakingConversationContext = .generatedTopic(
        GeneratedConversationTopic(
            title: "Shadowing practice",
            description: "Repeat target phrases aloud as closely as possible.",
            firstAIMessage: "",
            promptContext: "The learner is shadowing: they listen to a target phrase and repeat it aloud. Evaluate only the learner's spoken repetitions (grammar, vocabulary, fluency, pronunciation as estimated from the transcript). There is no AI interlocutor.",
            category: "Shadowing"
        )
    )

    // MARK: - Init

    init(
        setup: SpeakingConversationSetup,
        category: ShadowingCategory,
        recognizer: SpeechRecognitionService? = nil,
        synthesizer: SpeechSynthesisService? = nil,
        phraseService: ShadowingPhraseProviding? = nil,
        feedbackService: SpeakingFeedbackService? = nil,
        pronunciationAssessor: PronunciationAssessing? = nil,
        fallbackAssessor: PronunciationAssessing? = nil
    ) {
        self.setup = setup
        self.category = category
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.synthesizer = synthesizer ?? SpeechSynthesisService()
        self.phraseService = phraseService ?? ShadowingPhraseService()
        self.feedbackService = feedbackService ?? SpeakingFeedbackService()
        self.pronunciationAssessor = pronunciationAssessor ?? PronunciationAssessmentConfiguration.makeAzureAssessor()
        self.fallbackAssessor = fallbackAssessor ?? PronunciationAssessmentConfiguration.makeFallbackAssessor()
        wireRecognizerCallbacks()
        wireSynthesizerCallbacks()
    }

    deinit {
        feedbackTask?.cancel()
        assessmentTask?.cancel()
    }

    // MARK: - Session Lifecycle

    func startSession() {
        guard !hasStarted else { return }
        hasStarted = true
        hasEnded = false

        #if DEBUG
        print("[ShadowingVM] startSession lang=\(setup.language.title) level=\(setup.level.rawValue) category=\(category.rawValue)")
        #endif

        loadFreshPhrases(forceRefresh: false)
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

        if conversationFeedback == nil && !isGeneratingFeedback {
            beginFeedbackGeneration()
        }
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
    }

    // MARK: - Phrase Loading

    /// Generates a fresh set of 5 AI phrases for the current language/level/
    /// category. Falls back to randomized local phrases if AI is unavailable.
    /// `forceRefresh` is used by the "Regenerate" action and avoids the
    /// currently shown phrases in addition to the persisted recent set.
    func loadFreshPhrases(forceRefresh: Bool) {
        guard !isLoadingPhrases else { return }
        isLoadingPhrases = true
        errorMessage = nil
        phraseGenerationError = nil

        let language = setup.language
        let level = setup.level
        let category = category
        let service = phraseService
        let avoid = forceRefresh ? phrases.map(\.text) : []

        // Clear current attempt/assessment when regenerating.
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

    /// Regenerate button — always produces a different set.
    func regeneratePhrases() {
        loadFreshPhrases(forceRefresh: true)
    }

    // MARK: - Playback

    func playTargetPhrase() {
        guard let phrase = currentPhrase else { return }

        // Never listen and speak at the same time.
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
        // Speak ONLY the target-language phrase. The translation is for display.
        synthesizer.speak(phrase.text, localeIdentifier: setup.speechLocaleIdentifier)
    }

    // MARK: - Speech Recognition

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
        // Stop any target playback first.
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

        // Fresh attempt for this take.
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

    // MARK: - Pronunciation Assessment

    /// Runs the real pronunciation assessor first; on failure (e.g. Azure SDK
    /// not yet wired) falls back to the transcript-similarity estimate and
    /// records an honest message. Currently no audio file is captured, so the
    /// fallback path is expected until the Azure SDK + WAV capture are added.
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
            // 1) Try the real (Azure) assessor. We only have recognized text
            //    today, so this throws .notImplemented and we fall back.
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

            // 2) Honest transcript-similarity fallback.
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

    // MARK: - Comparison

    /// Local transcript comparison only. NOT true pronunciation analysis.
    func compareAttempt(target: ShadowingPhrase, userTranscript: String) -> ShadowingAttempt {
        let attempt = ShadowingComparison.evaluate(phrase: target, userTranscript: userTranscript)
        #if DEBUG
        print("[ShadowingVM] comparison score=\(attempt.accuracy)% missing=\(attempt.missingWords) extra=\(attempt.extraWords)")
        #endif
        return attempt
    }

    private func recordAttempt(_ attempt: ShadowingAttempt) {
        currentAttemptResult = attempt
        // Replace any previous attempt for this phrase (retry overwrites).
        attempts.removeAll { $0.phraseID == attempt.phraseID }
        attempts.append(attempt)
        // Feed the shared feedback pipeline with what the learner actually said.
        messages.append(SpeakingConversationMessage(role: .user, text: attempt.userTranscript))
    }

    // MARK: - Navigation

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

    // MARK: - Callbacks

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

    // MARK: - Feedback

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

// MARK: - Protocol Conformances

extension ShadowingViewModel: SpeakingResultProvidable {}
