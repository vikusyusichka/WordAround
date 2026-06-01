import Foundation

struct ListeningAudioImportSetup: Equatable, Hashable {
    let language: GrammarLanguage
    let level: EssayDifficulty
    /// User-facing original file name.
    let fileName: String
    /// Stored file name inside the audio cache directory (resolves to a URL).
    let storedFileName: String
    let durationText: String
    let durationSeconds: Double
    let fileSizeText: String
    let addQuestions: Bool
    let questionCount: Int
    let questionTypes: Set<ListeningQuestionType>

    /// On-disk URL of the imported audio.
    var audioURL: URL {
        ListeningAudioImporter.audioDirectory().appendingPathComponent(storedFileName)
    }

    var metadataLine: String {
        "\(language.title) • \(level.title) • \(durationText)"
    }
}
