import Foundation

struct EssayScore: Equatable {
    let total: Int
    let grammar: Int
    let vocabulary: Int
    let length: Int
    let complexity: Int
    let relevance: Int
    let independence: Int
    let cefrLevel: String
    let qualityLabel: String

    static let empty = EssayScore(
        total: 0,
        grammar: 0,
        vocabulary: 0,
        length: 0,
        complexity: 0,
        relevance: 0,
        independence: 100,
        cefrLevel: "A1",
        qualityLabel: "Not checked"
    )
}
