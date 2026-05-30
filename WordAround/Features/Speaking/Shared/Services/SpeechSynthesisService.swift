import Foundation
import AVFoundation

@MainActor
final class SpeechSynthesisService: NSObject {

    var onStart: (() -> Void)?
    var onFinish: (() -> Void)?

    private var synthesizer: AVSpeechSynthesizer?

    override init() {
        super.init()
    }

    private func speechSynthesizerInstance() -> AVSpeechSynthesizer {
        if let synthesizer { return synthesizer }
        let instance = AVSpeechSynthesizer()
        instance.delegate = self
        synthesizer = instance
        return instance
    }

    var isSpeaking: Bool { synthesizer?.isSpeaking ?? false }

    func speak(_ text: String, localeIdentifier: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onFinish?()
            return
        }

        let trimmed = text
        Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try? session.setActive(true, options: [])

            await MainActor.run {
                let synthesizer = self.speechSynthesizerInstance()
                if synthesizer.isSpeaking {
                    synthesizer.stopSpeaking(at: .immediate)
                }

                // IMPORTANT: the utterance text is exactly `trimmed` — the
                // single string passed in by the caller. Callers must pass the
                // target phrase ONLY (never the translation). See
                // ShadowingViewModel.playTargetPhrase().
                let utterance = AVSpeechUtterance(string: trimmed)
                let resolvedVoice = Self.resolveVoice(localeIdentifier: localeIdentifier)
                utterance.voice = resolvedVoice
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                utterance.pitchMultiplier = 1.0

                #if DEBUG
                print("[TTS] speak len=\(trimmed.count) requestedLocale=\(localeIdentifier) voice=\(resolvedVoice?.language ?? "system-default") (single utterance, no translation)")
                #endif

                synthesizer.speak(utterance)
            }
        }
    }

    /// Picks the best installed voice for the requested locale, degrading
    /// gracefully: exact locale → any voice sharing the language prefix
    /// (e.g. "pt" matches "pt-BR" when "pt-PT" is missing) → system default
    /// for the language → nil (system chooses). This keeps a non-English
    /// phrase spoken in its own language whenever a voice exists.
    private static func resolveVoice(localeIdentifier: String) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: localeIdentifier) {
            return exact
        }

        let languagePrefix = localeIdentifier.split(separator: "-").first.map(String.init) ?? localeIdentifier
        if let prefixed = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.lowercased().hasPrefix(languagePrefix.lowercased())
        }) {
            return prefixed
        }

        // Last resort: let the system default voice handle it rather than
        // forcing en-US onto, say, a Spanish phrase.
        return AVSpeechSynthesisVoice(language: languagePrefix)
    }

    func stop() {
        guard let synthesizer, synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.onStart?() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.onFinish?() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.onFinish?() }
    }
}
