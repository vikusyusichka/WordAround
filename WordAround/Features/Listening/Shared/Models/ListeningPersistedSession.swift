import Foundation

enum ListeningSessionStatus: String, Codable, Equatable {
    case draft
    case inProgress
    case completed
}

struct ListeningPersistedSession: Identifiable, Codable, Equatable {
    let id: String
    var modeID: String
    var title: String
    var language: GrammarLanguage
    var level: EssayDifficulty
    var createdAt: Date
    var updatedAt: Date

    var durationSeconds: Int
    var elapsedSeconds: Int
    var progress: Double
    var playbackPosition: Double

    var text: String?
    var localAudioFileName: String?
    var transcript: String?

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
        case "import-video":     return "Import Video"
        default:                 return "Listening"
        }
    }

    var voiceSpeed: ListeningVoiceSpeed {
        voiceSpeedRaw.flatMap(ListeningVoiceSpeed.init(rawValue:)) ?? .normal
    }

    var voiceType: ListeningVoiceType {
        voiceTypeRaw.flatMap(ListeningVoiceType.init(rawValue:)) ?? .default
    }

    var localAudioURL: URL? {
        guard let localAudioFileName else { return nil }
        return ListeningAudioImporter.audioDirectory().appendingPathComponent(localAudioFileName)
    }

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

    private static func timeText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private static func relativeDateText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
