import Combine
import Foundation

@MainActor
final class VideoListeningSessionViewModel: ObservableObject {

    /// Ordered flow of a video session. Questions stay locked until `.watched`.
    enum Phase: Equatable {
        case watching
        case watched
        case answeringQuestions
        case checkedAnswers
        case completed
    }

    let setup: ListeningVideoSetup
    let video: ListeningVideoItem

    // MARK: - Flow
    @Published private(set) var phase: Phase = .watching

    // MARK: - Questions
    @Published private(set) var orderedQuestions: [ListeningQuestion] = []
    @Published private(set) var isGeneratingQuestions = false
    @Published var selectedAnswers: [String: Int] = [:]

    // MARK: - Watch tracking / native player placeholder state
    @Published private(set) var watchSeconds = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackProgress: Double = 0

    // MARK: - Subtitles
    @Published var subtitlesEnabled = false
    @Published private(set) var subtitleCues: [ListeningSubtitleCue] = []
    @Published private(set) var activeSubtitleCue: ListeningSubtitleCue?
    @Published private(set) var selectedSubtitleCue: ListeningSubtitleCue?
    @Published private(set) var subtitleLoadState: ListeningSubtitleLoadState = .idle

    // MARK: - Translation
    @Published private(set) var selectedSubtitleText: String?
    @Published private(set) var translatedSubtitleText: String?
    @Published private(set) var isTranslating = false
    @Published private(set) var translationError: String?

    // MARK: - Result / navigation
    @Published var showResult = false
    @Published var errorMessage: String?
    @Published private(set) var result: ListeningResult?

    private let sessionId: String
    private let generator: ListeningQuestionGenerating
    private let scorer = ListeningScoringService.shared
    private let store: ListeningSessionStoring
    private let translator: ListeningTranslationServicing
    private var timer: Timer?
    private var didStart = false

    init(
        setup: ListeningVideoSetup,
        video: ListeningVideoItem,
        sessionId: String = UUID().uuidString,
        restore: ListeningPersistedSession? = nil,
        generator: ListeningQuestionGenerating? = nil,
        store: ListeningSessionStoring? = nil,
        translator: ListeningTranslationServicing? = nil
    ) {
        self.setup = setup
        self.video = video
        self.sessionId = restore?.id ?? sessionId
        self.generator = generator ?? LocalListeningQuestionGenerator()
        self.store = store ?? LocalListeningSessionStore.shared
        self.translator = translator ?? AIListeningTranslationService()

        if let restore {
            self.watchSeconds = restore.elapsedSeconds
            self.orderedQuestions = restore.questions
            self.selectedAnswers = restore.selectedAnswers
            // A resumed session has already been watched — unlock questions.
            if !restore.questions.isEmpty {
                self.phase = .answeringQuestions
            } else {
                self.phase = .watched
            }
        }
    }

    // MARK: - Derived

    var supportsQuestions: Bool { video.supportsQuestions }
    var requiresExternalPlayback: Bool { video.requiresExternalPlayback }
    var questionsUnlocked: Bool { phase != .watching }
    var hasCheckedAnswers: Bool { phase == .checkedAnswers }
    var isWatched: Bool { phase != .watching }

    var metadataLine: String {
        "\(setup.language.title) • \(setup.level.title) • \(durationText)"
    }

    var durationSeconds: Int {
        video.durationSeconds > 0 ? video.durationSeconds : max(watchSeconds, 1)
    }

    var durationText: String {
        video.durationText.isEmpty ? formatTime(durationSeconds) : video.durationText
    }

    var currentTimeText: String { formatTime(min(watchSeconds, durationSeconds)) }

    var watchURL: URL? { video.watchURL }

    var activeSubtitleText: String? { activeSubtitleCue?.text }

    var canTranslate: Bool {
        !(selectedSubtitleText?.isEmpty ?? true) && !isTranslating
    }

    // MARK: - Lifecycle

    func onAppear() {
        guard !didStart else { return }
        didStart = true
        startWatchTimer()
        loadSubtitles()
        // Generate questions in the background so they're ready the moment the
        // user finishes watching — they stay hidden until then.
        if supportsQuestions && orderedQuestions.isEmpty, let transcript = video.transcriptText {
            generateQuestions(from: transcript)
        }
        persist(status: .inProgress)
    }

    func teardown() {
        stopTimer()
        if !showResult { persist(status: .inProgress) }
    }

    private func startWatchTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        watchSeconds += 1
        playbackProgress = min(Double(watchSeconds) / Double(max(durationSeconds, 1)), 1)
        updateActiveSubtitle()

        // Native player (future) auto-completes when playback reaches the end.
        if !requiresExternalPlayback,
           phase == .watching,
           video.durationSeconds > 0,
           watchSeconds >= video.durationSeconds {
            markVideoFinished()
        }
    }

    // MARK: - Subtitles

    private func loadSubtitles() {
        subtitleLoadState = .loading
        let cues = ListeningSubtitleBuilder.estimatedCues(
            transcript: video.transcriptText,
            totalDuration: TimeInterval(video.durationSeconds)
        )
        if cues.isEmpty {
            subtitleLoadState = .unavailable
        } else {
            subtitleCues = cues
            subtitleLoadState = .loaded
            updateActiveSubtitle()
        }
    }

    private func updateActiveSubtitle() {
        guard subtitleLoadState == .loaded, !subtitleCues.isEmpty else { return }
        let time = TimeInterval(watchSeconds)
        if let match = subtitleCues.first(where: { $0.contains(time: time) }) {
            activeSubtitleCue = match
        } else if activeSubtitleCue == nil {
            activeSubtitleCue = subtitleCues.first
        }
    }

    func toggleSubtitles() {
        subtitlesEnabled.toggle()
        if subtitlesEnabled { updateActiveSubtitle() }
    }

    /// Selects the current subtitle line so it can be translated.
    func selectActiveSubtitle() {
        guard let cue = activeSubtitleCue else { return }
        selectedSubtitleCue = cue
        selectedSubtitleText = cue.text
        translatedSubtitleText = cue.translation
        translationError = nil
    }

    // MARK: - Translation

    func translateSelectedSubtitle() {
        guard let text = selectedSubtitleText, !text.isEmpty else {
            translationError = "Tap a subtitle line first."
            return
        }
        isTranslating = true
        translationError = nil
        let target = translator.defaultTargetLanguage(for: setup.language)
        Task {
            do {
                let translated = try await translator.translate(
                    text: text, from: setup.language, to: target
                )
                self.translatedSubtitleText = translated
                if let id = self.selectedSubtitleCue?.id,
                   let idx = self.subtitleCues.firstIndex(where: { $0.id == id }) {
                    self.subtitleCues[idx].translation = translated
                }
            } catch {
                self.translationError = (error as? LocalizedError)?.errorDescription
                    ?? "Couldn't translate this line right now."
            }
            self.isTranslating = false
        }
    }

    // MARK: - Native player placeholder controls

    func togglePlayback() {
        // Placeholder: drives the future native AVPlayer. No real media yet.
        isPlaying.toggle()
    }

    func replayVideo() {
        watchSeconds = 0
        playbackProgress = 0
        isPlaying = false
        activeSubtitleCue = subtitleCues.first
    }

    // MARK: - Watch completion

    /// Called when the native player reaches the end, or when the user taps
    /// "I watched this video" for an external (YouTube) source. Unlocks questions.
    func markVideoFinished() {
        guard phase == .watching else { return }
        phase = .watched
        if supportsQuestions, orderedQuestions.isEmpty, let transcript = video.transcriptText {
            generateQuestions(from: transcript)
        }
        persist(status: .inProgress)
    }

    func handleVideoOpenFailure() {
        errorMessage = "We couldn't open this video. Please try again later."
    }

    // MARK: - Questions

    private func generateQuestions(from transcript: String) {
        isGeneratingQuestions = true
        Task {
            let generated = await generator.generateQuestions(
                from: transcript,
                language: setup.language,
                level: setup.level,
                types: Set(ListeningQuestionType.allCases),
                count: 5
            )
            self.orderedQuestions = generated
            self.isGeneratingQuestions = false
        }
    }

    func startQuestions() {
        guard phase == .watched, supportsQuestions else { return }
        phase = .answeringQuestions
    }

    func selectAnswer(questionID: String, optionIndex: Int) {
        guard phase == .answeringQuestions else { return }
        selectedAnswers[questionID] = optionIndex
    }

    var canCheckAnswers: Bool {
        !orderedQuestions.isEmpty && !selectedAnswers.isEmpty
    }

    func checkAnswers() {
        guard phase == .answeringQuestions else { return }
        guard canCheckAnswers else {
            errorMessage = "Answer at least one question before checking."
            return
        }
        errorMessage = nil
        phase = .checkedAnswers
        persist(status: .inProgress)
    }

    // MARK: - Bottom action

    /// `nil` hides the bottom action bar (during `.watching`).
    var bottomButtonTitle: String? {
        switch phase {
        case .watching:
            return nil
        case .watched:
            return supportsQuestions ? "Start Questions" : "Finish Practice"
        case .answeringQuestions:
            return "Check Answers"
        case .checkedAnswers, .completed:
            return "Finish Practice"
        }
    }

    var bottomButtonIcon: String {
        switch phase {
        case .watched:
            return supportsQuestions ? "questionmark.circle.fill" : "flag.checkered"
        case .answeringQuestions:
            return "checkmark.circle.fill"
        default:
            return "flag.checkered"
        }
    }

    func handleBottomAction() {
        switch phase {
        case .watching:
            break
        case .watched:
            supportsQuestions ? startQuestions() : finish()
        case .answeringQuestions:
            checkAnswers()
        case .checkedAnswers, .completed:
            finish()
        }
    }

    private func finish() {
        stopTimer()
        phase = .completed
        let answered = supportsQuestions && !orderedQuestions.isEmpty && !selectedAnswers.isEmpty
        let computed = scorer.makeResult(
            sessionId: sessionId,
            questions: orderedQuestions,
            selectedAnswers: selectedAnswers,
            listeningTimeSeconds: watchSeconds,
            speedLabel: "1.0x",
            hasQuestions: answered
        )
        result = computed
        persist(status: .completed, result: computed)
        showResult = true
    }

    // MARK: - Helpers

    func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Persistence

    private func persist(status: ListeningSessionStatus, result: ListeningResult? = nil) {
        let session = ListeningPersistedSession(
            id: sessionId,
            modeID: "video-listening",
            title: video.title,
            language: setup.language,
            level: setup.level,
            durationSeconds: watchSeconds,
            elapsedSeconds: watchSeconds,
            progress: status == .completed ? 1 : 0.5,
            videoURL: video.watchURL?.absoluteString,
            videoTitle: video.title,
            videoChannel: video.channel,
            transcript: video.transcriptText,
            addQuestions: supportsQuestions,
            questions: orderedQuestions,
            selectedAnswers: selectedAnswers,
            result: result ?? self.result,
            status: status
        )
        Task { await store.save(session) }
    }
}
