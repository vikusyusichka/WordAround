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

    var qualityColor: QualityColor {
        switch total {
        case 85...100: return .excellent
        case 70..<85:  return .veryGood
        case 50..<70:  return .good
        default:       return .needsWork
        }
    }

    enum QualityColor {
        case excellent, veryGood, good, needsWork
    }
}
