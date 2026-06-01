import Foundation
import AVFoundation

/// AVFoundation-backed text-to-speech for Listen From Text. Wraps
/// `AVSpeechSynthesizer` and exposes a small play/pause/resume/stop API plus
/// start/finish callbacks. View models depend on `ListeningSpeechSynthesizing`,
/// never on AVFoundation directly.
@MainActor
final class AVFoundationListeningSpeechService: NSObject, ListeningSpeechSynthesizing {

    var onStart: (() -> Void)?
    var onFinish: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    var isSpeaking: Bool { synthesizer.isSpeaking }
    var isPaused: Bool { synthesizer.isPaused }

    func speak(_ text: String, localeIdentifier: String, rate: Float, voiceType: ListeningVoiceType = .default) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onFinish?()
            return
        }

        configureAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = Self.resolveVoice(localeIdentifier: localeIdentifier, voiceType: voiceType)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0

        synthesizer.speak(utterance)
    }

    func pause() {
        guard synthesizer.isSpeaking, !synthesizer.isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
    }

    func stop() {
        guard synthesizer.isSpeaking || synthesizer.isPaused else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
    }

    /// Best installed voice for the locale and requested gender, degrading gracefully.
    private static func resolveVoice(
        localeIdentifier: String,
        voiceType: ListeningVoiceType
    ) -> AVSpeechSynthesisVoice? {
        let candidates = voicesMatching(localeIdentifier: localeIdentifier)

        switch voiceType {
        case .default:
            return preferredVoice(from: candidates, localeIdentifier: localeIdentifier)
        case .male:
            return voiceMatchingGender(.male, in: candidates)
                ?? preferredVoice(from: candidates, localeIdentifier: localeIdentifier)
        case .female:
            return voiceMatchingGender(.female, in: candidates)
                ?? preferredVoice(from: candidates, localeIdentifier: localeIdentifier)
        }
    }

    private static func voicesMatching(localeIdentifier: String) -> [AVSpeechSynthesisVoice] {
        let normalized = localeIdentifier.lowercased()
        let prefix = normalized.split(separator: "-").first.map(String.init) ?? normalized
        let matches = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            let language = voice.language.lowercased()
            return language == normalized
                || language.hasPrefix("\(prefix)-")
                || language == prefix
        }

        if matches.isEmpty, let exact = AVSpeechSynthesisVoice(language: localeIdentifier) {
            return [exact]
        }

        return matches.sorted { lhs, rhs in
            let lhsEnhanced = lhs.quality == .enhanced
            let rhsEnhanced = rhs.quality == .enhanced
            if lhsEnhanced != rhsEnhanced { return lhsEnhanced }
            return lhs.language.count > rhs.language.count
        }
    }

    private static func preferredVoice(
        from candidates: [AVSpeechSynthesisVoice],
        localeIdentifier: String
    ) -> AVSpeechSynthesisVoice? {
        candidates.first ?? AVSpeechSynthesisVoice(language: localeIdentifier)
    }

    private static func voiceMatchingGender(
        _ gender: AVSpeechSynthesisVoiceGender,
        in candidates: [AVSpeechSynthesisVoice]
    ) -> AVSpeechSynthesisVoice? {
        if let match = candidates.first(where: { $0.gender == gender }) {
            return match
        }

        let hints: [String]
        switch gender {
        case .male:
            hints = ["daniel", "aaron", "fred", "tom", "alex", "rishi", "jacques", "martin", "nathan", "lee"]
        case .female:
            hints = ["samantha", "karen", "moira", "tessa", "allison", "ava", "zira", "fiona", "martha", "victoria"]
        default:
            return nil
        }

        return candidates.first { voice in
            let identifier = voice.identifier.lowercased()
            let name = voice.name.lowercased()
            return hints.contains { identifier.contains($0) || name.contains($0) }
        }
    }
}

extension AVFoundationListeningSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.onStart?() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.onFinish?() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Cancellation (replay / leaving the screen) is not a natural finish; do
        // not fire onFinish so callers can distinguish a user stop from EOF.
    }
}
