import Combine
import Foundation

@MainActor
final class ListenFromTextSessionViewModel: ObservableObject {
    let setup: ListeningSessionSetup

    @Published private(set) var questions: [ListeningQuestion] = []
    @Published private(set) var isGeneratingQuestions = false
    @Published private(set) var playbackState: ListeningPlaybackState = .idle
    @Published var progress: Double = 0
    @Published private(set) var elapsedSeconds = 0
    @Published var selectedAnswers: [String: Int] = [:]
    @Published private(set) var hasCheckedAnswers = false
    @Published var showResult = false
    @Published var errorMessage: String?
    @Published private(set) var result: ListeningResult?

    private let sessionId: String
    private let speech: ListeningSpeechSynthesizing
    private let generator: ListeningQuestionGenerating
    private let scorer = ListeningScoringService.shared
    private let store: ListeningSessionStoring

    private var timer: Timer?
    private var playbackElapsed: Double = 0
    private let estimatedDuration: Double
    private var didStart = false

    init(
        setup: ListeningSessionSetup,
        sessionId: String = UUID().uuidString,
        restore: ListeningPersistedSession? = nil,
        speech: ListeningSpeechSynthesizing? = nil,
        generator: ListeningQuestionGenerating? = nil,
        store: ListeningSessionStoring? = nil
    ) {
        self.setup = setup
        self.sessionId = restore?.id ?? sessionId
        self.speech = speech ?? AVFoundationListeningSpeechService()
        self.generator = generator ?? LocalListeningQuestionGenerator()
        self.store = store ?? LocalListeningSessionStore.shared
        self.estimatedDuration = Double(max(setup.estimatedMinutes * 60, 8))

        if let restore {
            self.questions = restore.questions
            self.selectedAnswers = restore.selectedAnswers
            self.elapsedSeconds = restore.elapsedSeconds
            self.progress = restore.progress
            self.playbackElapsed = restore.playbackPosition
        }

        self.speech.onStart = { [weak self] in
            self?.playbackState = .playing
        }
        self.speech.onFinish = { [weak self] in
            guard let self else { return }
            self.playbackState = .finished
            self.progress = 1
            self.stopTimer()
            self.persist(status: .inProgress)
        }
    }


    func onAppear() {
        guard !didStart else { return }
        didStart = true
        if setup.addQuestions && questions.isEmpty {
            generateQuestions()
        }
        persist(status: .inProgress)
    }

    func teardown() {
        speech.stop()
        stopTimer()
        if !showResult {
            persist(status: .inProgress)
        }
    }


    private func generateQuestions() {
        isGeneratingQuestions = true
        Task {
            let generated = await generator.generateQuestions(
                from: setup.text,
                language: setup.language,
                level: setup.level,
                types: setup.questionTypes,
                count: setup.questionCount
            )
            self.questions = generated
            self.isGeneratingQuestions = false
            self.persist(status: .inProgress)
        }
    }


    var isPlaying: Bool { playbackState == .playing }

    func togglePlayback() {
        switch playbackState {
        case .idle, .finished:
            startSpeaking(resetProgress: playbackState == .finished)
        case .playing:
            speech.pause()
            playbackState = .paused
            stopTimer()
        case .paused:
            speech.resume()
            playbackState = .playing
            startTimer()
        }
    }

    func replay() {
        speech.stop()
        stopTimer()
        startSpeaking(resetProgress: true)
    }

    private func startSpeaking(resetProgress: Bool) {
        guard !setup.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "There's no text to read aloud."
            return
        }
        if resetProgress {
            playbackElapsed = 0
            progress = 0
        }
        speech.speak(
            setup.text,
            localeIdentifier: setup.language.listeningLocaleIdentifier,
            rate: setup.voiceSpeed.utteranceRate,
            voiceType: setup.voiceType
        )
        playbackState = .playing
        startTimer()
    }


    private func startTimer() {
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
        guard playbackState == .playing else { return }
        elapsedSeconds += 1
        playbackElapsed += 1
        progress = min(playbackElapsed / estimatedDuration, 1.0)
    }


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
        speech.stop()
        stopTimer()
        let computed = scorer.makeResult(
            sessionId: sessionId,
            questions: questions,
            selectedAnswers: selectedAnswers,
            listeningTimeSeconds: elapsedSeconds,
            speedLabel: setup.voiceSpeed.rawValue,
            hasQuestions: setup.addQuestions && !questions.isEmpty
        )
        result = computed
        persist(status: .completed, result: computed)
        showResult = true
    }


    var timerText: String { formatTime(elapsedSeconds) }
    var durationText: String { formatTime(Int(estimatedDuration)) }
    var currentTimeText: String { formatTime(Int(estimatedDuration * progress)) }

    func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }


    private func persist(status: ListeningSessionStatus, result: ListeningResult? = nil) {
        let session = ListeningPersistedSession(
            id: sessionId,
            modeID: setup.modeID,
            title: setup.title,
            language: setup.language,
            level: setup.level,
            durationSeconds: Int(estimatedDuration),
            elapsedSeconds: elapsedSeconds,
            progress: status == .completed ? 1 : progress,
            playbackPosition: estimatedDuration * progress,
            text: setup.text,
            transcript: nil,
            voiceSpeedRaw: setup.voiceSpeed.rawValue,
            voiceTypeRaw: setup.voiceType.rawValue,
            showTextWhileListening: setup.showTextWhileListening,
            addQuestions: setup.addQuestions,
            questions: questions,
            selectedAnswers: selectedAnswers,
            result: result ?? self.result,
            status: status
        )
        Task { await store.save(session) }
    }
}
