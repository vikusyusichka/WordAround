import Foundation

enum ListeningSessionStatus: String, Codable, Equatable {
    case draft
    case inProgress
    case completed
}

/// The full, codable representation of a listening session used for local-first
/// persistence. Every mode (text, audio, video) maps its setup + runtime state
/// onto this single model so Saved Practice can list, continue, review and
/// delete sessions uniformly.
struct ListeningPersistedSession: Identifiable, Codable, Equatable {
    let id: String
    var modeID: String                 // matches ListeningMode.id
    var title: String
    var language: GrammarLanguage
    var level: EssayDifficulty
    var createdAt: Date
    var updatedAt: Date

    var durationSeconds: Int           // total expected/known duration
    var elapsedSeconds: Int            // accumulated listening time
    var progress: Double               // 0...1 playback/overall progress
    var playbackPosition: Double       // seconds — where to resume

    // Mode-specific payloads (all optional)
    var text: String?
    var localAudioFileName: String?    // resolved against the audio cache dir
    var videoURL: String?
    var videoTitle: String?
    var videoChannel: String?
    var transcript: String?            // hidden, used only to (re)build questions

    // Setup snapshot needed to resume
    var voiceSpeedRaw: String?
    var voiceTypeRaw: String?
    var showTextWhileListening: Bool
    var addQuestions: Bool

    var questions: [ListeningQuestion]
    var selectedAnswers: [String: Int]
    var result: ListeningResult?
    var status: ListeningSessionStatus

    init(
        id: String = UUID().uuidString,
        modeID: String,
        title: String,
        language: GrammarLanguage,
        level: EssayDifficulty,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        durationSeconds: Int = 0,
        elapsedSeconds: Int = 0,
        progress: Double = 0,
        playbackPosition: Double = 0,
        text: String? = nil,
        localAudioFileName: String? = nil,
        videoURL: String? = nil,
        videoTitle: String? = nil,
        videoChannel: String? = nil,
        transcript: String? = nil,
        voiceSpeedRaw: String? = nil,
        voiceTypeRaw: String? = nil,
        showTextWhileListening: Bool = false,
        addQuestions: Bool = true,
        questions: [ListeningQuestion] = [],
        selectedAnswers: [String: Int] = [:],
        result: ListeningResult? = nil,
        status: ListeningSessionStatus = .draft
    ) {
        self.id = id
        self.modeID = modeID
        self.title = title
        self.language = language
        self.level = level
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.durationSeconds = durationSeconds
        self.elapsedSeconds = elapsedSeconds
        self.progress = progress
        self.playbackPosition = playbackPosition
        self.text = text
        self.localAudioFileName = localAudioFileName
        self.videoURL = videoURL
        self.videoTitle = videoTitle
        self.videoChannel = videoChannel
        self.transcript = transcript
        self.voiceSpeedRaw = voiceSpeedRaw
        self.voiceTypeRaw = voiceTypeRaw
        self.showTextWhileListening = showTextWhileListening
        self.addQuestions = addQuestions
        self.questions = questions
        self.selectedAnswers = selectedAnswers
        self.result = result
        self.status = status
    }

    var isInProgress: Bool { status == .inProgress }
    var isCompleted: Bool { status == .completed }

    /// User-facing progress for Saved Practice cards. In-progress sessions stay
    /// below 100% until formally completed; when questions exist, listening and
    /// answers each contribute half of the bar.
    var displayProgress: Double {
        if status == .completed { return 1 }
        if addQuestions && !questions.isEmpty {
            let listeningPortion = min(max(progress, 0), 1) * 0.5
            let answered = Double(selectedAnswers.count) / Double(max(questions.count, 1))
            return min(listeningPortion + answered * 0.5, 0.99)
        }
        return min(max(progress, 0), 0.99)
    }

    var modeTitle: String {
        switch modeID {
        case "listen-from-text": return "Listen from Text"
        case "import-audio":     return "Import Audio"
        case "video-listening":  return "Video Listening"
        default:                 return "Listening"
        }
    }

    var voiceSpeed: ListeningVoiceSpeed {
        voiceSpeedRaw.flatMap(ListeningVoiceSpeed.init(rawValue:)) ?? .normal
    }

    var voiceType: ListeningVoiceType {
        voiceTypeRaw.flatMap(ListeningVoiceType.init(rawValue:)) ?? .default
    }

    /// Resolved on-disk URL of the imported audio, if any.
    var localAudioURL: URL? {
        guard let localAudioFileName else { return nil }
        return ListeningAudioImporter.audioDirectory().appendingPathComponent(localAudioFileName)
    }

    /// Maps to the lightweight model the Saved Practice cards render.
    func toSavedSession() -> ListeningSavedSession {
        ListeningSavedSession(
            id: id,
            title: title,
            modeTitle: modeTitle,
            languageTitle: language.title,
            levelTitle: level.title,
            score: result.map { $0.comprehensionPercent },
            progress: displayProgress,
            status: status == .completed ? "Completed" : "In progress",
            dateText: Self.relativeDateText(from: updatedAt),
            isInProgress: status != .completed && result == nil
        )
    }

    // MARK: - Rebuilding mode setups (for Continue / restore)

    func makeTextSetup() -> ListeningSessionSetup {
        ListeningSessionSetup(
            modeID: modeID,
            language: language,
            level: level,
            title: title,
            text: text ?? "",
            voiceSpeed: voiceSpeed,
            voiceType: voiceType,
            showTextWhileListening: showTextWhileListening,
            addQuestions: addQuestions,
            questionCount: max(questions.count, 1),
            questionTypes: Set(ListeningQuestionType.allCases),
            estimatedMinutes: max(durationSeconds / 60, 1)
        )
    }

    func makeAudioSetup() -> ListeningAudioImportSetup {
        ListeningAudioImportSetup(
            language: language,
            level: level,
            fileName: title,
            storedFileName: localAudioFileName ?? "",
            durationText: Self.timeText(durationSeconds),
            durationSeconds: Double(durationSeconds),
            fileSizeText: "",
            addQuestions: addQuestions,
            questionCount: max(questions.count, 1),
            questionTypes: Set(ListeningQuestionType.allCases)
        )
    }

    func makeVideo() -> (setup: ListeningVideoSetup, video: ListeningVideoItem) {
        let setup = ListeningVideoSetup(language: language, level: level, length: .medium)
        let storedVideoID = videoURL.flatMap { ListeningVideoItem.extractYouTubeVideoID(from: $0) }
        let resolvedURL: String? = {
            if let storedVideoID {
                return "https://www.youtube.com/watch?v=\(storedVideoID)"
            }
            if let videoURL { return videoURL }
            return nil
        }()
        let video = ListeningVideoItem(
            id: storedVideoID ?? id,
            title: videoTitle ?? title,
            channel: videoChannel ?? "",
            durationText: Self.timeText(durationSeconds),
            difficultyTitle: level.title,
            hasCaptions: transcript != nil,
            sourceURL: resolvedURL,
            transcriptText: transcript
        )
        return (setup, video)
    }

    private static func timeText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private static func relativeDateText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
