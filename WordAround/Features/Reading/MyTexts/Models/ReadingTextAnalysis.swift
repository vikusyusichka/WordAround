import Foundation

struct ReadingTextAnalysis: Equatable {
    let title: String
    let normalizedContent: String
    let wordCount: Int
    let estimatedReadingMinutes: Int
    let preview: String
    let estimatedLevel: EssayDifficulty
    let sentences: [String]
}
