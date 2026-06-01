import Combine
import Foundation

@MainActor
final class ImportAudioSessionViewModel: ObservableObject {
    let setup: ListeningAudioImportSetup
    let questions: [ListeningQuestion]

    @Published private(set) var playbackState: ListeningPlaybackState = .idle
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsedSeconds = 0
    @Published var selectedAnswers: [String: Int] = [:]
    @Published private(set) var hasCheckedAnswers = false
    @Published var showResult = false
    @Published var errorMessage: String?
    @Published private(set) var result: ListeningResult?

    private let sessionId: String
    private let transcript: String
    private let player: ListeningAudioPlaying
    private let scorer = ListeningScoringService.shared
    private let store: ListeningSessionStoring

    private var currentTime: TimeInterval = 0
    private var knownDuration: TimeInterval
    private var didLoad = false

    init(
        setup: ListeningAudioImportSetup,
        sessionId: String = UUID().uuidString,
        questions: [ListeningQuestion] = [],
        transcript: String = "",
        restore: ListeningPersistedSession? = nil,
        player: ListeningAudioPlaying? = nil,
        store: ListeningSessionStoring? = nil
    ) {
        self.setup = setup
        self.sessionId = restore?.id ?? sessionId
        self.questions = restore?.questions ?? questions
        self.transcript = restore?.transcript ?? transcript
        self.player = player ?? AVFoundationAudioPlayerService()
        self.store = store ?? LocalListeningSessionStore.shared
        self.knownDuration = setup.durationSeconds > 0 ? setup.durationSeconds : 1

        if let restore {
            self.selectedAnswers = restore.selectedAnswers
            self.elapsedSeconds = restore.elapsedSeconds
            self.progress = restore.progress
            self.currentTime = restore.playbackPosition
        }

        self.player.onProgress = { [weak self] current, duration in
            guard let self else { return }
            self.currentTime = current
            if duration > 0 { self.knownDuration = duration }
            self.progress = self.knownDuration > 0 ? min(current / self.knownDuration, 1) : 0
            if self.playbackState == .playing {
                self.elapsedSeconds = max(self.elapsedSeconds, Int(current))
            }
        }
        self.player.onFinish = { [weak self] in
            guard let self else { return }
            self.playbackState = .finished
            self.progress = 1
            self.persist(status: .inProgress)
        }
    }

    // MARK: - Lifecycle

    func onAppear() {
        guard !didLoad else { return }
        didLoad = true

        // Validate the file exists before loading — storedFileName can be empty
        // if the session was saved before the audio was copied (e.g. force-quit).
        let url = setup.audioURL
        guard !setup.storedFileName.isEmpty,
              FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "The audio file for this session is no longer available."
            return
        }

        do {
            try player.load(url: url)
            if currentTime > 0 { player.seek(to: currentTime) }
        } catch {
            errorMessage = "We couldn't play this audio file. It may have been moved or deleted."
        }
        persist(status: .inProgress)
    }

    func teardown() {
        player.stop()
        if !showResult { persist(status: .inProgress) }
    }

    // MARK: - Playback

    var isPlaying: Bool { playbackState == .playing }

    func togglePlayback() {
        guard errorMessage == nil else { return }
        switch playbackState {
        case .idle, .paused, .finished:
            if playbackState == .finished { player.seek(to: 0) }
            player.play()
            playbackState = .playing
        case .playing:
            player.pause()
            playbackState = .paused
        }
    }

    func replay() {
        guard errorMessage == nil else { return }
        player.seek(to: 0)
        player.play()
        playbackState = .playing
    }

    // MARK: - Answers

    func selectAnswer(questionID: String, optionIndex: Int) {
        guard !hasCheckedAnswers else { return }
        selectedAnswers[questionID] = optionIndex
    }

    var bottomButtonTitle: String {
        if setup.addQuestions {
            return hasCheckedAnswers ? "Finish Practice" : "Check Answers"
        }
        return "Finish Practice"
    }

    var bottomButtonIcon: String {
        setup.addQuestions && !hasCheckedAnswers ? "checkmark.circle.fill" : "flag.checkered"
    }

    var canCheckAnswers: Bool {
        !questions.isEmpty && !selectedAnswers.isEmpty
    }

    func handleBottomAction() {
        if setup.addQuestions && !hasCheckedAnswers {
            guard canCheckAnswers else {
                errorMessage = "Answer at least one question before checking."
                return
            }
            errorMessage = nil
            hasCheckedAnswers = true
            persist(status: .inProgress)
        } else {
            finish()
        }
    }

    private func finish() {
        player.stop()
        let computed = scorer.makeResult(
            sessionId: sessionId,
            questions: questions,
            selectedAnswers: selectedAnswers,
            listeningTimeSeconds: max(elapsedSeconds, Int(currentTime)),
            speedLabel: "1.0x",
            hasQuestions: setup.addQuestions && !questions.isEmpty
        )
        result = computed
        persist(status: .completed, result: computed)
        showResult = true
    }

    // MARK: - Display helpers

    var timerText: String { formatTime(elapsedSeconds) }
    var currentTimeText: String { formatTime(Int(currentTime)) }
    var durationText: String { setup.durationText }
    var metadataLine: String { setup.metadataLine }

    func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Persistence

    private func persist(status: ListeningSessionStatus, result: ListeningResult? = nil) {
        let session = ListeningPersistedSession(
            id: sessionId,
            modeID: "import-audio",
            title: setup.fileName,
            language: setup.language,
            level: setup.level,
            durationSeconds: Int(knownDuration),
            elapsedSeconds: elapsedSeconds,
            progress: status == .completed ? 1 : progress,
            playbackPosition: currentTime,
            localAudioFileName: setup.storedFileName,
            transcript: transcript.isEmpty ? nil : transcript,
            addQuestions: setup.addQuestions,
            questions: questions,
            selectedAnswers: selectedAnswers,
            result: result ?? self.result,
            status: status
        )
        Task { await store.save(session) }
    }
}
