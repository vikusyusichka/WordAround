import Foundation
import SwiftUI
import Combine

@MainActor
final class DescribePictureViewModel: ObservableObject {

    @Published private(set) var currentImage: DescribePictureImage?
    @Published private(set) var isLoadingImage = false
    @Published private(set) var imageError: String?

    @Published private(set) var transcriptChunks: [String] = []
    @Published private(set) var partialTranscript: String = ""
    @Published private(set) var state: SpeakingConversationState = .idle
    @Published var errorMessage: String?
    @Published private(set) var permissionsDenied = false

    @Published private(set) var messages: [SpeakingConversationMessage] = []

    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var conversationFeedback: SpeakingConversationFeedback?
    @Published private(set) var isGeneratingFeedback = false
    @Published private(set) var feedbackError: String?

    var isListening: Bool { state == .listening }
    var isGeneratingFeedbackValue: Bool { isGeneratingFeedback }
    var speakingFeedback: SpeakingConversationFeedback? { conversationFeedback }

    let setup: SpeakingConversationSetup
    var onTimerFinished: (() -> Void)?

    var formattedRemainingTime: String {
        let s = max(0, remainingSeconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    var isTimeRunningOut: Bool { remainingSeconds > 0 && remainingSeconds < 60 }

    var hasTranscript: Bool { !transcriptChunks.isEmpty || !partialTranscript.isEmpty }

    private let recognizer: SpeechRecognitionService
    private let feedbackService: SpeakingFeedbackService
    private let imageProvider: DescribePictureImageProviding

    private var hasStarted = false
    private var didRecordPracticeStats = false
    private let statsService: DailyPracticeStatsService
    private var permissionsRequested = false
    private var lastSubmittedTranscript = ""

    private var timerTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?

    private let pictureContext: SpeakingConversationContext = .generatedTopic(
        GeneratedConversationTopic(
            title: "Describe a picture",
            description: "Describe what you can see in a picture.",
            firstAIMessage: "Describe what you can see in this picture.",
            promptContext: "The learner is describing a photograph aloud. Evaluate their spoken description: people, objects, actions, colours and emotions they mention. There is no AI interlocutor — judge only the learner's monologue.",
            category: "Describe Picture"
        )
    )

    init(
        setup: SpeakingConversationSetup,
        recognizer: SpeechRecognitionService? = nil,
        feedbackService: SpeakingFeedbackService? = nil,
        imageProvider: DescribePictureImageProviding? = nil,
        statsService: DailyPracticeStatsService = .shared
    ) {
        self.setup = setup
        self.recognizer = recognizer ?? SpeechRecognitionService()
        self.feedbackService = feedbackService ?? SpeakingFeedbackService()
        self.imageProvider = imageProvider ?? DescribePictureImageConfiguration.makeProvider()
        self.statsService = statsService
        self.remainingSeconds = setup.length.minutes * 60
        wireRecognizerCallbacks()
    }

    deinit {
        timerTask?.cancel()
        feedbackTask?.cancel()
        imageTask?.cancel()
    }

    func startSession() {
        guard !hasStarted else { return }
        hasStarted = true

        #if DEBUG
        print("[DescribePictureVM] startSession lang=\(setup.language.title) level=\(setup.level.rawValue) length=\(setup.length.title)")
        #endif

        startTimer()
        loadRandomImage()
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
            sourceModeID: "describe-picture"
        )
    }

    func resetSession() {
        endSession()
        feedbackTask?.cancel()
        feedbackTask = nil
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil
        messages.removeAll()
        transcriptChunks.removeAll()
        partialTranscript = ""
        hasStarted = false
        didRecordPracticeStats = false
        errorMessage = nil
        permissionsDenied = false
        lastSubmittedTranscript = ""
        remainingSeconds = setup.length.minutes * 60
        currentImage = nil
        imageError = nil
    }

    func loadRandomImage() {
        guard !isLoadingImage else {
            #if DEBUG
            print("[DescribePictureVM] loadRandomImage ignored — request already in flight")
            #endif
            return
        }

        imageTask?.cancel()
        isLoadingImage = true
        imageError = nil

        let provider = imageProvider
        imageTask = Task { [weak self] in
            do {
                let image = try await provider.fetchRandomImage()
                if Task.isCancelled { return }
                self?.currentImage = image
                self?.isLoadingImage = false
                #if DEBUG
                print("[DescribePictureVM] image loaded id=\(image.id)")
                #endif
            } catch {
                if Task.isCancelled { return }
                self?.isLoadingImage = false
                let message = (error as? DescribePictureImageError)?.errorDescription
                    ?? error.localizedDescription
                self?.imageError = message
                #if DEBUG
                print("[DescribePictureVM] image load failed: \(message)")
                #endif
            }
        }
    }

    func refreshImage() {
        guard !isLoadingImage else { return }
        resetTranscript()
        loadRandomImage()
    }

    private func resetTranscript() {
        recognizer.cancel()
        feedbackTask?.cancel()
        feedbackTask = nil
        conversationFeedback = nil
        isGeneratingFeedback = false
        feedbackError = nil
        messages.removeAll()
        transcriptChunks.removeAll()
        partialTranscript = ""
        lastSubmittedTranscript = ""
        state = .idle
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
            #if DEBUG
            print("[DescribePictureVM] partial transcript update (len=\(text.count))")
            #endif
            self?.partialTranscript = text
        }

        recognizer.onFinalTranscript = { [weak self] text in
            guard let self else { return }
            #if DEBUG
            print("[DescribePictureVM] final transcript received (len=\(text.count))")
            #endif
            self.handleFinalTranscript(text)
        }

        recognizer.onError = { [weak self] error in
            guard let self else { return }
            #if DEBUG
            print("[DescribePictureVM] recognition error: \(error.localizedDescription)")
            #endif
            self.partialTranscript = ""
            switch error {
            case .microphonePermissionDenied, .speechPermissionDenied:
                self.permissionsDenied = true
                self.errorMessage = "Microphone and speech recognition access are required for Describe Picture."
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
        print("[DescribePictureVM] toggleListening (state=\(state))")
        #endif
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
        print("[DescribePictureVM] mic tapped → startListening (permissionsRequested=\(permissionsRequested))")
        #endif

        if !permissionsRequested {
            permissionsRequested = true
            let granted = await recognizer.requestPermissions()
            #if DEBUG
            print("[DescribePictureVM] permission result granted=\(granted)")
            #endif
            guard granted else {
                permissionsDenied = true
                errorMessage = "Microphone and speech recognition access are required for Describe Picture."
                state = .idle
                return
            }
            permissionsDenied = false
        }

        await recognizer.start(localeIdentifier: setup.speechLocaleIdentifier)
        if recognizer.isListening {
            #if DEBUG
            print("[DescribePictureVM] mic started locale=\(setup.speechLocaleIdentifier)")
            #endif
            state = .listening
        }
    }

    func stopListening() {
        guard recognizer.isListening else { return }
        #if DEBUG
        print("[DescribePictureVM] mic tapped → stopListening")
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
        print("[DescribePictureVM] transcript chunk appended: \(trimmed.prefix(60))")
        #endif

        messages.append(SpeakingConversationMessage(role: .user, text: trimmed))
        transcriptChunks.append(trimmed)
        state = .idle
    }

    func clearError() {
        errorMessage = nil
    }

    private func beginFeedbackGeneration() {
        let snapshotLanguage = setup.language
        let snapshotLevel = setup.level
        let snapshotContext = pictureContext
        let snapshotMessages = messages
        let service = feedbackService

        #if DEBUG
        print("[DescribePictureVM] feedback generation start userMessages=\(snapshotMessages.count)")
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
                    print("[DescribePictureVM] feedback fallback reason='\(reason)'")
                } else {
                    print("[DescribePictureVM] feedback AI succeeded overall=\(result.feedback.overallScore)")
                }
                #endif
            }
        }
    }
}

extension DescribePictureViewModel: SpeakingResultProvidable {}
