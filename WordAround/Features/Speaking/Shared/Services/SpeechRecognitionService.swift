import Foundation
import Speech
import AVFoundation

enum SpeechRecognitionError: LocalizedError {
    case microphonePermissionDenied
    case speechPermissionDenied
    case recognizerUnavailable
    case audioSessionFailed(String)
    case audioEngineFailed(String)
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required to practice speaking."
        case .speechPermissionDenied:
            return "Speech recognition access is required to convert your speech into text."
        case .recognizerUnavailable:
            return "Speech recognition is not available for this language right now."
        case .audioSessionFailed(let message):
            return "Could not start audio: \(message)"
        case .audioEngineFailed(let message):
            return "Could not start the microphone: \(message)"
        case .recognitionFailed(let message):
            return "Speech recognition failed: \(message)"
        }
    }
}

final class SpeechRecognitionService: @unchecked Sendable {

    var onPartialTranscript: (@MainActor (String) -> Void)?

    var onFinalTranscript: (@MainActor (String) -> Void)?
    var onError: (@MainActor (SpeechRecognitionError) -> Void)?

    private let audioQueue = DispatchQueue(label: "SpeechRecognitionService.audio", qos: .userInitiated)
    private var audioEngine: AVAudioEngine?
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private let stateLock = NSLock()
    private var latestTranscript: String = ""
    private var isListeningProtected = false

    private(set) var isListening: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return isListeningProtected
        }
        set {
            stateLock.lock()
            isListeningProtected = newValue
            stateLock.unlock()
        }
    }

    init() {}

    func requestPermissions() async -> Bool {
        let mic = await requestMicrophonePermission()
        guard mic else {
            await emitError(.microphonePermissionDenied)
            return false
        }

        let speech = await requestSpeechPermission()
        guard speech else {
            await emitError(.speechPermissionDenied)
            return false
        }

        return true
    }

    private func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func start(localeIdentifier: String) async {
        guard !isListening else { return }

        stateLock.lock()
        latestTranscript = ""
        stateLock.unlock()

        let startError = await withCheckedContinuation { (continuation: CheckedContinuation<SpeechRecognitionError?, Never>) in
            audioQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: .recognizerUnavailable)
                    return
                }

                let locale = Locale(identifier: localeIdentifier)
                guard let speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer() else {
                    continuation.resume(returning: .recognizerUnavailable)
                    return
                }

                guard speechRecognizer.isAvailable else {
                    continuation.resume(returning: .recognizerUnavailable)
                    return
                }

                let session = AVAudioSession.sharedInstance()
                do {
                    try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
                    try session.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    continuation.resume(returning: .audioSessionFailed(error.localizedDescription))
                    return
                }

                let engine = AVAudioEngine()
                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true

                let inputNode = engine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)

                inputNode.removeTap(onBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    request.append(buffer)
                }

                engine.prepare()
                do {
                    try engine.start()
                } catch {
                    continuation.resume(returning: .audioEngineFailed(error.localizedDescription))
                    return
                }

                self.audioEngine = engine
                self.recognizer = speechRecognizer
                self.request = request

                self.task = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                    guard let self else { return }

                    if let result {
                        let text = result.bestTranscription.formattedString
                        Task { @MainActor in
                            self.stateLock.lock()
                            self.latestTranscript = text
                            self.stateLock.unlock()
                            self.onPartialTranscript?(text)
                        }
                    }

                    if let error {
                        Task { @MainActor in
                            let ns = error as NSError
                            let benignCodes: Set<Int> = [203, 1110, 216]
                            if !benignCodes.contains(ns.code) {
                                self.onError?(.recognitionFailed(ns.localizedDescription))
                            }
                        }
                    }
                }

                continuation.resume(returning: nil)
            }
        }

        if let startError {
            await emitError(startError)
            return
        }

        isListening = true
    }

    func stop() async {
        guard isListening else {
            await MainActor.run {
                onFinalTranscript?("")
            }
            return
        }

        let finalText: String = await withCheckedContinuation { continuation in
            audioQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: "")
                    return
                }
                cleanupAudioLocked()
                stateLock.lock()
                let text = latestTranscript
                latestTranscript = ""
                stateLock.unlock()
                isListeningProtected = false
                continuation.resume(returning: text)
            }
        }

        await MainActor.run {
            onFinalTranscript?(finalText)
        }
    }

    func cancel() {
        guard isListening else { return }
        audioQueue.async { [weak self] in
            guard let self else { return }
            cleanupAudioLocked()
            stateLock.lock()
            latestTranscript = ""
            stateLock.unlock()
            isListeningProtected = false
        }
    }

    private func cleanupAudioLocked() {
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
        }
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        request?.endAudio()
        request = nil

        task?.finish()
        task = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    @MainActor
    private func emitError(_ error: SpeechRecognitionError) {
        onError?(error)
    }
}
