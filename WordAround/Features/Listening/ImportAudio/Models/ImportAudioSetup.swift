import Foundation

struct ListeningAudioImportSetup: Equatable, Hashable {
    let language: GrammarLanguage
    let level: EssayDifficulty
    let fileName: String
    let durationText: String
    let fileSizeText: String
    let addQuestions: Bool
    let questionCount: Int
    let questionTypes: Set<ListeningQuestionType>
}
