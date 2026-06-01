import Foundation
import Speech

/// Transcribes an imported audio file using the Speech framework
/// (`SFSpeechURLRecognitionRequest`). The resulting transcript is used only to
/// generate questions and is kept hidden from the user by default.
final class SpeechFrameworkAudioTranscriptionService: ListeningAudioTranscribing, @unchecked Sendable {

    /// Maximum seconds to wait for SFSpeech to return a final result.
    /// On-device recognition is fast; cloud fallback can take longer but 60 s
    /// is a reasonable hard ceiling before we surface an error to the user.
    private static let timeoutSeconds: TimeInterval = 60

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func transcribe(fileURL: URL, localeIdentifier: String) async throws -> String {
        let authorized = await requestPermission()
        guard authorized else { throw ListeningTranscriptionError.permissionDenied }

        let locale = Locale(identifier: localeIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(),
              recognizer.isAvailable else {
            throw ListeningTranscriptionError.recognizerUnavailable
        }
        recognizer.defaultTaskHint = .dictation

        // Run the recognition with an overall timeout so we never hang forever.
        let transcript = try await withTimeout(seconds: Self.timeoutSeconds) {
            try await self.runRecognition(recognizer: recognizer, fileURL: fileURL)
        }

        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 40 else { throw ListeningTranscriptionError.emptyTranscript }
        return trimmed
    }

    private func runRecognition(recognizer: SFSpeechRecognizer, fileURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: fileURL)
            request.shouldReportPartialResults = false
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }

            var didResume = false

            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error, !didResume {
                    didResume = true
                    continuation.resume(throwing: ListeningTranscriptionError.failed(error.localizedDescription))
                    return
                }
                guard let result, result.isFinal, !didResume else { return }
                didResume = true
                continuation.resume(returning: result.bestTranscription.formattedString)
            }

            // Store task reference so the timeout handler can cancel it.
            _ = task // retained by the recognizer internally
        }
    }

    /// Runs `operation` and throws `ListeningTranscriptionError.failed` if it
    /// does not complete within `seconds`.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw ListeningTranscriptionError.failed(
                    "Transcription timed out. Try a shorter audio file."
                )
            }

            // First task to finish wins; cancel the other.
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

/// Preview/test transcriber that returns canned text without permissions.
struct MockAudioTranscriptionService: ListeningAudioTranscribing {
    var transcript: String = ListeningPlaceholderData.sampleText
    func requestPermission() async -> Bool { true }
    func transcribe(fileURL: URL, localeIdentifier: String) async throws -> String { transcript }
}
