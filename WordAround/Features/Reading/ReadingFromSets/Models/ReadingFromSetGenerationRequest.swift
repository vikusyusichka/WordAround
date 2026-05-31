import Foundation

struct ReadingFromSetGenerationRequest: Equatable {
    let setId: String
    let setTitle: String
    let words: [ReadingFromSetWord]
    let targetLanguage: GrammarLanguage
    let difficulty: EssayDifficulty
    let length: ReadingLength
    let generationMode: ReadingGenerationStyle
    let readingFocus: ReadingFocus

    var terms: [String] { words.map(\.term) }

    var effectiveTargetWordCount: Int {
        max(length.targetWordCount, words.count * 4)
    }
}

extension ReadingLength {
    var targetWordCount: Int {
        switch self {
        case .short:  return 120
        case .medium: return 220
        case .long:   return 340
        }
    }
}
