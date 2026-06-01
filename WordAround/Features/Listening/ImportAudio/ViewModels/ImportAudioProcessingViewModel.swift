import Combine
import Foundation

@MainActor
final class ImportAudioProcessingViewModel: ObservableObject {
    let setup: ListeningAudioImportSetup

    @Published private(set) var currentStep = 0
    @Published var showSession = false

    private let steps = [
        "Uploading audio",
        "Transcribing speech",
        "Creating questions"
    ]

    init(setup: ListeningAudioImportSetup) {
        self.setup = setup
    }

    var stepTitles: [String] { steps }

    func runProcessing() {
        Task {
            for step in 0..<steps.count {
                currentStep = step
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
            showSession = true
        }
    }
}
