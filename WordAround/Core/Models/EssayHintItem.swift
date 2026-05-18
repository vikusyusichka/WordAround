import Foundation

struct EssayHintItem: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let translation: String
    let example: String
}
