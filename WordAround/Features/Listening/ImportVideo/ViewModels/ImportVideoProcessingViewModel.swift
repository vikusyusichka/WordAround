import Combine
import Foundation

@MainActor
final class ImportVideoProcessingViewModel: ObservableObject {

    enum Phase: Equatable {
        case idle
        case validating
        case uploading
        case transcribing
        case preparingSubtitles
        case ready
        case failed(String)
    }

    let setup: ListeningVideoImportSetup
    let sessionId = UUID().uuidString

    @Published private(set) var phase: Phase = .idle
    @Published var showSession = false

    private(set) var transcription: ListeningTranscriptionResponse?

    private let importer = ListeningVideoImporter()
    private let transcriber: ListeningTranscriptionServicing

    private let steps = ["Preparing video", "Transcribing speech", "Building subtitles"]

    init(
        setup: ListeningVideoImportSetup,
        transcriber: ListeningTranscriptionServicing? = nil
    ) {
        self.setup = setup
        self.transcriber = transcriber ?? CloudflareListeningTranscriptionService()
    }

    var stepTitles: [String] { steps }

    var currentStep: Int {
        switch phase {
        case .idle, .validating, .uploading: return 0
        case .transcribing:                  return 1
        case .preparingSubtitles:            return 2
        case .ready, .failed:                return steps.count
        }
    }

    var errorMessage: String? {
        if case .failed(let message) = phase { return message }
        return nil
    }

    var hasFailed: Bool {
        if case .failed = phase { return true }
        return false
    }

    func run() {
        guard phase == .idle else { return }
        Task { await process() }
    }

    func retry() {
        phase = .idle
        run()
    }

    private func process() async {
        phase = .validating
        let videoURL = setup.videoURL
        guard !setup.storedFileName.isEmpty,
              FileManager.default.fileExists(atPath: videoURL.path) else {
            phase = .failed("The video file is no longer available. Please import it again.")
            return
        }

        phase = .uploading
        let uploadURL = await importer.extractAudio(from: videoURL)

        phase = .transcribing
        do {
            let response = try await transcriber.transcribeVideo(
                fileURL: uploadURL,
                language: setup.language,
                level: setup.level
            )
            phase = .preparingSubtitles
            transcription = response
            phase = .ready
            showSession = true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Transcription failed."
            phase = .failed(message)
        }

        if uploadURL != videoURL {
            try? FileManager.default.removeItem(at: uploadURL)
        }
    }
}
