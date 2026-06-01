import Foundation

struct ListeningVideoSetup: Equatable, Hashable {
    let language: GrammarLanguage
    let level: EssayDifficulty
    let topic: String
    let length: ListeningVideoLength
}
