import Foundation

struct ListeningVideoImportSetup: Equatable, Hashable {
    let language: GrammarLanguage
    let level: EssayDifficulty
    let fileName: String
    let storedFileName: String
    let durationText: String
    let durationSeconds: Double
    let fileSizeText: String
    let addQuestions: Bool
    let questionCount: Int
    let questionTypes: Set<ListeningQuestionType>

    var videoURL: URL {
        ListeningVideoImporter.videoDirectory().appendingPathComponent(storedFileName)
    }

    var metadataLine: String {
        "\(language.title) • \(level.title) • \(durationText)"
    }
}
