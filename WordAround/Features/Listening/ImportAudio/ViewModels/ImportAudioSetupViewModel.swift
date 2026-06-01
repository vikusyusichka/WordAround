import Combine
import Foundation

@MainActor
final class ImportAudioSetupViewModel: ObservableObject {
    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var selectedLevel: EssayDifficulty = .b1
    @Published var addQuestions = true
    @Published var questionCount = 5
    @Published var questionTypes: Set<ListeningQuestionType> = Set(ListeningQuestionType.allCases)
    @Published var selectedFileName: String?
    @Published var selectedDuration = "4:32"
    @Published var selectedFileSize = "8.4 MB"
    @Published var showFileImporter = false
    @Published var showProcessing = false

    var canContinue: Bool { selectedFileName != nil }

    func clearSelectedFile() {
        selectedFileName = nil
    }

    func handleImportedFile(_ url: URL) {
        selectedFileName = url.lastPathComponent
    }

    func makeSetup() -> ListeningAudioImportSetup {
        ListeningAudioImportSetup(
            language: selectedLanguage,
            level: selectedLevel,
            fileName: selectedFileName ?? "audio.mp3",
            durationText: selectedDuration,
            fileSizeText: selectedFileSize,
            addQuestions: addQuestions,
            questionCount: questionCount,
            questionTypes: questionTypes
        )
    }
}
