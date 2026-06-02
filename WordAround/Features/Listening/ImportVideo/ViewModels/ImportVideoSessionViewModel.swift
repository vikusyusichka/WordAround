import Combine
import Foundation
import AVFoundation

@MainActor
final class ImportVideoSessionViewModel: ObservableObject {

    enum Phase: Equatable {
        case watching
        case watched
        case answeringQuestions
        case checkedAnswers
        case completed
    }

    let setup: ListeningVideoImportSetup
    let player: AVPlayer

    @Published private(set) var phase: Phase = .watching

    @Published private(set) var questions: [ListeningQuestion] = []
    @Published private(set) var isGeneratingQuestions = false
    @Published var selectedAnswers: [String: Int] = [:]

    @Published private(set) var currentTime: Double = 0
    @Published private(set) var watchedSeconds = 0

    @Published var subtitlesEnabled = true
    @Published private(set) var activeCue: ListeningSubtitleCue?

    @Published var showTranslationSheet = false
    @Published private(set) var selectedWord: String?
    @Published private(set) var selectedWordContext: String?
    @Published private(set) var wordTranslation: ListeningTranslationResult?
    @Published private(set) var isTranslating = false
    @Published var wordTranslationError: String?
    @Published var translationTarget: GrammarLanguage = .ukrainian
    @Published private(set) var savedWords: [ListeningTranslationResult] = []

    @Published private(set) var availableSets: [FlashcardSet] = []
    @Published private(set) var isLoadingSets = false
    @Published private(set) var isSavingToSet = false
    @Published var setSaveError: String?
    @Published private(set) var savedToSetName: String?

    @Published var showResult = false
    @Published var showShadowing = false
    @Published private(set) var result: ListeningResult?

    let transcription: ListeningTranscriptionResponse
    private let cues: [ListeningSubtitleCue]
    private let sessionId: String
    private let generator: ListeningQuestionGenerating
    private let scorer = ListeningScoringService.shared
    private let store: ListeningSessionStoring
    private let translator: ListeningTranslationServicing
    private let setSaver: ListeningSetSavingServicing

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var didStart = false

    init(
        setup: ListeningVideoImportSetup,
        transcription: ListeningTranscriptionResponse,
        sessionId: String = UUID().uuidString,
        generator: ListeningQuestionGenerating? = nil,
        store: ListeningSessionStoring? = nil,
        translator: ListeningTranslationServicing? = nil,
        setSaver: ListeningSetSavingServicing? = nil
    ) {
        self.setup = setup
        self.transcription = transcription
        self.cues = ListeningSubtitleBuilder.sentenceCues(from: transcription.orderedCues)
        self.sessionId = sessionId
        self.player = AVPlayer(url: setup.videoURL)
        self.generator = generator ?? LocalListeningQuestionGenerator()
        self.store = store ?? LocalListeningSessionStore.shared
        let resolvedTranslator = translator ?? AIListeningTranslationService()
        self.translator = resolvedTranslator
        self.setSaver = setSaver ?? ListeningSetSavingService()
        self.translationTarget = resolvedTranslator.defaultTargetLanguage(for: setup.language)
    }


    var supportsQuestions: Bool { setup.addQuestions && transcription.hasUsableTranscript }
    var hasSubtitles: Bool { !cues.isEmpty }
    var hasCheckedAnswers: Bool { phase == .checkedAnswers }
    var isWatched: Bool { phase != .watching }
    var activeSubtitleText: String? { activeCue?.text }
    var canCheckAnswers: Bool { !questions.isEmpty && !selectedAnswers.isEmpty }

    var durationSeconds: Int {
        setup.durationSeconds > 0 ? Int(setup.durationSeconds) : max(watchedSeconds, 1)
    }
    var metadataLine: String { setup.metadataLine }


    func onAppear() {
        guard !didStart else { return }
        didStart = true
        configureAudioSession()
        addObservers()
        if supportsQuestions {
            generateQuestions()
        }
        persist(status: .inProgress)
    }

    func teardown() {
        player.pause()
        removeObservers()
        if !showResult { persist(status: .inProgress) }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }

    private func addObservers() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                self?.handleTime(CMTimeGetSeconds(time))
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.markVideoFinished() }
        }
    }

    private func removeObservers() {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
    }

    private func handleTime(_ seconds: Double) {
        guard seconds.isFinite else { return }
        currentTime = seconds
        watchedSeconds = max(watchedSeconds, Int(seconds))
        if subtitlesEnabled {
            activeCue = cues.first { $0.contains(time: seconds) } ?? activeCue
        }
    }

    func toggleSubtitles() {
        subtitlesEnabled.toggle()
        if subtitlesEnabled {
            activeCue = cues.first { $0.contains(time: currentTime) } ?? cues.first
        }
    }


    func markVideoFinished() {
        guard phase == .watching else { return }
        phase = .watched
        persist(status: .inProgress)
    }


    private func generateQuestions() {
        isGeneratingQuestions = true
        Task {
            let generated = await generator.generateQuestions(
                from: transcription.transcriptText,
                language: setup.language,
                level: setup.level,
                types: setup.questionTypes,
                count: setup.questionCount
            )
            self.questions = generated
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

    func checkAnswers() {
        guard phase == .answeringQuestions else { return }
        guard canCheckAnswers else {
            setSaveError = nil
            wordTranslationError = "Answer at least one question before checking."
            return
        }
        phase = .checkedAnswers
        persist(status: .inProgress)
    }


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
        case .watched:           return supportsQuestions ? "questionmark.circle.fill" : "flag.checkered"
        case .answeringQuestions: return "checkmark.circle.fill"
        default:                  return "flag.checkered"
        }
    }

    func handleBottomAction() {
        switch phase {
        case .watching:           break
        case .watched:            supportsQuestions ? startQuestions() : finish()
        case .answeringQuestions: checkAnswers()
        case .checkedAnswers, .completed: finish()
        }
    }

    private func finish() {
        player.pause()
        phase = .completed
        let answered = supportsQuestions && !questions.isEmpty && !selectedAnswers.isEmpty
        let computed = scorer.makeResult(
            sessionId: sessionId,
            questions: questions,
            selectedAnswers: selectedAnswers,
            listeningTimeSeconds: watchedSeconds,
            speedLabel: "1.0x",
            hasQuestions: answered
        )
        result = computed
        persist(status: .completed, result: computed)
        showResult = true
    }


    func selectWord(_ word: String) {
        let cleaned = word.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard !cleaned.isEmpty else { return }
        selectedWord = cleaned
        selectedWordContext = activeCue?.text
        wordTranslation = nil
        wordTranslationError = nil
        savedToSetName = nil
        setSaveError = nil
        showTranslationSheet = true
        translateSelectedWord()
    }

    func changeTranslationTarget(_ language: GrammarLanguage) {
        guard language != translationTarget else { return }
        translationTarget = language
        translateSelectedWord()
    }

    func translateSelectedWord() {
        guard let word = selectedWord, !word.isEmpty else { return }
        isTranslating = true
        wordTranslationError = nil
        let context = selectedWordContext
        let source = setup.language
        let target = translationTarget
        Task {
            do {
                let translation = try await translator.translateWord(
                    word: word, context: context, from: source, to: target
                )
                wordTranslation = translation
                rememberTranslatedWord(translation)
            } catch {
                wordTranslationError = (error as? LocalizedError)?.errorDescription
                    ?? "Couldn't translate this word right now."
            }
            isTranslating = false
        }
    }

    var canTranslate: Bool { !(selectedWord?.isEmpty ?? true) && !isTranslating }


    func loadSetsIfNeeded() {
        guard availableSets.isEmpty, !isLoadingSets else { return }
        isLoadingSets = true
        setSaveError = nil
        Task {
            do {
                availableSets = try await setSaver.fetchSets()
            } catch {
                setSaveError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isLoadingSets = false
        }
    }

    func addTranslationToSet(setID: String) {
        guard let translation = wordTranslation else { return }
        let card = Flashcard.fromListening(translation, videoTitle: setup.fileName)
        isSavingToSet = true
        setSaveError = nil
        Task {
            do {
                let set = try await setSaver.addCard(card, toSetID: setID)
                recordSavedWord(translation, setName: set.title)
            } catch {
                setSaveError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isSavingToSet = false
        }
    }

    func createSetAndAdd(title: String, description: String, color: SetColor) {
        guard let translation = wordTranslation else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { setSaveError = "Give the set a name."; return }
        let card = Flashcard.fromListening(translation, videoTitle: setup.fileName)
        isSavingToSet = true
        setSaveError = nil
        Task {
            do {
                let set = try await setSaver.createSet(
                    title: trimmed, description: description, color: color, firstCard: card
                )
                availableSets.insert(set, at: 0)
                recordSavedWord(translation, setName: set.title)
            } catch {
                setSaveError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isSavingToSet = false
        }
    }

    private func recordSavedWord(_ translation: ListeningTranslationResult, setName: String) {
        rememberTranslatedWord(translation)
        savedToSetName = setName
    }

    private func rememberTranslatedWord(_ translation: ListeningTranslationResult) {
        if !savedWords.contains(where: { $0.originalText.caseInsensitiveCompare(translation.originalText) == .orderedSame }) {
            savedWords.append(translation)
        }
    }


    func makeShadowingPayload() -> ListeningShadowingPayload {
        let cuePhrases = cues
            .map(\.text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return ListeningShadowingPayload(
            title: setup.fileName,
            language: setup.language,
            level: setup.level,
            phrases: Array(cuePhrases.prefix(8)),
            selectedWords: savedWords
        )
    }

    func startShadowing() { showShadowing = true }


    private func persist(status: ListeningSessionStatus, result: ListeningResult? = nil) {
        let session = ListeningPersistedSession(
            id: sessionId,
            modeID: "import-video",
            title: setup.fileName,
            language: setup.language,
            level: setup.level,
            durationSeconds: durationSeconds,
            elapsedSeconds: watchedSeconds,
            progress: status == .completed ? 1 : 0.5,
            localAudioFileName: setup.storedFileName,
            transcript: transcription.transcriptText,
            addQuestions: supportsQuestions,
            questions: questions,
            selectedAnswers: selectedAnswers,
            result: result ?? self.result,
            status: status
        )
        Task { await store.save(session) }
    }
}
