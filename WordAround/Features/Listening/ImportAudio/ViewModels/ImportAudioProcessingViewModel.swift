import Combine
import Foundation

@MainActor
final class ImportAudioProcessingViewModel: ObservableObject {

    enum Phase: Equatable {
        case importing
        case transcribing
        case generatingQuestions
        case ready
        case failed(String)
    }

    let setup: ListeningAudioImportSetup
    let sessionId = UUID().uuidString

    @Published private(set) var phase: Phase = .importing
    @Published var showSession = false

    private(set) var transcript: String = ""
    private(set) var questions: [ListeningQuestion] = []

    private let transcriber: ListeningAudioTranscribing
    private let generator: ListeningQuestionGenerating

    private let steps = ["Uploading audio", "Transcribing speech", "Creating questions"]

    init(
        setup: ListeningAudioImportSetup,
        transcriber: ListeningAudioTranscribing? = nil,
        generator: ListeningQuestionGenerating? = nil
    ) {
        self.setup = setup
        self.transcriber = transcriber ?? SpeechFrameworkAudioTranscriptionService()
        self.generator = generator ?? LocalListeningQuestionGenerator()
    }

    var stepTitles: [String] { steps }

    var currentStep: Int {
        switch phase {
        case .importing:           return 0
        case .transcribing:        return 1
        case .generatingQuestions: return 2
        case .ready, .failed:      return steps.count
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

    func runProcessing() {
        guard phase == .importing else { return }
        Task { await process() }
    }

    func retry() {
        phase = .importing
        runProcessing()
    }

    private func process() async {
        phase = .transcribing

        guard setup.addQuestions else {
            phase = .ready
            showSession = true
            return
        }

        do {
            let text = try await transcriber.transcribe(
                fileURL: setup.audioURL,
                localeIdentifier: setup.language.listeningLocaleIdentifier
            )
            transcript = text

            phase = .generatingQuestions
            let generated = await generator.generateQuestions(
                from: text,
                language: setup.language,
                level: setup.level,
                types: setup.questionTypes,
                count: setup.questionCount
            )
            guard !generated.isEmpty else {
                phase = .failed(ListeningTranscriptionError.emptyTranscript.errorDescription ?? "Couldn't create questions.")
                return
            }
            questions = generated
            phase = .ready
            showSession = true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            phase = .failed(message)
        }
    }
}
