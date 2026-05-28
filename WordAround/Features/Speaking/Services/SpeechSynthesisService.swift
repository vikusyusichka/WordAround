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

                let utterance = AVSpeechUtterance(string: trimmed)
                if let voice = AVSpeechSynthesisVoice(language: localeIdentifier) {
                    utterance.voice = voice
                } else {
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                }
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                utterance.pitchMultiplier = 1.0

                synthesizer.speak(utterance)
            }
        }
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
