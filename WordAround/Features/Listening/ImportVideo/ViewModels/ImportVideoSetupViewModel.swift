import Combine
import Foundation

@MainActor
final class ImportVideoSetupViewModel: ObservableObject {
    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var selectedLevel: EssayDifficulty = .b1
    @Published var addQuestions = true
    @Published var questionCount = 5
    @Published var questionTypes: Set<ListeningQuestionType> = Set(ListeningQuestionType.allCases)

    @Published private(set) var importedVideo: ListeningImportedVideo?
    @Published private(set) var isImporting = false
    @Published var errorMessage: String?
    @Published var showFileImporter = false
    @Published var showProcessing = false

    private let importer = ListeningVideoImporter()

    var selectedFileName: String? { importedVideo?.originalName }
    var selectedDuration: String { importedVideo?.durationText ?? "" }
    var selectedFileSize: String { importedVideo?.fileSizeText ?? "" }
    var canContinue: Bool { importedVideo != nil && !isImporting }

    func clearSelectedFile() {
        if let stored = importedVideo?.fileName {
            ListeningVideoImporter.deleteVideo(fileName: stored)
        }
        importedVideo = nil
        errorMessage = nil
    }

    func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = "Couldn't open that file: \(error.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else { return }
            importVideo(from: url)
        }
    }

    func importVideo(from url: URL) {
        errorMessage = nil
        isImporting = true
        Task {
            do {
                importedVideo = try await importer.importVideo(from: url)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isImporting = false
        }
    }

    func continueToProcessing() {
        guard importedVideo != nil else {
            errorMessage = "Choose a video file first."
            return
        }
        showProcessing = true
    }

    func makeSetup() -> ListeningVideoImportSetup {
        let video = importedVideo
        return ListeningVideoImportSetup(
            language: selectedLanguage,
            level: selectedLevel,
            fileName: video?.originalName ?? "video",
            storedFileName: video?.fileName ?? "",
            durationText: video?.durationText ?? "0:00",
            durationSeconds: video?.durationSeconds ?? 0,
            fileSizeText: video?.fileSizeText ?? "",
            addQuestions: addQuestions,
            questionCount: questionCount,
            questionTypes: questionTypes
        )
    }
}
