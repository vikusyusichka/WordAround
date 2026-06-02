import Foundation
import Speech

final class SpeechFrameworkAudioTranscriptionService: ListeningAudioTranscribing, @unchecked Sendable {

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

            _ = task
        }
    }

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

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

struct MockAudioTranscriptionService: ListeningAudioTranscribing {
    var transcript: String = ListeningPlaceholderData.sampleText
    func requestPermission() async -> Bool { true }
    func transcribe(fileURL: URL, localeIdentifier: String) async throws -> String { transcript }
}
