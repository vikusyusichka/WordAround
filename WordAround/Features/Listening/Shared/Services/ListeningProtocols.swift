import Foundation

// MARK: - Question generation

/// Builds comprehension questions from a piece of text (pasted text, an audio
/// transcript, or a video transcript). Implemented locally for the MVP and
/// swappable for an AI-backed generator later.
protocol ListeningQuestionGenerating {
    func generateQuestions(
        from text: String,
        language: GrammarLanguage,
        level: EssayDifficulty,
        types: Set<ListeningQuestionType>,
        count: Int
    ) async -> [ListeningQuestion]
}

// MARK: - Speech synthesis (Listen From Text)

/// Text-to-speech playback abstraction so view models never touch AVFoundation
/// directly. Callbacks are delivered on the main actor.
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

// MARK: - Audio transcription (Import Audio)

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
            return "Transcription failed: \(message)"
        }
    }
}

/// Transcribes an on-disk audio file. The transcript stays internal and is used
/// only to generate questions — it is never shown to the user by default.
protocol ListeningAudioTranscribing {
    func requestPermission() async -> Bool
    func transcribe(fileURL: URL, localeIdentifier: String) async throws -> String
}

// MARK: - Audio playback (Import Audio)

/// Plays a local audio file with progress + finish callbacks.
@MainActor
protocol ListeningAudioPlaying: AnyObject {
    /// (currentTime, duration) in seconds.
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

// MARK: - Video search (Video Listening)

enum ListeningVideoSearchError: LocalizedError, Equatable {
    case emptyTopic
    case requestFailed(String)
    case noResults

    var errorDescription: String? {
        switch self {
        case .emptyTopic:
            return "Enter a topic to search for videos."
        case .requestFailed(let message):
            return "Video search failed: \(message)"
        case .noResults:
            return "No videos found. Try a different topic or level."
        }
    }
}

protocol ListeningVideoSearching {
    func search(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topic: String,
        length: ListeningVideoLength
    ) async throws -> [ListeningVideoItem]
}

// MARK: - Session persistence (Saved Practice)

/// Local-first store for completed and in-progress listening sessions.
protocol ListeningSessionStoring {
    func fetchSessions() async -> [ListeningPersistedSession]
    func session(id: String) async -> ListeningPersistedSession?
    func save(_ session: ListeningPersistedSession) async
    func delete(id: String) async
}
