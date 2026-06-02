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

                // Callers must pass the target phrase only (never the translation).
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

        // Last resort: system default voice rather than forcing en-US on non-English phrases.
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
