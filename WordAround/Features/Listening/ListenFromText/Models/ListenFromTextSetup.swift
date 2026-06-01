import Foundation

struct ListeningSessionSetup: Equatable, Hashable {
    let modeID: String
    let language: GrammarLanguage
    let level: EssayDifficulty
    let title: String
    let text: String
    let voiceSpeed: ListeningVoiceSpeed
    let voiceType: ListeningVoiceType
    let showTextWhileListening: Bool
    let addQuestions: Bool
    let questionCount: Int
    let questionTypes: Set<ListeningQuestionType>
    let estimatedMinutes: Int

    var metadataLine: String {
        "\(language.title) • \(level.title) • \(voiceSpeed.rawValue) • ~\(estimatedMinutes) min"
    }
}
