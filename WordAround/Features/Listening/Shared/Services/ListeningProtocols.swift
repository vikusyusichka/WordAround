import Foundation


protocol ListeningQuestionGenerating {
    func generateQuestions(
        from text: String,
        language: GrammarLanguage,
        level: EssayDifficulty,
        types: Set<ListeningQuestionType>,
        count: Int
    ) async -> [ListeningQuestion]
}


@MainActor
protocol ListeningSpeechSynthesizing: AnyObject {
    var onStart: (() -> Void)? { get set }
    var onFinish: (() -> Void)? { get set }
    var isSpeaking: Bool { get }
    var isPaused: Bool { get }

    func speak(_ text: String, localeIdentifier: String, rate: Float, voiceType: ListeningVoiceType)
    func pause()
    func resume()
    func stop()
}


enum ListeningTranscriptionError: LocalizedError, Equatable {
    case permissionDenied
    case recognizerUnavailable
    case emptyTranscript
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition access is required to create questions from your audio."
        case .recognizerUnavailable:
            return "Speech recognition isn't available for this language right now."
        case .emptyTranscript:
            return "This audio is too short or unclear to create questions."
        case .failed(let message):
            return message
        }
    }
}

protocol ListeningAudioTranscribing {
    func requestPermission() async -> Bool
    func transcribe(fileURL: URL, localeIdentifier: String) async throws -> String
}


@MainActor
protocol ListeningAudioPlaying: AnyObject {
    var onProgress: ((TimeInterval, TimeInterval) -> Void)? { get set }
    var onFinish: (() -> Void)? { get set }
    var duration: TimeInterval { get }
    var currentTime: TimeInterval { get }
    var isPlaying: Bool { get }

    func load(url: URL) throws
    func play()
    func pause()
    func seek(to time: TimeInterval)
    func setRate(_ rate: Float)
    func stop()
}


protocol ListeningSessionStoring {
    func fetchSessions() async -> [ListeningPersistedSession]
    func session(id: String) async -> ListeningPersistedSession?
    func save(_ session: ListeningPersistedSession) async
    func delete(id: String) async
}
