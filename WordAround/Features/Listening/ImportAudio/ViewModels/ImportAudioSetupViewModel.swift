import Combine
import Foundation

@MainActor
final class ImportAudioSetupViewModel: ObservableObject {
    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var selectedLevel: EssayDifficulty = .b1
    @Published var addQuestions = true
    @Published var questionCount = 5
    @Published var questionTypes: Set<ListeningQuestionType> = Set(ListeningQuestionType.allCases)

    @Published private(set) var importedAudio: ListeningImportedAudio?
    @Published private(set) var isImporting = false
    @Published var errorMessage: String?
    @Published var showFileImporter = false
    @Published var showProcessing = false

    private let importer = ListeningAudioImporter()

    var selectedFileName: String? { importedAudio?.originalName }
    var selectedDuration: String { importedAudio?.durationText ?? "" }
    var selectedFileSize: String { importedAudio?.fileSizeText ?? "" }

    var canContinue: Bool { importedAudio != nil && !isImporting }

    func clearSelectedFile() {
        if let stored = importedAudio?.fileName {
            ListeningAudioImporter.deleteAudio(fileName: stored)
        }
        importedAudio = nil
        errorMessage = nil
    }

    func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = "Couldn't open that file: \(error.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else { return }
            importAudio(from: url)
        }
    }

    func importAudio(from url: URL) {
        errorMessage = nil
        isImporting = true
        Task {
            do {
                let audio = try await importer.importAudio(from: url)
                self.importedAudio = audio
            } catch {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            self.isImporting = false
        }
    }

    func continueToProcessing() {
        guard importedAudio != nil else {
            errorMessage = "Choose an audio file first."
            return
        }
        showProcessing = true
    }

    func makeSetup() -> ListeningAudioImportSetup {
        let audio = importedAudio
        return ListeningAudioImportSetup(
            language: selectedLanguage,
            level: selectedLevel,
            fileName: audio?.originalName ?? "audio",
            storedFileName: audio?.fileName ?? "",
            durationText: audio?.durationText ?? "0:00",
            durationSeconds: audio?.durationSeconds ?? 0,
            fileSizeText: audio?.fileSizeText ?? "",
            addQuestions: addQuestions,
            questionCount: questionCount,
            questionTypes: questionTypes
        )
    }
}
