import Foundation
import SwiftUI
import Combine

@MainActor
final class PronunciationTrainerViewModel: ObservableObject {


    @Published private(set) var items: [PronunciationItem] = []
    @Published private(set) var currentItemIndex = 0
    @Published private(set) var isLoadingItems = false
    @Published private(set) var itemGenerationError: String?
    @Published private(set) var usedFallbackItems = false


    @Published private(set) var userTranscript = ""
    @Published private(set) var partialTranscript = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published private(set) var isPlayingItem = false
    @Published var errorMessage: String?
    @Published private(set) var permissionsDenied = false


    @Published private(set) var currentAssessment: PronunciationAssessmentResult?
    @Published private(set) var isAssessingPronunciation = false
    @Published private(set) var assessmentError: String?
    @Published private(set) var attempts: [PronunciationAttempt] = []


    @Published private(set) var messages: [SpeakingConversationMessage] = []
    @Published private(set) var conversationFeedback: SpeakingConversationFeedback?
    @Published private(set) var isGeneratingFeedback = false
    @Published private(set) var feedbackError: String?


    var currentItem: PronunciationItem? {
        guard items.indices.contains(currentItemIndex) else { return nil }
        return items[currentItemIndex]
    }

    var isListening: Bool { state == .listening }

    var isLastItem: Bool {
        !items.isEmpty && currentItemIndex >= items.count - 1
    }

    var sessionProgress: Double {
        guard !items.isEmpty else { return 0 }
        return min(1.0, Double(attempts.count) / Double(items.count))
    }

    var progressLabel: String {
        guard !items.isEmpty else { return "0 / 0" }
        return "\(min(currentItemIndex + 1, items.count)) / \(items.count)"
    }

    var averageScore: Int {
        guard !attempts.isEmpty else { return 0 }
        return attempts.reduce(0) { $0 + $1.score } / attempts.count
    }

    var hasAttemptForCurrentItem: Bool { currentAssessment != nil }


    let setup: SpeakingConversationSetup
    let difficulty: PronunciationDifficulty
    let focus: PronunciationFocus
    var onSessionEnded: (() -> Void)?


    private let recognizer: SpeechRecognitionService
    private let synthesizer: SpeechSynthesisService
    private let contentService: PronunciationContentProviding
    private let feedbackService: SpeakingFeedbackService
    private let pronunciationAssessor: PronunciationAssessing
    private let fallbackAssessor: PronunciationAssessing

    private var hasStarted = false
    private var hasEnded = false
    private var permissionsRequested = false
    private var lastSubmittedTranscript = ""
    private var isPlayingExample = false
    private var feedbackTask: Task<Void, Never>?
    private var assessmentTask: Task<Void, Never>?

    private let trainerContext: SpeakingConversationContext = .generatedTopic(
        GeneratedConversationTopic(
            title: "Pronunciation training",
            description: "Practise difficult sounds, words and minimal pairs.",
            firstAIMessage: "",
            promptContext: "The learner is doing focused pronunciation training: they repeat individual words, minimal pairs and short sound-focused phrases. Evaluate only the learner's spoken repetitions (pronunciation as estimated from the transcript, plus vocabulary). There is no AI interlocutor.",
            category: "Pronunciation"
        )
    )


    init(
        setup: SpeakingConversationSetup,
        difficulty: PronunciationDifficulty,
        focus: PronunciationFocus,
        recognizer: SpeechRecognitionService? = nil,
        synthesizer: SpeechSynthesisService? = nil,
        contentService: PronunciationContentProviding? = nil,
        feedbackService: SpeakingFeedbackService? = nil,
        pronunciationAssessor: PronunciationAssessing? = nil,
        fallbackAssessor: PronunciationAssessing? = nil
    ) {
        self.setup = setup
        self.difficulty = difficulty
        self.focus = focus
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.synthesizer = synthesizer ?? SpeechSynthesisService()
        self.contentService = contentService ?? PronunciationContentService()
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


    func startSession() {
        guard !hasStarted else { return }
        hasStarted = true
        hasEnded = false

        #if DEBUG
        print("[PronunciationVM] startSession lang=\(setup.language.title) level=\(setup.level.rawValue) difficulty=\(difficulty.rawValue) focus=\(focus.promptValue)")
        #endif

        loadFreshItems(forceRefresh: false)
    }

    func endSession() {
        guard !hasEnded else { return }
        hasEnded = true

        #if DEBUG
        print("[PronunciationVM] endSession attempts=\(attempts.count) avgScore=\(averageScore)")
        #endif

        synthesizer.stop()
        recognizer.cancel()
        isPlayingItem = false
        partialTranscript = ""
        state = .idle

        if conversationFeedback == nil && !isGeneratingFeedback {
            beginFeedbackGeneration()
        }
    }

    func resetSession() {
        synthesizer.stop()
        recognizer.cancel()
        feedbackTask?.cancel(); feedbackTask = nil
        assessmentTask?.cancel(); assessmentTask = nil

        items.removeAll()
        currentItemIndex = 0
        attempts.removeAll()
        currentAssessment = nil
        isAssessingPronunciation = false
        assessmentError = nil
        itemGenerationError = nil
        usedFallbackItems = false
        messages.removeAll()
        userTranscript = ""
        partialTranscript = ""
        lastSubmittedTranscript = ""
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil
        errorMessage = nil
        permissionsDenied = false
        isPlayingItem = false
        state = .idle
        hasStarted = false
        hasEnded = false
    }


    func loadFreshItems(forceRefresh: Bool) {
        guard !isLoadingItems else { return }
        isLoadingItems = true
        errorMessage = nil
        itemGenerationError = nil

        let language = setup.language
        let level = setup.level
        let difficulty = difficulty
        let focus = focus
        let service = contentService
        let avoid = forceRefresh ? items.map(\.text) : []

        currentAssessment = nil
        assessmentError = nil
        userTranscript = ""

        #if DEBUG
        print("[PronunciationVM] content generation request started forceRefresh=\(forceRefresh) lang=\(language.title) level=\(level.rawValue) difficulty=\(difficulty.rawValue) focus=\(focus.promptValue)")
        #endif

        Task { [weak self] in
            do {
                let batch = try await service.items(
                    for: language, level: level, difficulty: difficulty,
                    focus: focus, count: 10, avoidItems: avoid
                )
                guard let self else { return }
                self.items = batch.items
                self.currentItemIndex = 0
                self.usedFallbackItems = batch.usedFallback
                self.itemGenerationError = batch.fallbackReason
                self.isLoadingItems = false
                #if DEBUG
                print("[PronunciationVM] content generation response count=\(batch.items.count) usedFallback=\(batch.usedFallback)")
                #endif
            } catch {
                guard let self else { return }
                self.isLoadingItems = false
                self.itemGenerationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                #if DEBUG
                print("[PronunciationVM] content generation failed: \(self.itemGenerationError ?? "?")")
                #endif
            }
        }
    }

    func regenerateItems() {
        loadFreshItems(forceRefresh: true)
    }


    func playCurrentItem() {
        guard let item = currentItem else { return }
        speak(item.text, label: "item")

        #if DEBUG
        print("[PronunciationVM] item played — TTS spoken text='\(item.text)' locale=\(setup.speechLocaleIdentifier)")
        if let t = item.translation { print("[PronunciationVM] translation NOT spoken (display only): '\(t)'") }
        if let e = item.example { print("[PronunciationVM] example NOT spoken unless 'Play example' tapped: '\(e.prefix(40))'") }
        #endif
    }

    func playExample() {
        guard let example = currentItem?.example, !example.isEmpty else { return }
        isPlayingExample = true
        #if DEBUG
        print("[PronunciationVM] play example (explicit) text='\(example.prefix(60))'")
        #endif
        speak(example, label: "example")
    }

    private func speak(_ text: String, label: String) {
        if recognizer.isListening { recognizer.cancel() }
        partialTranscript = ""
        isPlayingItem = true
        state = .speaking
        synthesizer.speak(text, localeIdentifier: setup.speechLocaleIdentifier)
    }


    func toggleListening() async {
        switch state {
        case .idle, .error: await startListening()
        case .listening:    stopListening()
        case .processing, .speaking: break
        }
    }

    func startListening() async {
        if isPlayingItem {
            synthesizer.stop()
            isPlayingItem = false
        }

        if !permissionsRequested {
            permissionsRequested = true
            let granted = await recognizer.requestPermissions()
            #if DEBUG
            print("[PronunciationVM] permission result granted=\(granted)")
            #endif
            guard granted else {
                permissionsDenied = true
                errorMessage = "Microphone and speech recognition access are required for Pronunciation Trainer."
                state = .idle
                return
            }
            permissionsDenied = false
        }

        currentAssessment = nil
        assessmentError = nil
        userTranscript = ""
        lastSubmittedTranscript = ""

        await recognizer.start(localeIdentifier: setup.speechLocaleIdentifier)
        if recognizer.isListening {
            #if DEBUG
            print("[PronunciationVM] recording started locale=\(setup.speechLocaleIdentifier)")
            #endif
            state = .listening
        }
    }

    func stopListening() {
        guard recognizer.isListening else { return }
        #if DEBUG
        print("[PronunciationVM] recording stopping")
        #endif
        state = .processing
        Task { await recognizer.stop() }
    }

    func handleFinalTranscript(_ text: String) {
        partialTranscript = ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { state = .idle; return }
        if trimmed == lastSubmittedTranscript { state = .idle; return }
        lastSubmittedTranscript = trimmed

        #if DEBUG
        print("[PronunciationVM] final transcript received: '\(trimmed.prefix(60))'")
        #endif

        userTranscript = trimmed
        state = .idle
        if let item = currentItem {
            assessCurrentAttempt(referenceText: item.text, recognizedText: trimmed)
        }
    }


    func assessCurrentAttempt(referenceText: String, recognizedText: String) {
        let languageCode = setup.speechLocaleIdentifier
        let realAssessor = pronunciationAssessor
        let fallback = fallbackAssessor
        let itemId = currentItem?.id ?? UUID()

        assessmentTask?.cancel()
        isAssessingPronunciation = true
        assessmentError = nil
        currentAssessment = nil

        #if DEBUG
        print("[PronunciationVM] pronunciation assessment started ref='\(referenceText)' locale=\(languageCode)")
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
                    self?.applyAssessment(result, itemId: itemId, referenceText: referenceText, recognizedText: recognizedText, fallbackMessage: nil)
                    #if DEBUG
                    print("[PronunciationVM] assessment result (real) pron=\(result.pronunciationScore) acc=\(result.accuracyScore)")
                    #endif
                }
                return
            } catch {
                #if DEBUG
                print("[PronunciationVM] assessment fallback reason: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
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
                    self?.applyAssessment(
                        estimate, itemId: itemId, referenceText: referenceText, recognizedText: recognizedText,
                        fallbackMessage: "Pronunciation assessment unavailable. Showing transcript-based estimate."
                    )
                    #if DEBUG
                    print("[PronunciationVM] assessment result (estimate) pron=\(estimate.pronunciationScore) completeness=\(estimate.completenessScore)")
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

    private func applyAssessment(
        _ result: PronunciationAssessmentResult,
        itemId: UUID,
        referenceText: String,
        recognizedText: String,
        fallbackMessage: String?
    ) {
        currentAssessment = result
        isAssessingPronunciation = false
        assessmentError = fallbackMessage

        let attempt = PronunciationAttempt(
            itemId: itemId,
            targetText: referenceText,
            recognizedText: recognizedText,
            assessment: result
        )
        attempts.removeAll { $0.itemId == itemId }
        attempts.append(attempt)
        messages.append(SpeakingConversationMessage(role: .user, text: recognizedText))
    }


    func retryCurrentItem() {
        #if DEBUG
        print("[PronunciationVM] retry item index=\(currentItemIndex)")
        #endif
        synthesizer.stop()
        recognizer.cancel()
        assessmentTask?.cancel()
        isPlayingItem = false
        currentAssessment = nil
        isAssessingPronunciation = false
        assessmentError = nil
        userTranscript = ""
        partialTranscript = ""
        lastSubmittedTranscript = ""
        state = .idle
    }

    func goToNextItem() {
        guard !items.isEmpty else { return }

        if isLastItem {
            #if DEBUG
            print("[PronunciationVM] reached last item → ending session")
            #endif
            endSession()
            onSessionEnded?()
            return
        }

        synthesizer.stop()
        recognizer.cancel()
        assessmentTask?.cancel()
        isPlayingItem = false
        currentItemIndex += 1
        currentAssessment = nil
        isAssessingPronunciation = false
        assessmentError = nil
        userTranscript = ""
        partialTranscript = ""
        lastSubmittedTranscript = ""
        state = .idle

        #if DEBUG
        print("[PronunciationVM] next item index=\(currentItemIndex)")
        #endif
    }

    func clearError() { errorMessage = nil }


    private func wireRecognizerCallbacks() {
        recognizer.onPartialTranscript = { [weak self] text in
            self?.partialTranscript = text
            #if DEBUG
            print("[PronunciationVM] partial transcript update (len=\(text.count))")
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
                self.errorMessage = "Microphone and speech recognition access are required for Pronunciation Trainer."
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
            self?.isPlayingItem = true
            self?.state = .speaking
        }
        synthesizer.onFinish = { [weak self] in
            guard let self else { return }
            self.isPlayingItem = false
            self.isPlayingExample = false
            if self.state == .speaking { self.state = .idle }
        }
    }


    private func beginFeedbackGeneration() {
        let snapshotLanguage = setup.language
        let snapshotLevel = setup.level
        let snapshotContext = trainerContext
        let snapshotMessages = messages
        let service = feedbackService

        #if DEBUG
        print("[PronunciationVM] feedback generation start userMessages=\(snapshotMessages.count)")
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


extension PronunciationTrainerViewModel: SpeakingResultProvidable {}
